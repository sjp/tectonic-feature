#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI.
source dev-container-features-test-lib

# Feature-specific tests
check "tectonic is on PATH" bash -c "command -v tectonic"
check "tectonic --version" bash -c "tectonic --version"

# Report results
reportResults
