#!/bin/bash

# test_helper.bash - Helper functions for p7mextract tests

# Get the directory where this helper is located
HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$HELPER_DIR")"
FIXTURES_DIR="${HELPER_DIR}/fixtures"

# Path to the script under test
P7MEXTRACT="${PROJECT_DIR}/p7mextract"

# Load bats helper libraries (installed via brew)
# Support both Apple Silicon (/opt/homebrew) and Intel (/usr/local) Macs
if [[ -d "/opt/homebrew/lib" ]]; then
    BATS_LIB_PATH="/opt/homebrew/lib"
else
    BATS_LIB_PATH="/usr/local/lib"
fi

load "${BATS_LIB_PATH}/bats-support/load"
load "${BATS_LIB_PATH}/bats-assert/load"
load "${BATS_LIB_PATH}/bats-file/load"

# Setup function - runs before each test
setup() {
    # Create a temporary directory for test outputs
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Ensure the script is executable
    chmod +x "$P7MEXTRACT"
}

# Teardown function - runs after each test
teardown() {
    # Clean up temporary directory
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Helper: Run p7mextract with given arguments
run_p7mextract() {
    run "$P7MEXTRACT" "$@"
}

# Helper: Run p7mextract with simulated input (for interactive mode)
run_p7mextract_interactive() {
    local input="$1"
    shift
    run bash -c "echo '$input' | '$P7MEXTRACT' $*"
}

# Helper: Run p7mextract with multiple inputs (for multi-prompt scenarios)
run_p7mextract_multi_input() {
    local inputs="$1"
    shift
    run bash -c "printf '%s\n' $inputs | '$P7MEXTRACT' $*"
}

# Helper: Assert output file exists and has content
assert_extracted_file() {
    local file="$1"
    assert_file_exists "$file"
    assert_file_not_empty "$file"
}

# Helper: Get fixture path
fixture() {
    echo "${FIXTURES_DIR}/$1"
}

# Helper: Copy fixture to temp dir
copy_fixture_to_temp() {
    local fixture_name="$1"
    local dest_name="${2:-$fixture_name}"
    cp "$(fixture "$fixture_name")" "${TEST_TEMP_DIR}/${dest_name}"
    echo "${TEST_TEMP_DIR}/${dest_name}"
}

# Helper: Strip ANSI color codes from output
strip_colors() {
    echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

# Helper: Check if output contains success message
assert_success_message() {
    local expected_file="$1"
    assert_output --partial "Extracted to:"
    assert_output --partial "$expected_file"
}

# Helper: Check if output contains error message
assert_error_message() {
    local expected_error="$1"
    assert_output --partial "$expected_error"
}
