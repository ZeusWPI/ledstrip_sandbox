#!/bin/sh
set -eu
cd "$(dirname "$0")"

echo "Pulling server-side ledstrip/data/ folder..."
rsync -rvP root@ledstrip.kelder.local:ledstrip/data/ data/
