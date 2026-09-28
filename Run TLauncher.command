#!/bin/zsh
# Unofficial macOS helper. Downloads TLauncher and Java from their owners.
emulate -LR zsh
set -euo pipefail
setopt NULL_GLOB

TLAUNCHER_URL='https://tlauncher.org/jar'
TLAUNCHER_ZIP_SHA256='f7703658742f97905290a1944c4bb66df498e46201641340c9354ff196746ded'
TLAUNCHER_JAR_SHA256='77a85ddcf6b24ef72524d8615761f52a7970ce1a8b9db7302d91ad78cb66fe87'
ZULU_VERSION='zulu8.96.0.205-ca-fx-jre8.0.504'
APP_DIR="${TLAUNCHER_HELPER_HOME:-$HOME/Library/Application Support/TLauncher-macOS-helper}"
JAR="$APP_DIR/TLauncher.jar"
PREPARE_ONLY=0
TEMP_DIR=''

fail() {
  print -u2 "Error: $1"
  exit 1
}

cleanup() {
  if [[ -n "$TEMP_DIR" && "$TEMP_DIR" == "$APP_DIR"/.tmp.* ]]; then
    /bin/rm -rf "$TEMP_DIR"
  fi
}
trap cleanup EXIT

sha256() {
  /usr/bin/shasum -a 256 "$1" | /usr/bin/awk '{print $1}'
}

download() {
  local url="$1" output="$2"
  /usr/bin/curl --fail --location --show-error --silent \
    --proto '=https' --proto-redir '=https' \
    --connect-timeout 15 --max-time 240 --retry 2 \
    --output "$output" "$url" || fail "Download failed: $url"
}

is_java8_fx() {
  local java="$1" home_dir="${1%/bin/java}" version
  [[ -x "$java" && -f "$home_dir/lib/ext/jfxrt.jar" ]] || return 1
  version="$("$java" -version 2>&1)" || return 1
  [[ "$version" == *'version "1.8.'* ]]
}

for arg in "$@"; do
  case "$arg" in
    --prepare-only) PREPARE_ONLY=1 ;;
    *)
      print 'Usage: zsh "Run TLauncher.command" [--prepare-only]'
      exit 2
      ;;
  esac
done
[[ "$(/usr/bin/uname -s)" == 'Darwin' ]] || fail 'This helper runs only on macOS.'

case "$(/usr/bin/uname -m)" in
  arm64)
    ZULU_ARCH='aarch64'
    ZULU_SHA256='97d384e8ed02b5042c51fd19c94e2b8c33070ab913a24d1f7ab8e376e816fc16'
    ;;
  x86_64)
    ZULU_ARCH='x64'
    ZULU_SHA256='549bdafdebb9c149060fe28fdf9bd9cc07f5f10086c40afd41c76006131c9129'
    ;;
  *) fail 'Only Apple Silicon and Intel Macs are supported.' ;;
esac

ZULU_NAME="$ZULU_VERSION-macosx_$ZULU_ARCH"
ZULU_URL="https://cdn.azul.com/zulu/bin/$ZULU_NAME.tar.gz"
JAVA="$APP_DIR/runtime/$ZULU_NAME/Contents/Home/bin/java"
/bin/mkdir -p "$APP_DIR/runtime"

if [[ ! -f "$JAR" || "$(sha256 "$JAR")" != "$TLAUNCHER_JAR_SHA256" ]]; then
  TEMP_DIR="$(/usr/bin/mktemp -d "$APP_DIR/.tmp.XXXXXX")"
  print 'Downloading the verified TLauncher archive from tlauncher.org...'
  download "$TLAUNCHER_URL" "$TEMP_DIR/TLauncher.zip"
  [[ "$(sha256 "$TEMP_DIR/TLauncher.zip")" == "$TLAUNCHER_ZIP_SHA256" ]] ||
    fail 'The official download changed. This helper must be updated before it can use the new version.'
  /usr/bin/unzip -tq "$TEMP_DIR/TLauncher.zip" >/dev/null || fail 'TLauncher archive is damaged.'
  /usr/bin/unzip -p "$TEMP_DIR/TLauncher.zip" TLauncher.jar > "$TEMP_DIR/TLauncher.jar" ||
    fail 'TLauncher.jar was not found in the official archive.'
  [[ "$(sha256 "$TEMP_DIR/TLauncher.jar")" == "$TLAUNCHER_JAR_SHA256" ]] ||
    fail 'TLauncher.jar did not match the verified release.'
  /bin/mv -f "$TEMP_DIR/TLauncher.jar" "$JAR"
  cleanup
  TEMP_DIR=''
fi

if ! is_java8_fx "$JAVA"; then
  TEMP_DIR="$(/usr/bin/mktemp -d "$APP_DIR/.tmp.XXXXXX")"
  print 'Downloading the verified Azul Zulu Java 8 + JavaFX runtime...'
  download "$ZULU_URL" "$TEMP_DIR/Java8.tar.gz"
  [[ "$(sha256 "$TEMP_DIR/Java8.tar.gz")" == "$ZULU_SHA256" ]] ||
    fail 'The Java download changed. This helper must be updated before it can use the new version.'
  /usr/bin/tar -xzf "$TEMP_DIR/Java8.tar.gz" -C "$TEMP_DIR" || fail 'Java archive is damaged.'
  [[ -x "$TEMP_DIR/$ZULU_NAME/Contents/Home/bin/java" ]] || fail 'Java executable is missing.'
  if [[ -e "$APP_DIR/runtime/$ZULU_NAME" ]]; then
    /bin/rm -rf "$APP_DIR/runtime/$ZULU_NAME"
  fi
  /bin/mv "$TEMP_DIR/$ZULU_NAME" "$APP_DIR/runtime/$ZULU_NAME"
  JAVA="$APP_DIR/runtime/$ZULU_NAME/Contents/Home/bin/java"
  cleanup
  TEMP_DIR=''
fi

is_java8_fx "$JAVA" || fail 'A working Java 8 + JavaFX runtime was not found.'
print "TLauncher ready: $JAR"
print "Java runtime: $JAVA"
if (( PREPARE_ONLY )); then
  print 'Preparation passed. Run this command again without --prepare-only to open TLauncher.'
  exit 0
fi

print 'Opening TLauncher...'
exec "$JAVA" -jar "$JAR"
