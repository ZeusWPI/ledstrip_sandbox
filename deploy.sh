#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

if [ ! -e build-cross/ledstrip ]; then
    echo "Run ./build.sh first"
    exit 1
fi

ssh root@ledstrip rm -r ledstrip || true
echo Running rsync...
rsync -r data build-cross/ root@ledstrip:ledstrip/
echo Restarting ledstrip
ssh root@ledstrip systemctl restart ledstrip
