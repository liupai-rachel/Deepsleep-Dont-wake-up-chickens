#!/usr/bin/env bash
set -euo pipefail

test -s downloaded/web/index.html
test -s downloaded/linux/game.x86_64
test -s downloaded/linux/game.pck
test -s downloaded/windows/game.exe
test -s downloaded/windows/game.pck
# Actions artifacts do not preserve executable permissions.
chmod +x downloaded/linux/game.x86_64
mkdir -p release
for platform in web linux windows; do
  (cd "downloaded/$platform" && zip -qr "../../release/$platform.zip" .)
  test -s "release/$platform.zip"
done
