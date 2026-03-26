#!/bin/bash
set -e

cd "$(dirname "$0")/.."

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    PLATFORM="Windows"
    CMAKE_GENERATOR="MinGW Makefiles"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macOS"
    CMAKE_GENERATOR="Unix Makefiles"
else
    PLATFORM="Linux"
    CMAKE_GENERATOR="Unix Makefiles"
fi

echo "Configuring C project for $PLATFORM..."

mkdir -p build

cmake -B build -S . -G "$CMAKE_GENERATOR" -DCMAKE_BUILD_TYPE=Debug

echo "Building project..."
cmake --build build --config Debug

echo "Build complete! Run with:"
if [[ "$PLATFORM" == "Windows" ]]; then
    echo "  .\\bin\\main.exe"
else
    echo "  ./bin/main"
fi
