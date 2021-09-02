#!/bin/bash

set -e

measure()
{
    local prefix="$1"
    local suffix="$2"
    local output="$prefix-$suffix.txt"

    if [ -f "$output" ]
    then
        return
    fi

    cmake --build "$prefix"-build-"$suffix" -- -k 0 || true
    rm "$prefix"-build-"$suffix"/main_*

    echo "$prefix" "$suffix"

    for i in {1..100}
    do
        /usr/bin/time -f "$((i * 10 + 2))\t%e" \
                      cmake --build "$prefix"-build-"$suffix" \
                      --target main_$((i * 10)) \
                      >/dev/null || true
    done \
        2>> "$output"
}

benchmark()
{
    local prefix="$1"

    measure "$prefix" no-lto
    measure "$prefix" lto
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

