#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p build/qa
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"

"$FLUTTER_BIN" test --no-pub test/ui test/widget_test.dart --reporter expanded 2>&1 \
  | tee build/qa/ui-audit.log
