#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

PLATFORM="${1:-linux}"
PROFILES=(development release)
BACKENDS=(ada plutosvg)

TMP_RESULTS="$(mktemp)"
trap 'rm -f "${TMP_RESULTS}"' EXIT

for profile in "${PROFILES[@]}"; do
  for backend in "${BACKENDS[@]}"; do
    echo
    echo "=== profile=${profile} backend=${backend} ==="
    alr exec -- gprbuild \
      -P tests/tests.gpr \
      -XADI_PLATFORM="${PLATFORM}" \
      -XADI_BUILD_PROFILE="${profile}" \
      -XADI_SVG_BACKEND="${backend}" \
      -XTEST_KIND=svg_perf_test

    while IFS= read -r line; do
      printf '%s\n' "${line}"
      if [[ "${line}" == PERF* ]]; then
        printf '%s profile=%s\n' "${line}" "${profile}" >> "${TMP_RESULTS}"
      fi
    done < <(./tests/bin/svg_perf_test)
  done
done

echo
echo "=== Comparison (avg_ms, lower is better) ==="

python3 - <<'PY' "${TMP_RESULTS}"
import sys
from collections import defaultdict

path = sys.argv[1]
rows = []
with open(path, "r", encoding="utf-8") as f:
    for raw in f:
        raw = raw.strip()
        if not raw.startswith("PERF "):
            continue
        parts = raw.split()
        kv = {}
        for p in parts[1:]:
            if "=" in p:
                k, v = p.split("=", 1)
                kv[k] = v
        rows.append(kv)

data = defaultdict(dict)
for r in rows:
    key = (r.get("profile", ""), r.get("asset", ""), int(r.get("size", "0")))
    backend = r.get("backend", "")
    try:
        avg = float(r.get("avg_ms", "nan"))
        cold = float(r.get("cold_ms", "nan"))
    except ValueError:
        continue
    data[key][backend] = {"avg": avg, "cold": cold}

print("profile asset size ada_cold pluto_cold cold_ratio ada_avg pluto_avg avg_ratio")
for key in sorted(data.keys()):
    profile, asset, size = key
    ada = data[key].get("ada")
    pluto = data[key].get("plutosvg")
    if ada is None or pluto is None:
        print(f"{profile} {asset} {size} n/a n/a n/a n/a n/a n/a")
        continue

    cold_ratio = ada["cold"] / pluto["cold"] if pluto["cold"] > 0 else float("nan")
    avg_ratio = ada["avg"] / pluto["avg"] if pluto["avg"] > 0 else float("nan")

    print(
        f"{profile} {asset} {size} "
        f"{ada['cold']:.3f} {pluto['cold']:.3f} {cold_ratio:.2f} "
        f"{ada['avg']:.3f} {pluto['avg']:.3f} {avg_ratio:.2f}"
    )
PY
