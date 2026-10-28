# Demoscena

Small experimental demos and executable scene studies.

## Demos

- [Dem0](Dem0/) — 64K intro prototype.
- [Dem1](Dem1/) — 64K native macOS intro prototype with four scene captures.

## Running the unsigned macOS app

The `Dem1/Dem1` executable is an **unsigned, not notarized** Apple Silicon (arm64) app. macOS Gatekeeper may prevent it from opening. Only run it if you trust this repository and its contents.

1. Download or clone this repository, then open the `Dem1` folder.
2. In Finder, Control-click `Dem1` and choose **Open**. In the warning dialog, choose **Open** again. If macOS still blocks it, go to **System Settings → Privacy & Security** and use **Open Anyway** for this app.
3. Or, in Terminal from the `Dem1` folder, remove the quarantine attribute from this one file and launch it:
   ```sh
   xattr -d com.apple.quarantine ./Dem1
   ./Dem1
   ```

The quarantine-removal command only changes this executable; it does not disable Gatekeeper globally. The included `Launch.command` starts the same app. The build currently targets arm64 Macs; Intel Macs are unsupported. See [Dem1/README.md](Dem1/README.md) for controls and scene screenshots.
