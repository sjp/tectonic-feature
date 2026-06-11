#!/bin/sh
set -e

# Feature option (with default fallback so the script also works standalone).
INSTALL_DIRECTORY="${INSTALLDIRECTORY:-/usr/local/bin}"

echo "Activating feature 'tectonic'"
echo "Installing into: ${INSTALL_DIRECTORY}"

# Ensure the tools we need are available. The drop-sh installer needs curl;
# the arm64 fallback also needs tar.
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

# Place the produced 'tectonic' binary onto PATH.
install_binary() {
    src="$1"
    if [ ! -f "${src}" ]; then
        echo "ERROR: expected tectonic binary at '${src}' was not produced." >&2
        exit 1
    fi
    mkdir -p "${INSTALL_DIRECTORY}"
    install -m 0755 "${src}" "${INSTALL_DIRECTORY}/tectonic"
}

ensure_prereqs

# Work in a throwaway directory; the drop-sh installer drops the binary into the
# current directory, and we extract release tarballs here too.
WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "${WORKDIR}"; }
trap cleanup EXIT
cd "${WORKDIR}"

ARCH="$(uname -m)"
OS="$(uname -s)"

# Tectonic does NOT publish an aarch64 glibc (linux-gnu) build, so the official
# drop-sh installer 404s on arm64 Linux. For that case, fetch the static musl
# build directly. Everywhere else, use the upstream installer unchanged.
if [ "${OS}" = "Linux" ] && { [ "${ARCH}" = "aarch64" ] || [ "${ARCH}" = "arm64" ]; }; then
    echo "Detected arm64 Linux; tectonic ships only a musl build for this target."
    echo "Resolving latest tectonic release..."

    TAG="$(curl --proto '=https' --tlsv1.2 -fsSL \
        https://api.github.com/repos/tectonic-typesetting/tectonic/releases/latest \
        | grep -o '"tag_name": *"tectonic@[^"]*"' | head -n1 \
        | sed -e 's/.*tectonic@//' -e 's/"//')"

    if [ -z "${TAG}" ]; then
        echo "ERROR: could not determine the latest tectonic version." >&2
        exit 1
    fi

    TARGET="aarch64-unknown-linux-musl"
    TARBALL="tectonic-${TAG}-${TARGET}.tar.gz"
    URL="https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%40${TAG}/${TARBALL}"

    echo "Downloading ${TARBALL} (v${TAG})..."
    curl --proto '=https' --tlsv1.2 -fsSL "${URL}" -o "${TARBALL}"
    tar -xzf "${TARBALL}"
    install_binary "${WORKDIR}/tectonic"
else
    echo "Downloading and running the Tectonic installer..."
    curl --proto '=https' --tlsv1.2 -fsSL https://drop-sh.fullyjustified.net | sh
    install_binary "${WORKDIR}/tectonic"
fi

echo "Tectonic installed at ${INSTALL_DIRECTORY}/tectonic"
"${INSTALL_DIRECTORY}/tectonic" --version || true

echo "Done!"
