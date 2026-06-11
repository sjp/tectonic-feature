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

On x86_64 this feature runs Tectonic's official installer:

```sh
curl --proto '=https' --tlsv1.2 -fsSL https://drop-sh.fullyjustified.net | sh
```

The installer downloads a prebuilt `tectonic` binary, which is then placed into the configured install directory.

On **arm64 Linux**, Tectonic does not publish a glibc (`aarch64-unknown-linux-gnu`) build, so the drop-sh installer 404s. The feature detects this case and instead downloads the official static `aarch64-unknown-linux-musl` release tarball directly from GitHub.

## OS Support

Works on Debian/Ubuntu (`apt-get`) and Alpine (`apk`) based images, on both `x86_64` and `aarch64`/`arm64`. `curl`, `ca-certificates`, and `tar` are installed automatically if missing.
