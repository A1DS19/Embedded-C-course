#!/bin/bash

cd "$(dirname "$0")/.."

if ! command -v valgrind >/dev/null 2>&1; then
    echo "Valgrind not found. Install it for memory checking."
    exit 1
fi

echo "Running comprehensive memory check..."

cmake -B build -S . -DCMAKE_BUILD_TYPE=Debug
cmake --build build

valgrind \
    --tool=memcheck \
    --leak-check=full \
    --show-leak-kinds=all \
    --track-origins=yes \
    --verbose \
    --error-exitcode=1 \
    --log-file=valgrind-report.log \
    ./bin/main

echo "Memory check complete! Report saved to valgrind-report.log"
