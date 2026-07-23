//  From AdaWebPack (github.com/ovenpasta/adawebpack), examples/sdl3/.
//  Copyright (c) 2020, Vadim Godunko
//  SPDX-License-Identifier: BSD-3-Clause

var SDL3AdaSuiteDecoder =
  typeof TextDecoder !== "undefined" ? new TextDecoder("utf-8") : null;

function SDL3AdaSuiteString(address, size) {
  var bytes = HEAPU8.subarray(address, address + size);

  if (SDL3AdaSuiteDecoder !== null) {
    return SDL3AdaSuiteDecoder.decode(bytes);
  }

  var result = "";
  var index;

  for (index = 0; index < bytes.length; index += 1) {
    result += String.fromCharCode(bytes[index]);
  }

  return result;
}

mergeInto(LibraryManager.library, {
  __gnat_grow: function (pages) {
    try {
      var oldPages = wasmMemory.grow(pages);

      if (typeof updateMemoryViews === "function") {
        updateMemoryViews();
      }

      return oldPages;
    } catch (error) {
      return 4294967295;
    }
  },

  __gnat_put_exception: function (address, size, line) {
    var message = SDL3AdaSuiteString(address, size);

    if (message === "do silent abort") {
      throw new Error(message);
    }

    if (line !== 0) {
      console.error("Ada exception at %s:%d", message, line);
    } else {
      console.error("Ada exception: %s", message);
    }
  }
});
