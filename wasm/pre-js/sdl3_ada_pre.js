//  From AdaWebPack (github.com/ovenpasta/adawebpack), examples/sdl3/.
//  Copyright (c) 2020, Vadim Godunko
//  SPDX-License-Identifier: BSD-3-Clause

Module['noInitialRun'] = true;
Module['onRuntimeInitialized'] = function () {
  var sp = stackSave();
  try {
    Module['_main']();
  } catch (error) {
    if (error !== 'unwind') {
      throw error;
    }
  } finally {
    stackRestore(sp);
  }
};
