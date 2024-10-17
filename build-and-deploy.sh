#!/usr/bin/env bash
set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

docker build -o . .

pushd lua-language-server-ws
docker build -f Dockerfile.lua-language-server --platform=linux/arm/v7 -o . .
pnpm i && pnpm build
popd

rsync -r ledstrip data public lua-language-server-ws --exclude=node_modules --progress root@ledstrip:ledstrip
ssh root@ledstrip systemctl restart ledstrip