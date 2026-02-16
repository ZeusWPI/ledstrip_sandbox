#!/bin/sh
set -eu
cd "$(dirname "$0")"
if ! command -v rsync >/dev/null; then
    echo "Error: rsync is required"
    exit 1
fi

if ! [ -e build-cross/ledstrip ]; then
    echo "Error: Run ./build.sh first"
    exit 1
fi

echo "Running ./pull-data.sh..."
./pull-data.sh

echo "Deleting server-side ledstrip/ folder..."
ssh root@ledstrip rm -r ledstrip || true

echo "Pushing build-cross/ to server-side ledstrip/..."
rsync -rvP build-cross/ root@ledstrip:ledstrip/

echo "Pushing data/ to server-side ledstrip/data/..."
rsync -rvP data/ root@ledstrip:ledstrip/data/

echo "Restarting ledstrip..."
ssh root@ledstrip systemctl restart ledstrip
