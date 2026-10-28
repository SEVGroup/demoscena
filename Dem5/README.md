# Dem5 — color intro

Silent 96-second, three-scene color intro for Apple Silicon macOS. An organic swarm condenses into a kinetic field of moving forms, then opens into a luminous tunnel. The 52,864-byte executable is ad-hoc signed, but has no Developer ID signature and is not notarized. Intel is unsupported.

## Run

From Terminal in this folder:

```sh
./Dem5
```

If Gatekeeper blocks the downloaded file, follow the repository's [macOS launch instructions](../README.md#running-a-macos-demo-without-developer-id-signing-or-notarization).

- **Right** or **Down**: next scene.
- **Left** or **Up**: previous scene.
- **F** (or the same physical key, **А** in Russian layout): toggle fullscreen.
- **Esc** or **⌘Q**: quit.

## Scene captures

### Scene 1
![Dem5 scene 1](screenshots/scene1.png)

### Scene 2
![Dem5 scene 2](screenshots/scene2.png)

### Scene 3
![Dem5 scene 3](screenshots/scene3.png)

## Build

`source/build.sh` rebuilds with Xcode command line tools and Python 3. It enforces the 65,536-byte executable limit. Metal shader compilation at launch requires a Mac with Metal support.

See [COMPO-CHECK.md](COMPO-CHECK.md) before considering a competition submission.
