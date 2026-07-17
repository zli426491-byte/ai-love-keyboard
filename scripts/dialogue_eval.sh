#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p build/qa
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"

echo "Dialogue mode: mock_static (no live AI API call)"
"$FLUTTER_BIN" test --no-pub test/dialogue --reporter expanded 2>&1 \
  | tee build/qa/dialogue-eval.log
