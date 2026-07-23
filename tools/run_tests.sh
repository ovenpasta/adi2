#!/usr/bin/env bash
#  Run every Ada test binary plus the Python generator tests, and exit
#  nonzero if any of them fail. The test list is parsed from
#  tests/tests.gpr so it cannot drift from the declared Test_Kind set.
#
#  Binaries must already be built (alr build does this via post-build
#  actions). Headless-safe: SDL's dummy video driver is used unless the
#  caller sets SDL_VIDEODRIVER.
set -u
cd "$(dirname "$0")/.."

export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-dummy}"

kinds=$(sed -n '/type Test_Kind is/,/);/p' tests/tests.gpr \
        | grep -oE '"[a-z_0-9]+"' | tr -d '"')

fail=0
for t in $kinds; do
  bin="tests/bin/$t"
  if [[ ! -x "$bin" ]]; then
    echo "MISSING $t (run alr build first)"
    fail=1
    continue
  fi
  if out=$("$bin" 2>&1); then
    echo "PASS $t"
  else
    echo "FAIL $t"
    echo "$out" | tail -20
    fail=1
  fi
done

for p in test_css_to_ada test_xml_to_ada test_adi_mcp test_binary_to_ada; do
  if python3 "tools/$p.py" >/dev/null 2>&1; then
    echo "PASS $p"
  else
    echo "FAIL $p"
    fail=1
  fi
done

if [[ $fail -ne 0 ]]; then
  echo "TESTS FAILED"
else
  echo "all tests passed"
fi
exit $fail
