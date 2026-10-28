# Demoscena

Small experimental demos and executable scene studies.

## Demos

- [Dem0](Dem0/) — 64K intro prototype.
- [Dem1](Dem1/) — 64K native macOS intro prototype with four scene captures.
- [Dem2](Dem2/) — 64K native macOS intro prototype with three scene captures.
- [Dem3](Dem3/) — AFTERIMAGE, a silent monochrome three-scene intro for Apple Silicon macOS.
- [Dem4](Dem4/) — a silent monochrome intro with three motion-focused scenes.
- [Dem5](Dem5/) — a silent color intro with three scenes.
- [Dem6](Dem6/) — a silent 96-second color intro for Apple Silicon macOS.
- [Dem7](Dem7/) — a silent 96-second color intro for Apple Silicon macOS.
- [Dem8](Dem8/) — a silent 96-second color intro for Apple Silicon macOS.
- [Dem9](Dem9/) — a silent 96-second color intro for Apple Silicon macOS.
- [Dem10](Dem10/) — a silent 96-second color intro for Apple Silicon macOS.
- [Dem11](Dem11/) — a 64K macOS intro with individually colliding particles and a gradual wave finale.
- [Dem12](Dem12/) — a 64K macOS intro where waves draw a solitary figure toward a luminous aperture.
- [Dem13](Dem13/) — a 64K macOS intro about a person and dog meeting in a responsive triangular world.

## Running a macOS demo without Developer ID signing or notarization

Dem1 through Dem13 are Apple Silicon (arm64) executables with ad-hoc signatures. They are not signed with an Apple Developer ID and are not notarized, so macOS Gatekeeper may prevent them from opening. Intel Macs are unsupported.

From Terminal, go to the demo folder, remove the quarantine attribute from that executable, and run it. Example for Dem5:

```sh
cd Dem5
xattr -d com.apple.quarantine ./Dem5
./Dem5
```

Use the corresponding folder and executable name for another demo. Removing quarantine this way only changes that file; it does not disable Gatekeeper globally. You can also Control-click `Launch.command` in Finder and choose **Open**. If macOS still blocks launch, check **System Settings → Privacy & Security** for **Open Anyway** after attempting to open it once. See each demo's README for controls and screenshots.
