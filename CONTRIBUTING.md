# Contributing

Issues and pull requests are welcome.

## Issues

- Bug reports should describe the observed and expected behaviour and,
  where possible, include a minimal reproduction, the Adi2 version, the
  build profile, and the platform.
- Feature requests, design proposals, and reports of incomplete
  documentation are also welcome.

## Pull requests

- Before beginning a new feature, a change in behaviour, or a
  substantial refactoring, open an issue so that the proposed approach
  can be discussed.
- Follow the existing code style described in
  [`docs/coding_conventions.md`](docs/coding_conventions.md).
- Run `tools/run_tests.sh`, which builds and runs the Ada tests and the
  Python generator tests. Ada test binaries are written to `tests/bin/`.
  `alr build -- -j0` builds the library without running the test suite.
  New behaviour should include appropriate tests; see
  [`docs/adding_test.md`](docs/adding_test.md).
- Do not weaken or remove a test merely to make an implementation pass.
  Describe any disagreement with an existing test in the issue or pull
  request.
- Each commit should address a defined change and have a concise subject
  line and a body explaining the change and its purpose.

## Licensing of Contributions

Adi2 is distributed under the Apache License 2.0. Before a Contribution
other than one covered by the exceptions below can be accepted, the
contributor must accept the [Contributor License Agreement](CLA.md)
(the "Agreement") with Aldo Nicolas Bruno ("We" or "Us").

Section 2.1(a) of the Agreement provides that contributors retain
ownership of the Copyright in their Contributions and retain the rights
to use and license those Contributions that they would have had without
entering into the Agreement.

Section 2.3 permits Us to license a Contribution under other terms,
including commercial or proprietary terms. As a condition of that
permission, We must also license the Contribution under the license or
licenses used for Adi2 on its Submission Date. Adi2 is presently
licensed under the Apache License 2.0. A later change to the primary
open-source license would not alter this obligation for an earlier
Contribution. Under Section 6.3, an assignee of Our rights or
obligations must agree in writing to the same terms.

### Purpose of the Agreement

The Agreement permits Adi2 to be offered under negotiated commercial
terms, including terms concerning warranties, indemnification,
long-term support, and certification evidence. The purpose of this
licensing model is to fund continued development and maintenance while
Contributions remain available under the open-source licenses required
by Section 2.3.

The Agreement is the [Harmony][harmony] Individual Contributor License
Agreement 1.0 using outbound licensing Option Five. Its substantive
terms have not been modified except where the Harmony template requires
an adopter to select or supply terms. Canonical, The Aerospace
Corporation, and NSF Unidata use the same agreement or agreements based
on it.

### Accepting the Agreement

After reading [CLA.md](CLA.md), post the following statement on the pull
request, replacing the bracketed text:

> I, [full legal name], have read and agree to the Adi2 Individual
> Contributor License Agreement at [permanent link]. I intend this
> comment to be my electronic signature. I confirm that I am
> contributing in my individual capacity and have the authority to enter
> into the Agreement.

To obtain the permanent link, open `CLA.md` on GitHub and press `y`.
GitHub will replace the branch name in the address with the commit
identifier for the version of the Agreement that was accepted.

The statement and the pull-request record document the contributor's
stated legal name, the accepted version of the Agreement, the relevant
Contribution, and the contributor's intent to sign. A contributor must
accept a new version before making a subsequent non-exempt Contribution
if the Agreement is materially amended. Corrections limited to
typography, links, or formatting do not require renewed acceptance.

Execution on paper or by email is available on request. A contributor
whose employer owns or may have rights in a submitted work must comply
with Section 3(c) of the Agreement, including by obtaining the required
employer approval or arranging an entity agreement. Contact Us before
submission at [adi@aldustechnology.com](mailto:adi@aldustechnology.com)
to make those arrangements.

Acceptance of the Agreement is not required to file an issue,
participate in a discussion, or submit a minor, non-substantive
correction that affects fewer than ten lines. This exemption is limited
to corrections that do not add or modify program logic or other
original expression, such as correcting a typographical error,
repairing a dead link, or making a purely factual correction to a code
comment. Line count alone does not qualify a change for the exemption.
An exempt correction intentionally submitted for inclusion in Adi2 is
licensed as provided by Section 5 of the Apache License 2.0 unless the
contributor explicitly states otherwise.

### Third-Party Material in a Contribution

If a submitted work contains material for which the contributor does
not own the Copyright, the pull request must identify that material, its
source, its license, and any modifications. This requirement applies to
software and non-software material, including icons, images, fonts,
animation data, and algorithms derived from another source. Third-party
material may be submitted only where its terms permit the proposed
inclusion and distribution. These disclosures allow the third-party
material to be distinguished from the contributor's Contribution as
defined in the Agreement.

Non-software material used by the examples is recorded in
[`examples/assets/NOTICE.md`](examples/assets/NOTICE.md), with source,
license, and modification information. New entries must follow the
existing format. Because `tools/binary_to_ada.py` incorporates these
assets into executable binaries, any applicable attribution or notice
requirements must also be satisfied when those binaries are
distributed.

[harmony]: https://www.harmonyagreements.org/

## Commercial support

For commercial support or custom development, contact
**adi@aldustechnology.com**.
