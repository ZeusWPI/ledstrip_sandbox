#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
command -v podman &>/dev/null && podman=podman || podman=docker

[ -e build-cross ] && rm -r build-cross
mkdir build-cross
$podman build -o build-cross .
