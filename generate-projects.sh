#!/bin/bash

set -e

cmakelists="cmake/CMakeLists.txt"
cmake_command=(cmake ../cmake -G Ninja -DCMAKE_BUILD_TYPE=Release)

generate_project()
{
    local n="$1"
    local callee=$(((n / 10 / 2) * 10))

    cat > "include/foo_$n.hpp" <<EOF
#pragma once
int foo_$n(int);
EOF

    cat > "src/foo_$n.cpp" <<EOF
#include "foo_$callee.hpp"

int foo_$n(int x)
{
  return foo_$callee(x) * $n;
}
EOF

    cat > "src/main_$n.cpp" <<EOF
#include "foo_$n.hpp"

#include <cstdio>

int main()
{
  printf("%d\n", foo_$n(1));
  return 0;
}
EOF

    (
        echo "add_executable(main_$n"
        echo '  ${source_root}/main_'"$n"'.cpp'

        local i=0
        while [[ $i -le $n ]]
        do
            echo '  ${source_root}/foo_'"$i"'.cpp'
            i=$((i + 10))
        done

        echo ')'
        echo
    ) >> "$cmakelists"
}

generate_clang()
{
    mkdir -p clang-build-{no-,}lto

    export CXX=clang++

    cd clang-build-no-lto

    "${cmake_command[@]}"

    cd ../clang-build-lto

    local flags="-flto"

    LDFLAGS="$flags" CXXFLAGS="$flags" "${cmake_command[@]}"

    cd ..
}

generate_gcc()
{
    mkdir -p gcc-build-{no-,}lto

    export CXX=g++

    cd gcc-build-no-lto

    "${cmake_command[@]}"

    cd ../gcc-build-lto

    local flags="-flto -fno-fat-lto-objects"

    LDFLAGS="$flags" CXXFLAGS="$flags" "${cmake_command[@]}"

    cd ..
}

generate_icc()
{
    mkdir -p icc-build-{no-,}lto

    export CXX=icpc

    cd icc-build-no-lto

    "${cmake_command[@]}"

    cd ../icc-build-lto

    LDFLAGS=-flto CXXFLAGS=-flto "${cmake_command[@]}"

    cd ..
}

mkdir -p cmake include src

cat > "$cmakelists" <<'EOF'
cmake_minimum_required(VERSION 3.12)

project(benchmark LANGUAGES CXX)

set(source_root "${CMAKE_CURRENT_LIST_DIR}/../src")
include_directories("${CMAKE_CURRENT_LIST_DIR}/../include")

EOF

cat > "include/foo_0.hpp" <<EOF
#pragma once
int foo_0(int);
EOF

    cat > "src/foo_0.cpp" <<EOF
int foo_0(int x)
{
  return 1;
}
EOF

for i in {1..100}
do
    generate_project $((i * 10))
done

for arg in "$@"
do
    case "$arg" in
        --clang)
            generate_clang
            ;;
        --gcc)
            generate_gcc
            ;;
        --icc)
            generate_icc
            ;;
    esac
done

