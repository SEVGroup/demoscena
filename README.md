# Demoscena

Small experimental demos and executable scene studies.

## Demos

- [Dem0](Dem0/) — 64K intro prototype.
- [Dem1](Dem1/) — 64K native macOS intro prototype with four scene captures.
- [Dem2](Dem2/) — 64K native macOS intro prototype with three scene captures.
- [Dem3](Dem3/) — AFTERIMAGE, a silent monochrome three-scene intro for Apple Silicon macOS.
- [Dem4](Dem4/) — a silent monochrome intro with three motion-focused scenes.

## Running a macOS demo without Developer ID signing or notarization

Dem1, Dem2, Dem3, and Dem4 are Apple Silicon (arm64) executables with ad-hoc signatures. They are not signed with an Apple Developer ID and are not notarized, so macOS Gatekeeper may prevent them from opening. Run them only if you trust this repository. Intel Macs are unsupported.

From Terminal, go to the demo folder, remove the quarantine attribute from that executable, and run it. Example for Dem4:

```sh
cd Dem4
xattr -d com.apple.quarantine ./Dem4
./Dem4
```

Use the corresponding folder and executable name for Dem1, Dem2, or Dem3. Removing quarantine this way only changes that file; it does not disable Gatekeeper globally. You can also Control-click `Launch.command` in Finder and choose **Open**. If macOS still blocks launch, check **System Settings → Privacy & Security** for **Open Anyway** after attempting to open it once. See each demo's README for controls and screenshots.
