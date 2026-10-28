# Dem3 build and competition notes

Silent monochrome intro, three linked scenes, 96-second duration. Apple Silicon arm64, macOS 13+ deployment target. No external assets or audio. One native executable.

The build script checks the executable against 65,536 bytes. This build needs a real Mac with Metal for shader compilation at launch. Verify compatibility, controls, projection and current party rules before any competition submission.

Controls: left/up goes to the previous scene; right/down jumps to the next scene. F / А toggles fullscreen. Esc or Cmd+Q exits.
