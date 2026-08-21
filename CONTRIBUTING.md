# Contributing

Issues and pull requests are welcome.

## Issues

- Report bugs with what you observed, what you expected, a minimal
  reproduction if possible, and the relevant version / build profile /
  platform.
- Feature ideas, design discussion, and documentation gaps are all fair
  game.

## Pull requests

- **For anything beyond a small fix, open an issue first** so the
  approach can be discussed before you invest time in it.
- Match the existing code style — see
  [`docs/coding_conventions.md`](docs/coding_conventions.md).
- Keep the test suite green. `tools/run_tests.sh` builds and runs it —
  the Ada tests, whose binaries land in `tests/bin/`, and the Python
  generator tests. `alr build -- -j0` builds the library alone. Add
  tests for new behaviour — see
  [`docs/adding_test.md`](docs/adding_test.md).
- Never weaken or delete a test to make an implementation pass; raise
  the mismatch in the issue or PR instead.
- Keep commits focused, with a short subject line and a body explaining
  what changed and why.

## Licensing of contributions

Adi2 is licensed under **Apache-2.0**. Unless you explicitly state
otherwise, any contribution intentionally submitted for inclusion is
understood to be under the same license, as defined in Section 5 of the
Apache License 2.0. There is no CLA to sign.

## Commercial support

For commercial support or custom development, contact
**adi@aldustechnology.com**.
