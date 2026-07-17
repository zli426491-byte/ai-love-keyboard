"""Snapshot and update App Store version localizations without storing secrets."""

from __future__ import annotations

import argparse
import json
import os
import time
from datetime import datetime, timezone
from pathlib import Path

import jwt
import requests


BASE_URL = "https://api.appstoreconnect.apple.com/v1"


def required_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SystemExit(f"Missing required environment variable: {name}")
    return value


def api_session() -> requests.Session:
    key_id = required_env("ASC_KEY_ID")
    issuer_id = required_env("ASC_ISSUER_ID")
    private_key_path = Path(required_env("ASC_PRIVATE_KEY_PATH"))
    now = int(time.time())
    token = jwt.encode(
        {
            "iss": issuer_id,
            "iat": now,
            "exp": now + 600,
            "aud": "appstoreconnect-v1",
        },
        private_key_path.read_text(encoding="utf-8"),
        algorithm="ES256",
        headers={"kid": key_id, "typ": "JWT"},
    )
    session = requests.Session()
    session.headers.update(
        {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }
    )
    return session


def request_json(
    session: requests.Session,
    method: str,
    path: str,
    **kwargs: object,
) -> dict:
    response = session.request(method, f"{BASE_URL}{path}", timeout=30, **kwargs)
    if not response.ok:
        raise SystemExit(f"App Store Connect API failed: {method} {path} ({response.status_code})")
    return response.json() if response.content else {}


def find_version(session: requests.Session, app_id: str, version: str) -> dict:
    payload = request_json(
        session,
        "GET",
        f"/apps/{app_id}/appStoreVersions",
        params={"filter[platform]": "IOS", "limit": 50},
    )
    for item in payload.get("data", []):
        if item.get("attributes", {}).get("versionString") == version:
            return item
    raise SystemExit(f"iOS App Store version {version} was not found")


def fetch_localizations(session: requests.Session, version_id: str) -> dict[str, dict]:
    payload = request_json(
        session,
        "GET",
        f"/appStoreVersions/{version_id}/appStoreVersionLocalizations",
        params={"limit": 50},
    )
    return {
        item["attributes"]["locale"]: item
        for item in payload.get("data", [])
    }


def snapshot(localizations: dict[str, dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = {
        "capturedAt": datetime.now(timezone.utc).isoformat(),
        "localizations": {
            locale: {
                "id": item["id"],
                "description": item["attributes"].get("description"),
                "whatsNew": item["attributes"].get("whatsNew"),
            }
            for locale, item in sorted(localizations.items())
        },
    }
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--app-id", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--metadata", type=Path, required=True)
    parser.add_argument("--snapshot", type=Path, required=True)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    desired = json.loads(args.metadata.read_text(encoding="utf-8"))
    session = api_session()
    version = find_version(session, args.app_id, args.version)
    localizations = fetch_localizations(session, version["id"])
    snapshot(localizations, args.snapshot)

    missing = sorted(set(localizations) - set(desired))
    unknown = sorted(set(desired) - set(localizations))
    if missing or unknown:
        raise SystemExit(f"Locale mismatch. Missing={missing}; unknown={unknown}")

    changes = []
    for locale, item in sorted(localizations.items()):
        attributes = {
            "description": desired[locale]["description"].strip(),
            "whatsNew": desired[locale]["whatsNew"].strip(),
        }
        current = item["attributes"]
        if all(current.get(key) == value for key, value in attributes.items()):
            continue
        changes.append(locale)
        if args.apply:
            request_json(
                session,
                "PATCH",
                f"/appStoreVersionLocalizations/{item['id']}",
                json={
                    "data": {
                        "type": "appStoreVersionLocalizations",
                        "id": item["id"],
                        "attributes": attributes,
                    }
                },
            )

    mode = "updated" if args.apply else "would update"
    print(f"{mode} {len(changes)} localizations: {', '.join(changes) or 'none'}")

    if args.apply:
        verified = fetch_localizations(session, version["id"])
        for locale, expected in desired.items():
            actual = verified[locale]["attributes"]
            if actual.get("description") != expected["description"].strip():
                raise SystemExit(f"Description verification failed for {locale}")
            if actual.get("whatsNew") != expected["whatsNew"].strip():
                raise SystemExit(f"What's New verification failed for {locale}")
        print("read-back verification passed")


if __name__ == "__main__":
    main()
