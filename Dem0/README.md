# Dem0 — local 64K intro prototype


Run `./Dem0` in this directory, or double-click `Launch.command`.
F (or the same physical key, А in Russian layout): toggle fullscreen. Esc or Cmd+Q: quit. The intro exits automatically.
Default window: 1152×648; internal rendering capped at 1280 pixels wide for the M2 Air.
Built with deployment target macOS 13; only the actual M2/macOS 27 machine was tested. Intel is unsupported.

`source/build.sh` rebuilds with Xcode command line tools and Python 3. A separate offline Metal compiler is not needed: the executable compiles its embedded shader through the system Metal framework on launch. Build fails if the final signed executable exceeds 65,536 bytes.

`./Dem0 --capture 36 tunnel.png` renders one frame at 36 seconds without opening the demo window.


This is a private prototype, not an approved competition submission. See COMPO-CHECK.md. Do not publish it before choosing a competition whose rules require a previously unreleased entry.
