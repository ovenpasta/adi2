# Example asset attribution

Assets used by the example programs. They are demonstration content, not
part of the library, and are not installed with it.

## Animated Noto Emoji

Used by `rlottie_example`. Copyright Google LLC, licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/legalcode).
Project page: <https://googlefonts.github.io/noto-emoji-animation/>.

Every file below was downloaded from
`https://fonts.gstatic.com/s/e/notoemoji/latest/<codepoint>/lottie.json`
and is stored **unmodified**, byte for byte as served. Only the file name
differs from the source path.

| File | Codepoint | SHA-256 |
|------|-----------|---------|
| `noto_party_popper.json` | U+1F389 | `eab1fd7070bffd2965c12a80d2d91cff76683af65019f142acf9a553ee877b5c` |
| `noto_grinning_face.json` | U+1F600 | `b93b4e7f34019b29df77a873ea6583f5974008c0add4cac69f8f3b37c07a2426` |
| `noto_red_heart.json` | U+2764 U+FE0F | `7925790edd7ec4a4da6ccb9491c61a2e03705182e7db263f12d8e46a8fcddb79` |
| `noto_rocket.json` | U+1F680 | `2b6daf24cee4de340073838a7d97d07c097f2d3919b676d0e4e5fed8a2f23453` |
| `noto_fire.json` | U+1F525 | `96199d8e8fea7d90196b95b9a9e56b13af43e3817efe037bd9aa1e5215579838` |
| `noto_thumbs_up.json` | U+1F44D | `a5803c4978c0760977aa08033ab0abcb5023945a47008261cd405815fc947698` |
| `noto_tears_of_joy.json` | U+1F602 | `ae479405485961c5c233d882bd2b8ddf54c24e7ddb48371e6346b04b6b57edca` |
| `noto_star.json` | U+2B50 | `074dfd63037b9bcd30ad54f0f22fcde6c1bbba2b6611344d4b853fdc9dc8135f` |

CC BY 4.0 requires attribution. Retain this notice when redistributing
these files, and keep the attribution if you adapt them. Record any
change here — the "unmodified" claim above is what a downstream user
relies on.

## Google Material Icons and Material Symbols

Copyright Google LLC, licensed under Apache-2.0. Source:
<https://github.com/google/material-design-icons>, which keeps the two
sets apart: `src/` is the classic Material Icons, `symbols/` is Material
Symbols. Only `waving_hand` below comes from the latter.

`icons.svg` carries six symbols whose path data is verbatim upstream.
The examples below embed further path data inline, so that they
demonstrate building an image from a path string rather than from a file;
each is likewise verbatim.

| Where | Icon | Upstream |
|-------|------|----------|
| `icons.svg` | `home` `star` `heart` `settings` `search` `bell` | `src/*/{home,star,favorite,settings,search,notifications}/materialicons/24px.svg` |
| `combo_box_example.adb` | home, star, settings, search | as above |
| `image_example.adb` | star, favorite, flash_on, shield, notifications | `src/*/…/materialicons/24px.svg` |
| `dialog_example.adb` | info, warning | `src/action/info`, `src/alert/warning` |
| `material_demo.adb` | dashboard, waving_hand | `src/action/dashboard`; `symbols/web/waving_hand/materialsymbolsoutlined/waving_hand_fill1_24px.svg` |

None of this path data has been altered. `waving_hand` comes from
Material Symbols, which draws in a 960-unit box over a negative Y range,
so it is embedded with its own `viewBox` rather than rescaled — rescaling
would be a modification and would have to be recorded here.

The chevrons in `Adi.Widget.Combo_Box` and the list markers in
`Adi.Widget.Html_View` are hand-drawn geometric primitives, not derived
from any icon set. The document outline in `label_example.adb` is
likewise hand-drawn.

## camera.svg

"digital-camera" by AJ Ashton, published through
[openclipart.org](https://openclipart.org/). The file's own embedded
Dublin Core metadata names the author and dedicates the work to the
public domain (`cc:license` → `http://web.resource.org/cc/PublicDomain`).

## cat.svg

Hand-authored for this repository.

## OpenSans-Regular.ttf

A symlink into `vendor/open-sans/`, under the SIL Open Font License 1.1.

## Not yet reviewed

These came from elsewhere but carry no usable metadata, and the commits
that added them record no source. Provenance is not established, and
nothing here should be read as a claim that they are original to this
repository or that their terms permit redistribution.

| File | What the file itself records |
|------|------------------------------|
| `tiger.svg` | Nothing. Resembles the widely-redistributed "Ghostscript tiger", but resemblance is not evidence and no licence is inferred from it. |
| `animhorse.gif` | A GIF comment naming the authoring tool only: "GifBuilder 0.5 by Yves Piguet". Eight frames. |
| `happycat.png` | No text chunks. |
| `bg.jpg` | No EXIF, no comment, no XMP. |
