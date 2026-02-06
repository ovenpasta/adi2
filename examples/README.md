# Adi Examples

This directory contains example programs demonstrating how to use the Adi GUI library.

## Building Examples

### Build all examples (via post-build action)
```bash
alr build
```

### Build a specific example
```bash
gprbuild -P examples.gpr -XEXAMPLE_KIND=ttf_example
```

## Running Examples

Examples are built to `examples/bin/`:
```bash
./bin/ttf_example
```

## Available Examples

### ttf_example
Demonstrates how to use the SDL_TTF binding for TrueType font rendering:
- Font loading
- Font properties (size, style, metrics)
- Text rendering (Solid, Shaded, Blended modes)
- Text size calculation

## Adding New Examples

1. Create your example file: `my_example.adb`
2. Update `examples.gpr`:
   - Add to the `Example_Kind` type: `type Example_Kind is ("ttf_example", "my_example");`
3. Update `alire.toml`:
   - Add a post-build action:
     ```toml
     [[actions]]
     type = "post-build"
     command = ["gprbuild", "-P", "examples/examples.gpr", "-XEXAMPLE_KIND=my_example"]
     ```
