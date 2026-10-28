# Demoscena

Small experimental demos and executable scene studies.

## Demos

- [Dem0](Dem0/) — 64K intro prototype.
- [Dem1](Dem1/) — 64K native macOS intro prototype with four scene captures.
- [Dem2](Dem2/) — 64K native macOS intro prototype with three scene captures.

## Running an unsigned macOS demo

Dem1 and Dem2 are unsigned, not notarized Apple Silicon (arm64) executables. macOS Gatekeeper may prevent them from opening. Run them only if you trust this repository and its contents. Intel Macs are unsupported.

From Terminal, open the demo folder and remove the quarantine attribute from the specific executable you intend to run:

```sh
cd Dem2  # or: cd Dem1
xattr -d com.apple.quarantine ./Dem2  # use ./Dem1 for Dem1
./Dem2  # use ./Dem1 for Dem1
```

This changes the selected file only; it does not disable Gatekeeper globally. You can also Control-click `Launch.command` in Finder and choose **Open**. If macOS still blocks launch, check **System Settings → Privacy & Security** for **Open Anyway** after attempting to open it once. See each demo's README for controls and screenshots.
