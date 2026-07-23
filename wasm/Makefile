#  WebAssembly build of adi2 examples.
#
#  Pipeline: gprbuild (GNAT-LLVM, wasm32, EH runtime) compiles + binds the
#  Ada closure of one example into obj/<example>/; plutosvg/plutovg C is
#  compiled once with emcc into obj/plutosvg/; emcc links everything with
#  the static SDL3 wasm libs into out/<example>.html/.js/.wasm.
#
#    make EXAMPLE=label_example
#    make serve            # http://localhost:8000/label_example.html
#
#  Prerequisites (see FINDINGS.md):
#    - GNAT-LLVM built with the wasm EH runtime: make wasm-emcc-eh
#    - SDL3 / SDL3_ttf / SDL3_image wasm prefixes (adawebpack sdl3 examples)
#    - emscripten
#
#  The desktop build (../adi.gpr, alr) is completely independent of this.

.DEFAULT_GOAL := all

EXAMPLE ?= label_example
#  callbacks: SDL main callbacks — the normal, portable mode. Runs in
#  every browser; application state must live at package level (main's
#  stack is gone after startup).
#  blocking: runs the desktop examples verbatim — native Adi.App loop
#  suspended via JSPI, so example locals and nested callbacks survive.
#  Needs a JSPI-capable browser. Default here only because the
#  showcase reuses desktop example code unchanged.
LOOP ?= blocking

LLVM_INTERFACE_DIR ?= /src/gnat-llvm/llvm-interface
LLVM_BIN_DIR ?= $(LLVM_INTERFACE_DIR)/bin
LLVM_SYS_BIN ?= /usr/lib/llvm21/bin
LLVM_LIBRARY_PATH ?= /usr/lib/llvm21/lib

ADA_RTS ?= $(LLVM_INTERFACE_DIR)/lib/gnat-llvm/wasm32/rts-wasm-emcc-eh
ADA_RUNTIME_LIB = $(ADA_RTS)/adalib/libgnat.a

SDL3_ROOT ?= $(LLVM_INTERFACE_DIR)/adawebpack_src/examples/sdl3
SDL3_PREFIX ?= $(SDL3_ROOT)/sdl3-prefix
#  SDL3_ttf must be built with -fwasm-exceptions: freetype uses
#  setjmp/longjmp, and JS-based SJLJ cannot be mixed with wasm EH.
#  Built locally into wasm/sdl3-ttf-prefix (see PORT_REPORT.md).
SDL3_TTF_PREFIX ?= sdl3-ttf-prefix
SDL3_IMAGE_PREFIX ?= $(SDL3_ROOT)/sdl3-image-prefix

EMCC ?= /usr/lib/emscripten/emcc
EM_CACHE ?= /tmp/emscripten-cache
GPRBUILD ?= gprbuild

#  A fallback UI font, embedded where Adi.Font's Linux fallback scan looks
#  (Scan of /usr/share/fonts works over MEMFS). NotoSans matches the
#  scanner's (file prefix, family name) table.
FONT_FILE ?= /usr/share/fonts/noto/NotoSans-Regular.ttf
FONT_MOUNT = /usr/share/fonts/NotoSans-Regular.ttf

#  Runtime files the examples expect, mounted at the same repo-relative
#  paths they use natively (Emscripten CWD is "/"): examples/assets
#  (images, SVG, html; also the "app://" scheme root), examples/css
#  (runtime-loaded stylesheets), plus OpenSans-Regular.ttf for
#  font_example. ~2.4 MB per example — fine for a showcase.
EMBED_FLAGS = \
  --embed-file $(FONT_FILE)@$(FONT_MOUNT) \
  --embed-file ../examples/assets@/examples/assets \
  --embed-file ../examples/css@/examples/css \
  --embed-file ../vendor/open-sans/static/OpenSans-Regular.ttf@/OpenSans-Regular.ttf

