#!/bin/sh
set -eu

GAME_DIR="${1:-/Users/danielvajda/Downloads/world of warcraft 3.3.5a hd}"
ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"

DLL_SRC="$ROOT_DIR/native/build/winemorpher.dll"
ADDON_SRC="$ROOT_DIR/addon/WineMorpher"
DATA_ADDON_SRC="$ROOT_DIR/addon/WineMorpher_Data"

if [ ! -f "$DLL_SRC" ]; then
  echo "Missing $DLL_SRC. Run: cd '$ROOT_DIR/native' && make"
  exit 1
fi

if [ ! -d "$GAME_DIR" ]; then
  echo "Game directory does not exist: $GAME_DIR"
  exit 1
fi

# Clean up legacy dinput8.dll from game root if it's there
if [ -f "$GAME_DIR/dinput8.dll" ]; then
  echo "Backing up and removing legacy game-root dinput8.dll..."
  cp "$GAME_DIR/dinput8.dll" "$GAME_DIR/dinput8.dll.before-winemorpher-$STAMP"
  rm -f "$GAME_DIR/dinput8.dll"
fi

mkdir -p "$GAME_DIR/mods"
if [ -f "$GAME_DIR/mods/dinput8.dll" ]; then
  echo "Backing up and removing legacy mods/dinput8.dll..."
  cp "$GAME_DIR/mods/dinput8.dll" "$GAME_DIR/mods/dinput8.dll.before-winemorpher-$STAMP"
  rm -f "$GAME_DIR/mods/dinput8.dll"
fi

if [ -f "$GAME_DIR/dlls.txt" ]; then
  cp "$GAME_DIR/dlls.txt" "$GAME_DIR/dlls.txt.before-winemorpher-$STAMP"
fi

mkdir -p "$GAME_DIR/interface/addons"
rm -rf "$GAME_DIR/interface/addons/WineMorpher"
cp -R "$ADDON_SRC" "$GAME_DIR/interface/addons/WineMorpher"
rm -rf "$GAME_DIR/interface/addons/WineMorpher_Data"
cp -R "$DATA_ADDON_SRC" "$GAME_DIR/interface/addons/WineMorpher_Data"

# Install our new winemorpher.dll
cp "$DLL_SRC" "$GAME_DIR/mods/winemorpher.dll"

# Setup the new dlls.txt loading mods/winemorpher.dll natively
cat > "$GAME_DIR/dlls.txt" <<'EOF'
mods/winemorpher.dll
mods/libSiliconPatch.dll
mods/winerosetta.dll
EOF

echo "Installed WineMorpher addon, WineMorpher_Data addon, and mods/winemorpher.dll into:"
echo "$GAME_DIR"
