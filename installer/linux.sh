#!/usr/bin/env bash
set -euo pipefail

# ===== Config =====
NAME="smog"
REPO="orbitbits/smog"
DIST_BRANCH="binaries"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${DIST_BRANCH}"
INSTALL_DIR="/usr/local/bin"
ARCH="x86_64"
BINARY_SUFFIX="linux-${ARCH}"

# ===== UI =====
title()   { printf "\e[0;35m[ %s ]\e[0m\n" "$1"; }
info()    { printf "\e[0;36m-> %s\e[0m\n" "$1"; }
warn()    { printf "\e[0;33m! %s\e[0m\n" "$1"; }
error()   { printf "\e[0;31mx %s\e[0m\n" "$1"; }
success() { printf "\e[0;32m* %s\e[0m\n" "$1"; }

# ===== Checks =====
[[ "$(uname -s)" != "Linux" ]] && { error "Linux only"; exit 1; }
[[ "$(uname -m)" != "x86_64" ]] && { error "Only x86_64 supported"; exit 1; }

command -v curl >/dev/null || { error "curl is required"; exit 1; }

# ===== Root handling =====
SUDO=""
if [ "$EUID" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  elif command -v doas >/dev/null 2>&1; then
    SUDO="doas"
  fi
fi

require_root() {
  if [ -z "$SUDO" ] && [ "$EUID" -ne 0 ]; then
    error "Root privileges required (sudo/doas not found)"
    exit 1
  fi
}

# ===== List versions =====
if [[ "${1:-}" == "--versions" ]]; then
  title "Available versions"

  curl -fsSL "https://api.github.com/repos/${REPO}/contents/?ref=${DIST_BRANCH}" \
    | grep '"name": "v' \
    | cut -d '"' -f4 \
    | sort -V

  exit 0
fi

# ===== Uninstall =====
if [[ "${1:-}" == "--uninstall" ]]; then
  require_root

  title "Uninstalling $NAME"

  if [ -f "${INSTALL_DIR}/${NAME}" ]; then
    $SUDO rm -v "${INSTALL_DIR}/${NAME}"
    success "Removed from ${INSTALL_DIR}"
  else
    warn "Not installed"
  fi

  exit 0
fi

# ===== Resolve version =====
if [[ -n "${1:-}" ]]; then
  VERSION_TAG="$1"
else
  VERSION_TAG=$(curl -fsSL "${BASE_URL}/latest.txt" | tr -d '[:space:]')
fi

[[ -z "$VERSION_TAG" ]] && { error "Failed to resolve version"; exit 1; }

VERSION="${VERSION_TAG#v}"
BIN_NAME="${NAME}-${VERSION}-${BINARY_SUFFIX}"
DOWNLOAD_URL="${BASE_URL}/v${VERSION}/${BIN_NAME}"

# ===== Start =====
title "$NAME Installer"
info "Version: $VERSION_TAG"
info "Download: $DOWNLOAD_URL"

TMP_FILE=$(mktemp)

# ===== Download =====
if curl -fL --progress-bar "$DOWNLOAD_URL" -o "$TMP_FILE"; then
  success "Download complete"
else
  error "Download failed"
  rm -f "$TMP_FILE"
  exit 1
fi

# ===== Integrity (basic) =====
if command -v sha256sum >/dev/null 2>&1; then
  # info "SHA256:"
  # sha256sum "$TMP_FILE"
  HASH=$(sha256sum "$TMP_FILE" | awk '{print $1}')
  info "SHA256: $HASH"
fi

# ===== Install =====
require_root

title "Installing to ${INSTALL_DIR}"

$SUDO install -Dm755 "$TMP_FILE" "${INSTALL_DIR}/${NAME}"

rm -f "$TMP_FILE"

success "Installation complete!"
info "Run: ${NAME}"