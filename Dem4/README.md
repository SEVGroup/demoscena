# Dem4 — three-scene intro

Silent monochrome 64K intro for Apple Silicon macOS. It has three scenes: a migrating flock of rings, fast-rotating paper-like solids, and a particle stream spiraling between moving sources. Runtime: 96 seconds. The 52,864-byte executable is ad-hoc signed, but has no Developer ID signature and is not notarized. Intel is unsupported.

## Run

From Terminal in this folder:

```sh
./Dem4
```

If Gatekeeper blocks the downloaded file, follow the repository's [macOS launch instructions](../README.md#running-a-macos-demo-without-developer-id-signing-or-notarization).

- **Right** or **Down**: next scene.
- **Left** or **Up**: previous scene.
- **F** (or the same physical key, **А** in Russian layout): toggle fullscreen.
- **Esc** or **⌘Q**: quit.

## Scene captures

### Scene 1
![Dem4 scene 1](screenshots/scene1.png)

### Scene 2
![Dem4 scene 2](screenshots/scene2.png)

### Scene 3
![Dem4 scene 3](screenshots/scene3.png)

## Build

`source/build.sh` rebuilds with Xcode command line tools and Python 3. It enforces the 65,536-byte executable limit. Metal shader compilation at launch requires a Mac with Metal support.

See [COMPO-CHECK.md](COMPO-CHECK.md) before considering a competition submission.
