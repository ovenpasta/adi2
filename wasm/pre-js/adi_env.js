//  Pin Adi.Font's fallback to the embedded Open Sans, so shipped text
//  metrics do not depend on the build machine's installed fonts.
//  Adi.Font reads this once, before its system scan.
Module['preRun'] = Module['preRun'] || [];
Module['preRun'].push(function () {
  ENV.ADI_FALLBACK_FONT = '/OpenSans-Regular.ttf';
});
