#!/bin/sh
set -e

# Feature option (with default fallback so the script also works standalone).
INSTALL_DIRECTORY="${INSTALLDIRECTORY:-/usr/local/bin}"

echo "Activating feature 'tectonic'"
echo "Installing into: ${INSTALL_DIRECTORY}"

# We download Tectonic's official *static musl* release tarballs directly. These
# are self-contained (no runtime shared-library dependencies like libgraphite2 /
# libharfbuzz / libicu), so they run on slim base images where the dynamically
# linked '-gnu' build — which the upstream drop-sh installer selects on glibc —
# would fail to load.

# Ensure the tools we need are available: curl to download, tar to extract.
ensure_prereqs() {
    missing=""
    command -v curl >/dev/null 2>&1 || missing="${missing} curl"
    command -v tar  >/dev/null 2>&1 || missing="${missing} tar"
    [ -z "${missing}" ] && return 0

    echo "Installing missing prerequisites:${missing}"
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y
        apt-get install -y --no-install-recommends curl ca-certificates tar
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache curl ca-certificates tar
    else
        echo "ERROR: missing${missing} and no supported package manager was found." >&2
        exit 1
    fi
}

ensure_prereqs

# Map the machine architecture to Tectonic's musl release target triple.
ARCH="$(uname -m)"
case "${ARCH}" in
    x86_64 | amd64)
        TARGET="x86_64-unknown-linux-musl" ;;
    aarch64 | arm64)
        TARGET="aarch64-unknown-linux-musl" ;;
    *)
        echo "ERROR: unsupported architecture '${ARCH}'." >&2
        exit 1 ;;
esac

# Resolve the latest tectonic release version. The /releases/latest endpoint
# points at the main 'tectonic@X.Y.Z' tag.
echo "Resolving latest tectonic release..."
TAG="$(curl --proto '=https' --tlsv1.2 -fsSL \
    https://api.github.com/repos/tectonic-typesetting/tectonic/releases/latest \
    | grep -o '"tag_name": *"tectonic@[^"]*"' | head -n1 \
    | sed -e 's/.*tectonic@//' -e 's/"//')"

if [ -z "${TAG}" ]; then
    echo "ERROR: could not determine the latest tectonic version." >&2
    exit 1
fi

# Work in a throwaway directory.
WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "${WORKDIR}"; }
trap cleanup EXIT
cd "${WORKDIR}"

TARBALL="tectonic-${TAG}-${TARGET}.tar.gz"
URL="https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%40${TAG}/${TARBALL}"

echo "Downloading ${TARBALL} (v${TAG}, ${TARGET})..."
curl --proto '=https' --tlsv1.2 -fsSL "${URL}" -o "${TARBALL}"
tar -xzf "${TARBALL}"

if [ ! -f "${WORKDIR}/tectonic" ]; then
    echo "ERROR: release tarball did not contain a 'tectonic' binary." >&2
    exit 1
fi

mkdir -p "${INSTALL_DIRECTORY}"
install -m 0755 "${WORKDIR}/tectonic" "${INSTALL_DIRECTORY}/tectonic"

echo "Tectonic installed at ${INSTALL_DIRECTORY}/tectonic"
"${INSTALL_DIRECTORY}/tectonic" --version || true

echo "Done!"
