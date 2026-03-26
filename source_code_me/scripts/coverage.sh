#!/bin/bash

cd "$(dirname "$0")/.."

if ! command -v gcov >/dev/null 2>&1; then
    echo "gcov not found. Install gcc for coverage analysis."
    exit 1
fi

echo "Generating code coverage report..."

rm -rf coverage/ *.gcno *.gcda *.gcov

cmake -B build -S . \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_C_FLAGS="--coverage -fprofile-arcs -ftest-coverage"
cmake --build build

if [ -f bin/test_main ]; then
    echo "Running tests to generate coverage data..."
    ./bin/test_main
else
    echo "Running main executable for coverage..."
    ./bin/main
fi

mkdir -p coverage
gcov -r src/*.c
mv *.gcov coverage/

if command -v lcov >/dev/null 2>&1 && command -v genhtml >/dev/null 2>&1; then
    echo "Generating HTML coverage report..."
    lcov --capture --directory . --output-file coverage/coverage.info
    genhtml coverage/coverage.info --output-directory coverage/html
    echo "HTML coverage report generated in coverage/html/"
fi

echo "Coverage analysis complete! Results in coverage/"
