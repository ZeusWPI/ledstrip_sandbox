#!/usr/bin/env bash
set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

[ -e build-cross ] && rm -r build-cross
mkdir build-cross
docker build -o build-cross .

ssh root@ledstrip rm -r ledstrip || true
echo Running rsync...
rsync -r data build-cross/ root@ledstrip:ledstrip/
echo Restarting ledstrip
ssh root@ledstrip systemctl restart ledstrip
