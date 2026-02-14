# Proposed SDL_ttf Issue

## Title

Renderer text engine: underline/strikethrough fill ops render white instead of text RGB

## Message

Hi SDL_ttf team,

I think there is a color-selection bug in the renderer text engine path (`TTF_DrawRendererText`) affecting text decorations.

### Observed behavior

When drawing text with underline or strikethrough and a non-white text color, the decoration line can render white while glyphs render in the expected color.

### Expected behavior

Underline/strikethrough should render in the same RGBA as the text color.

### Repro (renderer text engine path)

1. Create text with `TTF_CreateRendererTextEngine` + `TTF_CreateText`.
2. Use a font style with underline or strikethrough.
3. Set non-white text color with `TTF_SetTextColor(text, r, g, b, a)`.
4. Draw with `TTF_DrawRendererText`.

Result: glyphs are correctly tinted, but decoration line RGB appears white.

### Suspected root cause

In `src/SDL_renderer_textengine.c` (`TTF_DrawRendererText`), the color branch currently does:

```c
if (sequence->image_type == TTF_IMAGE_ALPHA) {
    SDL_copyp(&color, &text->internal->color);
} else {
    color.r = 1.0f;
    color.g = 1.0f;
    color.b = 1.0f;
    color.a = text->internal->color.a;
}
```

Underline/strikethrough draw ops can be emitted as fill sequences (`sequence->texture == NULL`, `image_type` invalid), which fall into the `else` branch and get forced to white RGB.

### Suggested fix

Treat fill sequences as text-colored ops:

```c
if (sequence->image_type == TTF_IMAGE_ALPHA || sequence->texture == NULL) {
    SDL_copyp(&color, &text->internal->color);
} else {
    // keep existing color-glyph behavior
}
```

I prepared a small patch with this change here:

- `deps/issues/sdl_ttf_text_decoration_color.patch`

Thanks!
