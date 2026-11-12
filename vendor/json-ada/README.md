# json-ada

[onox/json-ada](https://github.com/onox/json-ada), Apache-2.0 (`LICENSE.txt`).
`src/` is upstream's `json/src` at `4a04b21` (6.0.0), with these changes:

- `json-tokenizers.adb`, `json-types.adb`: from
  [onox/json-ada#17](https://github.com/onox/json-ada/pull/17) at `3775a7e`
  (Alejandro R. Mosteo): `\u` escapes, and UTF-8 bytes in 16#80# .. 16#9F#.
- `json-types.adb`: an object key holding an escape is looked up by what it
  decodes to (`"="` on a key).

Once #17 is merged, re-vendor from upstream and keep only what it lacks.
