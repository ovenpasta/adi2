#!/usr/bin/env bash
#  Build and run every Ada test plus the Python generator tests, and
#  exit nonzero if any of them fail. The test list is parsed from
#  tests/tests.gpr so it cannot drift from the declared Test_Kind set.
#
#  This is the alr test action. Builds are sequential — never run more
#  than one gprbuild at a time in this repo. Headless-safe: SDL's dummy
#  video driver is used unless the caller sets SDL_VIDEODRIVER.
#
#  Each test gets TEST_TIMEOUT seconds and is reported as a failure if it
#  runs past that. Some tests answer a "does this loop for ever" question
#  by finishing at all, so a hang has to end the suite with a verdict
#  rather than wedge it. The whole suite normally runs in under a minute,
#  so the default leaves two orders of magnitude of headroom on a loaded
#  machine.
set -u
cd "$(dirname "$0")/.."

GPRBUILD="${GPRBUILD:-alr exec -- gprbuild}"
TEST_TIMEOUT="${TEST_TIMEOUT:-120}"
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-dummy}"

#  Run one command under the timeout and report. $1 is the label, the
#  rest is the command. Exit 124 is timeout's own "expired"; 137 is the
#  follow-up KILL for a process that ignored the TERM.
run_one () {
  local label="$1"; shift
  local out rc
  out=$(timeout --kill-after=10 "$TEST_TIMEOUT" "$@" 2>&1)
  rc=$?
  if [[ $rc -eq 0 ]]; then
    echo "PASS $label"
    return 0
  fi
  if [[ $rc -eq 124 || $rc -eq 137 ]]; then
    echo "TIMEOUT $label: still running after ${TEST_TIMEOUT}s"
  else
    echo "FAIL $label"
    echo "$out" | tail -20
  fi
  return 1
}

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
  run_one "$t" "tests/bin/$t" || fail=1
done

for p in test_css_to_ada test_xml_to_ada test_binary_to_ada test_po_to_ada test_adi_mcp; do
  run_one "$p" python3 "tools/$p.py" || fail=1
done

if [[ $fail -ne 0 ]]; then
  echo "TESTS FAILED"
else
  echo "all tests passed"
fi
exit $fail
