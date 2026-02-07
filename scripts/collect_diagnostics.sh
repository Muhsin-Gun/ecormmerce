#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${ROOT_DIR}/diagnostics"
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
OUTPUT_FILE="${OUTPUT_DIR}/flutter_diagnostics_${TIMESTAMP}.log"

mkdir -p "${OUTPUT_DIR}"

{
  echo "Flutter diagnostics run at ${TIMESTAMP}"
  echo "Working directory: ${ROOT_DIR}"
  echo ""
  echo "== flutter --version =="
  flutter --version
  echo ""
  echo "== flutter analyze =="
  flutter analyze
  echo ""
  echo "== flutter test (if available) =="
  flutter test || echo "flutter test failed or no tests found"
} | tee "${OUTPUT_FILE}"

echo ""
echo "Saved diagnostics to ${OUTPUT_FILE}"
