#!/usr/bin/env bash
#  Build and run every Ada test, the Python generator tests, and the
#  example widget-tree goldens, and exit nonzero if any of them fail. The
#  Ada test list is parsed from tests/tests.gpr so it cannot drift from
#  the declared Test_Kind set.
#
#  This is the alr test action. It calls gprbuild directly and expects to
#  already be inside the Alire environment, as every other script here
#  does; run it by hand as `alr exec -- tools/run_tests.sh`. Builds are
#  sequential — never run more than one gprbuild at a time in this repo.
#  Headless-safe: SDL's dummy video driver is used unless the caller sets
#  SDL_VIDEODRIVER.
#
#  Each test gets TEST_TIMEOUT seconds and is reported as a failure if it
#  runs past that. Some tests answer a "does this loop for ever" question
#  by finishing at all, so a hang has to end the suite with a verdict
#  rather than wedge it. The Ada and Python tests normally run in under a
#  minute together, so the default leaves two orders of magnitude of
#  headroom on a loaded machine.
set -u
cd "$(dirname "$0")/.."

GPRBUILD="${GPRBUILD:-gprbuild}"
TEST_TIMEOUT="${TEST_TIMEOUT:-120}"
TREE_TIMEOUT="${TREE_TIMEOUT:-900}"
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-dummy}"

#  Run one command under a time limit and report. $1 is the label, $2 the
#  limit in seconds, the rest is the command. Exit 124 is timeout's own
#  "expired"; 137 is the follow-up KILL for a process that ignored the
#  TERM.
run_one () {
  local label="$1" limit="$2"; shift 2
  local out rc
  out=$(timeout --kill-after=10 "$limit" "$@" 2>&1)
  rc=$?
  if [[ $rc -eq 0 ]]; then
    echo "PASS $label"
    return 0
  fi
  if [[ $rc -eq 124 || $rc -eq 137 ]]; then
    echo "TIMEOUT $label: still running after ${limit}s"
  else
    echo "FAIL $label"
    echo "$out" | tail -20
  fi
  return 1
}

#  Stylesheets a test compares against its own runtime parse.
tools/generate_test_styles.sh >/dev/null

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
  run_one "$t" "$TEST_TIMEOUT" "tests/bin/$t" || fail=1
done

for p in test_css_to_ada test_xml_to_ada test_binary_to_ada test_po_to_ada test_adi_mcp; do
  run_one "$p" "$TEST_TIMEOUT" python3 "tools/$p.py" || fail=1
done

#  Every example's widget tree against its golden. This one builds the
#  examples and then runs each of them, so it needs its own budget:
#  around a minute when nothing changed, several when the library did.
#  Set ADI_SKIP_TREE_GOLDENS=1 to leave it out.
if [[ "${ADI_SKIP_TREE_GOLDENS:-0}" != 1 ]]; then
  run_one "widget_trees" "$TREE_TIMEOUT" python3 tools/widget_trees.py || fail=1
fi

if [[ $fail -ne 0 ]]; then
  echo "TESTS FAILED"
else
  echo "all tests passed"
fi
exit $fail
