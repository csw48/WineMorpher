#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-v0.2.1}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_NAME="WineMorpher-${VERSION}"
STAGE="${ROOT}/dist/${PACKAGE_NAME}"
ZIP_PATH="${ROOT}/dist/${PACKAGE_NAME}.zip"

cd "${ROOT}"
make -C native

rm -rf "${STAGE}" "${ZIP_PATH}"
mkdir -p "${STAGE}/Interface/AddOns" "${STAGE}/mods"

cp -R addon/WineMorpher "${STAGE}/Interface/AddOns/WineMorpher"
cp -R addon/WineMorpher_Data "${STAGE}/Interface/AddOns/WineMorpher_Data"
cp native/build/winemorpher.dll "${STAGE}/mods/winemorpher.dll"

cat > "${STAGE}/dlls.txt" <<'EOF'
mods/winemorpher.dll
mods/libSiliconPatch.dll
mods/winerosetta.dll
EOF

cat > "${STAGE}/README-INSTALL.txt" <<EOF
WineMorpher ${VERSION}

1. Close WoW completely.
2. Copy Interface/AddOns/WineMorpher into your WoW Interface/AddOns folder.
3. Copy Interface/AddOns/WineMorpher_Data into your WoW Interface/AddOns folder.
4. Copy mods/winemorpher.dll into your WoW mods folder.
5. Add these lines to your WoW dlls.txt:

mods/winemorpher.dll
mods/libSiliconPatch.dll
mods/winerosetta.dll

6. Start WoW and type /wmorph or /wmorph gui.

Note: this package includes the WineMorpher_Data database files used by the
item/set/mount/creature/title browsers.
EOF

(
    cd "${ROOT}/dist"
    zip -qr "${PACKAGE_NAME}.zip" "${PACKAGE_NAME}"
)

echo "${ZIP_PATH}"
