#!/usr/bin/env bash

VERSION=`nimble dump --json | jq -r .version`

nim c \
-d:VERSION="${1}" \
-d:release \
-d:linux \
--cpu=mipsel \
--out=$PWD/out/sillaslcansync  $PWD/src/sillaslcansync.nim
