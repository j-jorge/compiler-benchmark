#!/bin/bash

set -e

measure()
{
    local prefix="$1"
    local suffix="$2"

    echo "$prefix" "$suffix"

    true > "$prefix-$suffix.txt"

    for i in {1..100}
    do
        /usr/bin/time -f "$((i*10))\t%e" \
                      ninja -C "$prefix"-build-"$suffix" main_$((i * 10)) \
                      >/dev/null
    done \
        2>> "$prefix-$suffix.txt"
}

benchmark()
{
    local prefix="$1"

    ninja -C "$prefix"-build-lto
    rm "$prefix"-build-lto/main_*

    ninja -C "$prefix"-build-no-lto
    rm "$prefix"-build-no-lto/main_*

    measure "$prefix" lto
    measure "$prefix" no-lto
}

if [ -d clang-build-no-lto ]
then
    benchmark clang
fi

if [ -d gcc-build-no-lto ]
then
    benchmark gcc
fi

if [ -d icc-build-no-lto ]
then
    benchmark icc
fi