#  -fwasm-exceptions is REQUIRED with the -eh runtime (keeps the wasm EH
#  personality / unwind tables).
#
#  blocking (JSPI): emscripten's own run()/callMain must invoke main —
#  it goes through the JSPI promising wrapper so emscripten_sleep can
#  suspend/resume. No pre-js, no INVOKE_RUN=0 (calling the raw _main
#  export would suspend once and never resume). main never resolves;
#  the runtime stays alive naturally.
#
#  callbacks: -sINVOKE_RUN=0 + pre-js defer main until the runtime is
#  up and catch the 'unwind' from emscripten_exit_with_live_runtime.
EMCC_FLAGS ?= -O2 -fwasm-exceptions \
  -sALLOW_MEMORY_GROWTH=1 -sSTACK_SIZE=8388608

ADA_JS_LIBRARY = pre-js/ada_runtime_support.js
ifeq ($(LOOP),blocking)
EMCC_FLAGS += -sJSPI -sJSPI_EXPORTS=main
PRE_JS_FLAGS =
else
EMCC_FLAGS += -sINVOKE_RUN=0
PRE_JS_FLAGS = --pre-js pre-js/sdl3_ada_pre.js
endif

#  ---- plutosvg / plutovg (plain C, compiled once for all examples) ----
PLUTO_DIR = ../vendor/plutosvg
PLUTO_SRCS = $(PLUTO_DIR)/source/plutosvg.c $(wildcard $(PLUTO_DIR)/plutovg/source/*.c)
PLUTO_OBJS = $(patsubst %.c,obj/plutosvg/%.o,$(notdir $(PLUTO_SRCS)))
#  -fwasm-exceptions: plutovg's ft-raster uses setjmp/longjmp, which must
#  use wasm-SJLJ to coexist with the EH runtime's wasm exceptions.
PLUTO_CFLAGS = -O2 -std=c99 -fwasm-exceptions \
  -DPLUTOVG_BUILD -DPLUTOVG_BUILD_STATIC \
  -DPLUTOSVG_BUILD -DPLUTOSVG_BUILD_STATIC \
  -I$(PLUTO_DIR)/source -I$(PLUTO_DIR)/plutovg/source -I$(PLUTO_DIR)/plutovg/include

VPATH = $(PLUTO_DIR)/source:$(PLUTO_DIR)/plutovg/source

obj/plutosvg/%.o: %.c
	@mkdir -p obj/plutosvg
	EM_CACHE=$(EM_CACHE) $(EMCC) $(PLUTO_CFLAGS) -c $< -o $@

#  ---- Ada compile + bind ----
#  .PHONY so gprbuild's own dependency tracking decides what to rebuild.
.PHONY: ada-objs
ada-objs:
	PATH=$(LLVM_SYS_BIN):$(LLVM_BIN_DIR):$$PATH LD_LIBRARY_PATH=$(LLVM_LIBRARY_PATH) \
	$(GPRBUILD) --target=llvm --RTS=$(ADA_RTS) -c -b -p \
	  -P adi_wasm.gpr -XWASM_EXAMPLE=$(EXAMPLE) -XWASM_MAIN_LOOP=$(LOOP)

#  ---- Link ----
#  The shared obj dir holds every built example's main + binder objects;
#  link exactly this example's closure: all library objects (other
#  examples' generated style/UI packages are gc'd by wasm-ld) minus all
#  mains and binders, plus this example's own two.
EXAMPLE_MAINS := $(notdir $(basename $(wildcard ../examples/*.adb)))
MAINS_RE := b__.*|$(shell echo $(EXAMPLE_MAINS) | tr ' ' '|')

#  Custom shell: Bulma top bar with example switcher instead of the
#  default emscripten developer shell.
SHELL_FILE = site/shell.html

out/$(EXAMPLE).html: ada-objs $(PLUTO_OBJS) $(ADA_JS_LIBRARY) $(SHELL_FILE)
	@mkdir -p out
	objs="$$(ls obj/$(LOOP)/*.o | grep -v -E '/($(MAINS_RE))\.o$$')"; \
	EM_CACHE=$(EM_CACHE) $(EMCC) $(EMCC_FLAGS) \
	  --shell-file $(SHELL_FILE) \
	  $(PRE_JS_FLAGS) --js-library $(ADA_JS_LIBRARY) \
	  $$objs \
	  obj/$(LOOP)/$(EXAMPLE).o obj/$(LOOP)/b__$(EXAMPLE).o \
	  $(PLUTO_OBJS) \
	  $(ADA_RUNTIME_LIB) \
	  $(SDL3_TTF_PREFIX)/lib/libSDL3_ttf.a \
	  $(SDL3_IMAGE_PREFIX)/lib/libSDL3_image.a \
	  $(SDL3_PREFIX)/lib/libSDL3.a \
	  $(EMBED_FLAGS) \
	  -o $@

all: out/$(EXAMPLE).html

#  ---- Showcase: every example expected to work in the browser ----
#  Excluded: rlottie_example (tasks/C++), runtime_css_example (its whole
#  point is filesystem live-reload), text_editor_example (native file
#  dialogs). Sequential builds — NEVER run gprbuild concurrently.
#  demo_flex additionally excluded: it withs GNAT.Traceback.Symbolic and
#  the wasm RTS does not ship the g-traceb spec yet (upstream item, same
#  one-line-rename family as g-os_lib was).
SHOWCASE_EXAMPLES = \
  hello_example label_example button_example \
  slider_example value_input_example text_input_example combo_box_example \
  list_box_example stack_example grid_example \
  gradient_example image_example animated_image_example assets_example \
  font_example transition_example material_demo \
  dialog_example html_view_example

showcase: $(PLUTO_OBJS)
	@fail=""; \
	for e in $(SHOWCASE_EXAMPLES); do \
	  echo "=== $$e"; \
	  $(MAKE) --no-print-directory EXAMPLE=$$e LOOP=$(LOOP) || fail="$$fail $$e"; \
	done; \
	cp site/index.html out/index.html; \
	if [ -n "$$fail" ]; then echo "FAILED:$$fail"; exit 1; \
	else echo "Showcase complete: out/index.html"; fi

serve:
	cd out && python3 -m http.server 8000

#  ---- Deploy: content-hashed names (cache busting), hac_web pattern ----
#  Entry .html pages keep plain names (dropdown links and bookmarks stay
#  stable; fresh mtimes keep their heuristic-cache window short). Each
#  page's .js/.wasm are copied as name-<hash12>.ext with references
#  rewritten inside-out: the wasm name inside the js first, then the js
#  itself is hashed. A rebuild that changes a file changes its URL, so
#  browsers refetch exactly what changed.
DIST ?= dist
DEPLOY_URL ?= https://pizzahack.eu/adi2/demo
deploy:
	rm -rf $(DIST)
	mkdir -p $(DIST)
	@set -e; \
	for e in $(SHOWCASE_EXAMPLES); do \
	  wh=$$(sha256sum out/$$e.wasm | cut -c1-12); \
	  cp out/$$e.wasm $(DIST)/$$e-$$wh.wasm; \
	  sed "s/$$e\.wasm/$$e-$$wh.wasm/g" out/$$e.js > $(DIST)/.js.tmp; \
	  jh=$$(sha256sum $(DIST)/.js.tmp | cut -c1-12); \
	  mv $(DIST)/.js.tmp $(DIST)/$$e-$$jh.js; \
	  sed -e "s/$$e\.js/$$e-$$jh.js/g" \
	      -e "s|$(DEPLOY_URL)/\([ \">]\)|$(DEPLOY_URL)/$$e.html\1|g" \
	      out/$$e.html > $(DIST)/$$e.html; \
	done; \
	cp out/index.html $(DIST)/index.html; \
	cp site/og.png $(DIST)/og.png; \
	echo "Deployed to $(DIST)/ with hashed js/wasm names"

serve-dist:
	cd $(DIST) && python3 -m http.server 8000

clean:
	rm -rf obj out $(DIST)

.PHONY: all serve serve-dist deploy clean showcase
