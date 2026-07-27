#!/usr/bin/env bash
#  Build and run every Ada test plus the Python generator tests, and
#  exit nonzero if any of them fail. The test list is parsed from
#  tests/tests.gpr so it cannot drift from the declared Test_Kind set.
#
#  This is the alr test action. Builds are sequential — never run more
#  than one gprbuild at a time in this repo. Headless-safe: SDL's dummy
#  video driver is used unless the caller sets SDL_VIDEODRIVER.
set -u
cd "$(dirname "$0")/.."

GPRBUILD="${GPRBUILD:-alr exec -- gprbuild}"
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-dummy}"

kinds=$(sed -n '/type Test_Kind is/,/);/p' tests/tests.gpr \
        | grep -oE '"[a-z_0-9]+"' | tr -d '"')

fail=0
for t in $kinds; do
  if ! $GPRBUILD -j0 -P tests/tests.gpr -XTEST_KIND="$t" >/dev/null 2>&1; then
    echo "BUILD FAIL $t"
    $GPRBUILD -j0 -P tests/tests.gpr -XTEST_KIND="$t" 2>&1 | grep -iE "error" | head -10
    fail=1
    continue
  fi
  bin="tests/bin/$t"
  if out=$("$bin" 2>&1); then
    echo "PASS $t"
  else
    echo "FAIL $t"
    echo "$out" | tail -20
    fail=1
  fi
done

for p in test_css_to_ada test_xml_to_ada test_binary_to_ada test_po_to_ada test_adi_mcp; do
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
