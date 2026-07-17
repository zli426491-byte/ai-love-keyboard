#!/usr/bin/env python3
"""Fail a release when RevenueCat does not expose the LoveKey products.

This uses RevenueCat's read-only SDK offerings endpoint with a synthetic QA
subscriber. It never performs a purchase and never prints the public SDK key.
"""

from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request
from collections.abc import Iterable, Mapping


EXPECTED_PRODUCT_IDS = frozenset(
    {
        "com.ailovekeyboard.pro.weekly",
        "com.ailovekeyboard.pro.yearly",
        "com.ailovekeyboard.pro.lifetime",
    }
)
OFFERINGS_URL = (
    "https://api.revenuecat.com/v1/subscribers/"
    "lovekey-release-preflight/offerings"
)


class RevenueCatPreflightError(RuntimeError):
    """Raised when the configured offering cannot safely ship."""


def _as_records(value: object) -> list[Mapping[str, object]]:
    if isinstance(value, Mapping):
        records: list[Mapping[str, object]] = []
        for key, item in value.items():
            if not isinstance(item, Mapping):
                continue
            record = dict(item)
            record.setdefault("identifier", str(key))
            records.append(record)
        return records
    if isinstance(value, list):
        return [item for item in value if isinstance(item, Mapping)]
    return []


def _product_id(package: Mapping[str, object]) -> str | None:
    for key in (
        "platform_product_identifier",
        "product_identifier",
        "store_product_identifier",
    ):
        value = package.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()

    product = package.get("product")
    if isinstance(product, Mapping):
        for key in ("identifier", "id", "product_identifier"):
            value = product.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()
    return None


def current_offering_product_ids(payload: Mapping[str, object]) -> set[str]:
    current = payload.get("current_offering_id")
    if not isinstance(current, str) or not current.strip():
        current_value = payload.get("current")
        if isinstance(current_value, Mapping):
            current = current_value.get("identifier")
        elif isinstance(current_value, str):
            current = current_value

    if not isinstance(current, str) or not current.strip():
        raise RevenueCatPreflightError("RevenueCat 沒有設定 current offering")

    offerings = _as_records(payload.get("offerings"))
    offering = next(
        (
            item
            for item in offerings
            if item.get("identifier") == current
            or item.get("offering_id") == current
        ),
        None,
    )
    if offering is None:
        raise RevenueCatPreflightError(
            f"RevenueCat 找不到 current offering：{current}"
        )

    packages = _as_records(offering.get("packages"))
    return {
        product_id
        for package in packages
        if (product_id := _product_id(package)) is not None
    }


def validate_lovekey_offering(payload: Mapping[str, object]) -> set[str]:
    product_ids = current_offering_product_ids(payload)
    missing = EXPECTED_PRODUCT_IDS - product_ids
    if missing:
        configured = ", ".join(sorted(product_ids)) or "（無商品）"
        missing_text = ", ".join(sorted(missing))
        raise RevenueCatPreflightError(
            "RevenueCat current offering 不是完整的 LoveKey 商品設定。"
            f"缺少：{missing_text}；目前讀到：{configured}"
        )
    return product_ids


def fetch_offerings(public_key: str, attempts: int = 3) -> Mapping[str, object]:
    request = urllib.request.Request(
        OFFERINGS_URL,
        headers={
            "Authorization": f"Bearer {public_key}",
            "Accept": "application/json",
            "X-Platform": "iOS",
        },
    )
    last_error: Exception | None = None
    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(request, timeout=20) as response:
                payload = json.load(response)
            if not isinstance(payload, Mapping):
                raise RevenueCatPreflightError("RevenueCat 回傳格式不是 JSON 物件")
            return payload
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as error:
            last_error = error
            if attempt < attempts:
                time.sleep(attempt)

    raise RevenueCatPreflightError(
        f"無法讀取 RevenueCat offering（重試 {attempts} 次）：{last_error}"
    )


def main(argv: Iterable[str] | None = None) -> int:
    del argv  # Reserved for future CLI options without exposing keys in argv.
    public_key = os.environ.get("REVENUECAT_IOS_PUBLIC_KEY", "").strip()
    if not public_key:
        print("RevenueCat 預檢失敗：REVENUECAT_IOS_PUBLIC_KEY 未設定", file=sys.stderr)
        return 1

    try:
        product_ids = validate_lovekey_offering(fetch_offerings(public_key))
    except RevenueCatPreflightError as error:
        print(f"RevenueCat 預檢失敗：{error}", file=sys.stderr)
        return 1

    print(
        "RevenueCat 預檢通過：current offering 已包含 LoveKey 週／年／永久商品。"
    )
    print("已驗證商品：" + ", ".join(sorted(product_ids)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
