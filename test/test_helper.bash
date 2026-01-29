#!/bin/bash

# Copyright 2025 fredericks1982
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# test_helper.bash - Helper functions for p7mextract tests

# Get the directory where this helper is located
HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$HELPER_DIR")"
FIXTURES_DIR="${HELPER_DIR}/fixtures"

# Path to the script under test
P7MEXTRACT="${PROJECT_DIR}/p7mextract"

# Load bats helper libraries
# Support Apple Silicon (/opt/homebrew), Intel Macs (/usr/local), and Linux (npm global)
if [[ -d "/opt/homebrew/lib" ]]; then
    BATS_LIB_PATH="/opt/homebrew/lib"
elif [[ -d "/usr/local/lib/bats-support" ]]; then
    BATS_LIB_PATH="/usr/local/lib"
elif [[ -d "/usr/lib/bats-support" ]]; then
    BATS_LIB_PATH="/usr/lib"
else
    # npm global install location
    BATS_LIB_PATH="$(npm root -g 2>/dev/null)"
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
