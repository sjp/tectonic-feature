# Tectonic (tectonic)

Installs the [Tectonic](https://tectonic-typesetting.github.io/) LaTeX toolkit — a modern, self-contained TeX/LaTeX engine that downloads support files on demand.

## Example Usage

```jsonc
"features": {
    "ghcr.io/sjp/tectonic-feature/tectonic:1": {}
}
```

## Options

| Option             | Type   | Default            | Description                                                       |
| ------------------ | ------ | ------------------ | ----------------------------------------------------------------- |
| `installDirectory` | string | `/usr/local/bin`   | Directory to install the `tectonic` binary into. Must be on PATH. |

## How it works

The feature downloads Tectonic's official **static musl** release tarball for the current architecture directly from GitHub:

- `x86_64` → `tectonic-<version>-x86_64-unknown-linux-musl.tar.gz`
- `aarch64` / `arm64` → `tectonic-<version>-aarch64-unknown-linux-musl.tar.gz`

It resolves the latest release version via the GitHub API, extracts the `tectonic` binary, and installs it into the configured directory.

The musl builds are statically linked, so they have **no runtime shared-library dependencies** (e.g. `libgraphite2`, `libharfbuzz`, `libicu`) and run on slim base images. This is why the feature does not use the upstream `drop-sh` installer, which selects the dynamically linked `-gnu` build on glibc systems and fails to load on minimal images (and has no `aarch64-unknown-linux-gnu` build at all).

## OS Support

Works on Debian/Ubuntu (`apt-get`) and Alpine (`apk`) based images, on both `x86_64` and `aarch64`/`arm64`. `curl`, `ca-certificates`, and `tar` are installed automatically if missing.
