#!/usr/bin/env bash

VERSION=`nimble dump --json | jq -r .version`


nim c \
-d:VERSION:"${1}" \
-d:debug \
--out=$PWD/out/sillaslcansync-local $PWD/src/sillaslcansync.nim