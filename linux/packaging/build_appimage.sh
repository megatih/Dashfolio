#!/usr/bin/env bash
# Packages a Flutter Linux bundle as an AppImage.
#   build_appimage.sh <bundle-dir> <x64|arm64> <version> <out-dir>
# Needs: ImageMagick (convert/magick), curl, and optionally zsyncmake (writes the .zsync file for in-place updates).
set -euo pipefail

BUNDLE=${1:?bundle dir}
ARCH_FLUTTER=${2:?x64 or arm64}
VERSION=${3:?version}
OUT=${4:?output dir}

APPIMAGETOOL_VERSION=1.9.1
RUNTIME_VERSION=20251108
APP_ID=app.dashfolio.dashfolio

case "$ARCH_FLUTTER" in
  x64) ARCH=x86_64 ;;
  arm64) ARCH=aarch64 ;;
  *) echo "unknown arch: $ARCH_FLUTTER" >&2; exit 1 ;;
esac

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
APPDIR="$WORK/Dashfolio.AppDir"
mkdir -p "$OUT" "$APPDIR/usr/lib" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/metainfo"
OUT="$(cd "$OUT" && pwd)"

cp -R "$BUNDLE" "$APPDIR/usr/lib/dashfolio"
install -m 755 "$HERE/AppRun" "$APPDIR/AppRun"
install -m 644 "$HERE/$APP_ID.desktop" "$APPDIR/$APP_ID.desktop"
install -m 644 "$HERE/$APP_ID.desktop" "$APPDIR/usr/share/applications/$APP_ID.desktop"
sed -e "s/@VERSION@/${VERSION%%-*}/" -e "s/@DATE@/$(date -u +%F)/" "$HERE/$APP_ID.metainfo.xml.in" \
  >"$APPDIR/usr/share/metainfo/$APP_ID.appdata.xml"

# Icons: hicolor theme sizes plus the root icon appimagetool and file managers use.
if command -v magick >/dev/null 2>&1; then IM=(magick); else IM=(convert); fi
for size in 16 24 32 48 64 128 256 512; do
  dir="$APPDIR/usr/share/icons/hicolor/${size}x${size}/apps"
  mkdir -p "$dir"
  "${IM[@]}" "$ROOT/assets/icon/app_icon.png" -resize "${size}x${size}" "$dir/$APP_ID.png"
done
cp "$APPDIR/usr/share/icons/hicolor/256x256/apps/$APP_ID.png" "$APPDIR/$APP_ID.png"
ln -s "$APP_ID.png" "$APPDIR/.DirIcon"

fetch() { curl -fsSL --retry 3 -o "$2" "$1"; chmod +x "$2"; }
fetch "https://github.com/AppImage/appimagetool/releases/download/$APPIMAGETOOL_VERSION/appimagetool-$(uname -m).AppImage" "$WORK/appimagetool"
fetch "https://github.com/AppImage/type2-runtime/releases/download/$RUNTIME_VERSION/runtime-$ARCH" "$WORK/runtime"

NAME="Dashfolio-$VERSION-linux-$ARCH_FLUTTER.AppImage"
UPDATE_INFO="gh-releases-zsync|megatih|Dashfolio|latest|Dashfolio-*-linux-$ARCH_FLUTTER.AppImage.zsync"
# Runners have no FUSE, so run appimagetool extracted. It runs on the build host's arch; the runtime is the target's.
(cd "$OUT" && APPIMAGE_EXTRACT_AND_RUN=1 ARCH="$ARCH" "$WORK/appimagetool" --runtime-file "$WORK/runtime" \
  --updateinformation "$UPDATE_INFO" "$APPDIR" "$NAME")
echo "$OUT/$NAME"
