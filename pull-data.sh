#!/usr/bin/env bash
set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

echo Running rsync...
rsync -r root@ledstrip:ledstrip/data/ data/