#!/bin/bash

cd "$(dirname "$0")/.."

echo "Formatting C code..."

CLANG_FORMAT=""
if command -v clang-format >/dev/null 2>&1; then
    CLANG_FORMAT="clang-format"
elif command -v clang-format-15 >/dev/null 2>&1; then
    CLANG_FORMAT="clang-format-15"
elif command -v clang-format-14 >/dev/null 2>&1; then
    CLANG_FORMAT="clang-format-14"
else
    echo "clang-format not found. Install it to use code formatting."
    exit 1
fi

find src include tests -name "*.c" -o -name "*.h" 2>/dev/null | \
    xargs "$CLANG_FORMAT" -i 2>/dev/null

echo "C code formatting complete!"
