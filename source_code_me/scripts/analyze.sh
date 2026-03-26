#!/bin/bash

cd "$(dirname "$0")/.."

echo "Running static analysis..."

if command -v cppcheck >/dev/null 2>&1; then
    echo "Running cppcheck..."
    cppcheck --enable=all --std=c23 --platform=unix64 \
             --suppress=missingIncludeSystem \
             --suppress=unusedFunction \
             --suppress=constVariablePointer \
             -I include/ src/ || true
else
    echo "cppcheck not found. Install it for static analysis."
fi

if command -v clang-tidy >/dev/null 2>&1; then
    echo "Running clang-tidy..."
    find src/ -name "*.c" | xargs clang-tidy -p build/ \
        --checks='-clang-analyzer-security.insecureAPI.DeprecatedOrUnsafeBufferHandling' || true
else
    echo "clang-tidy not found. Install it for enhanced analysis."
fi

if command -v scan-build >/dev/null 2>&1; then
    echo "Running Clang static analyzer..."
    scan-build -o analysis-results make clean build || true
    echo "Analysis results saved to analysis-results/"
else
    echo "scan-build not found. Install clang-tools for static analysis."
fi

echo "Static analysis complete!"
