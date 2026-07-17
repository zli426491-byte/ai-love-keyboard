from __future__ import annotations

import unittest

from tools.check_revenuecat_offering import (
    EXPECTED_PRODUCT_IDS,
    RevenueCatPreflightError,
    current_offering_product_ids,
    validate_lovekey_offering,
)


def _payload(*product_ids: str) -> dict[str, object]:
    return {
        "current_offering_id": "default",
        "offerings": [
            {
                "identifier": "default",
                "packages": [
                    {
                        "identifier": f"package-{index}",
                        "platform_product_identifier": product_id,
                    }
                    for index, product_id in enumerate(product_ids)
                ],
            }
        ],
    }


class RevenueCatOfferingTest(unittest.TestCase):
    def test_accepts_complete_lovekey_offering(self) -> None:
        product_ids = validate_lovekey_offering(_payload(*EXPECTED_PRODUCT_IDS))

        self.assertEqual(product_ids, set(EXPECTED_PRODUCT_IDS))

    def test_rejects_cleanup_app_offering(self) -> None:
        with self.assertRaisesRegex(
            RevenueCatPreflightError,
            "com.ailovekeyboard.pro.lifetime",
        ):
            validate_lovekey_offering(
                _payload(
                    "com.cleanupapp.cleaner.weekly",
                    "com.cleanupapp.cleaner.yearly",
                )
            )

    def test_rejects_missing_current_offering(self) -> None:
        with self.assertRaisesRegex(
            RevenueCatPreflightError,
            "沒有設定 current offering",
        ):
            current_offering_product_ids({"offerings": []})

    def test_supports_dictionary_response_shape(self) -> None:
        payload = {
            "current_offering_id": "default",
            "offerings": {
                "default": {
                    "packages": {
                        "$rc_weekly": {
                            "platform_product_identifier": (
                                "com.ailovekeyboard.pro.weekly"
                            )
                        }
                    }
                }
            },
        }

        self.assertEqual(
            current_offering_product_ids(payload),
            {"com.ailovekeyboard.pro.weekly"},
        )


if __name__ == "__main__":
    unittest.main()
