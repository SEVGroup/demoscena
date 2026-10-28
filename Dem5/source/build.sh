#!/bin/sh
set -eu
cd "$(dirname "$0")"
python3 - <<'PY'
import json
from pathlib import Path
Path('shader.h').write_text('#define SHADER '+json.dumps(Path('visual.metal').read_text())+'\n')
PY
xcrun clang main.m -o ../Dem5 -Oz -mmacosx-version-min=13.0 -fobjc-arc -ffast-math -framework Cocoa -framework Metal -framework QuartzCore -Wl,-no_data_const -Wl,-dead_strip -Wl,-x
strip -x ../Dem5
codesign --force --sign - ../Dem5
size=$(stat -f%z ../Dem5)
echo "Dem5: $size / 65536 bytes"
test "$size" -le 65536
