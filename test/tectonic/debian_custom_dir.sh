#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI.
source dev-container-features-test-lib

# The custom installDirectory is not on PATH, so verify the binary landed at
# the exact location we asked for and is runnable.
check "tectonic installed at custom directory" bash -c "/opt/tectonic/bin/tectonic --version"

# Report results
reportResults
