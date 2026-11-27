#!/bin/bash
# make_dist.sh U_FILE OUT_DIR  -> OUT_DIR/UT Millenium/... and OUT_DIR/UT-Millenium-v1.0.zip
set -e
REPO="$(cd "$(dirname "$0")/.." && pwd)"
U="$1"; OUT="$2"
D="$OUT/UT Millenium"
rm -rf "$D" "$OUT/UT-Millenium-v1.0.zip"
mkdir -p "$D/UT Millenium Data/Mod"
cp "$REPO/Launcher/UT Millenium Launcher.cmd" "$D/"
cp "$REPO/Launcher/README.txt" "$D/UT Millenium Data/README.txt"
cp "$U" "$D/UT Millenium Data/Mod/UTMillenium.u"
cp "$REPO/UTMillenium/UTMillenium.int" "$D/UT Millenium Data/Mod/UTMillenium.int"
for f in "$REPO"/Launcher/ps/*.ps1; do
  b=$(basename "$f" .ps1)
  sed 's/\r$//; s/$/\r/' "$f" > "$D/UT Millenium Data/Mod/$b.txt"
done
(cd "$OUT" && zip -qr -X UT-Millenium-v1.0.zip "UT Millenium")
echo "built $OUT/UT-Millenium-v1.0.zip"
