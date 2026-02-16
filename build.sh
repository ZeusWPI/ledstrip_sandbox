#!/bin/sh
set -eu
cd "$(dirname "$0")"
if command -v podman >/dev/null; then
    p=podman
elif command -v docker >/dev/null; then
    p=docker
else
    echo "Error: podman/docker is required"
    exit 1
fi

[ -e build-cross ] && rm -r build-cross
mkdir build-cross
$p build --jobs=0 -o build-cross .
