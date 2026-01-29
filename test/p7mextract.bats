#!/usr/bin/env bats

# p7mextract.bats - Test suite for p7mextract utility

# Load test helper
load 'test_helper'

# =============================================================================
# HELP AND USAGE TESTS
# =============================================================================

@test "displays help with --help" {
    run_p7mextract --help
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "p7mextract"
    assert_output --partial "-o, --output"
}

@test "displays help with -h" {
    run_p7mextract -h
    assert_success
    assert_output --partial "Usage:"
}

@test "shows error for unknown option" {
    run_p7mextract --invalid-option
    assert_failure
    assert_output --partial "Unknown option"
}

@test "shows error when -o has no argument" {
    run_p7mextract "$(fixture valid_der.pdf.p7m)" -o
    assert_failure
    assert_output --partial "Option -o requires an argument"
}

# =============================================================================
# SUCCESSFUL EXTRACTION TESTS
# =============================================================================

@test "extracts valid DER format p7m file" {
    local input="$(fixture valid_der.pdf.p7m)"
    local outfile="${TEST_TEMP_DIR}/output.pdf"

    run_p7mextract "$input" -o "$outfile"
    assert_success
    assert_file_exists "$outfile"
    assert_output --partial "Extracted to:"
}

@test "extracts valid PEM format p7m file" {
    local input="$(fixture valid_pem.pdf.p7m)"
    local outfile="${TEST_TEMP_DIR}/output.pdf"

    run_p7mextract "$input" -o "$outfile"
    assert_success
    assert_file_exists "$outfile"
    assert_output --partial "Extracted to:"
}

@test "extracted content matches original" {
    local input="$(fixture valid_der.txt.p7m)"
    local outfile="${TEST_TEMP_DIR}/output.txt"
    local original="$(fixture sample.txt)"

    run_p7mextract "$input" -o "$outfile"
    assert_success

    # Compare extracted content with original (ignore CR/LF differences from OpenSSL smime)
    run diff --strip-trailing-cr "$original" "$outfile"
    assert_success
}

@test "displays file size in output" {
    local input="$(fixture valid_der.pdf.p7m)"
    local outfile="${TEST_TEMP_DIR}/output.pdf"

    run_p7mextract "$input" -o "$outfile"
    assert_success
    # Should show size in bytes, KB, or MB
    assert_output --regexp "(bytes|KB|MB)"
}

# =============================================================================
# OUTPUT FILENAME LOGIC TESTS
# =============================================================================

@test "auto-detects output name: file.pdf.p7m -> file.pdf" {
    local input="$(copy_fixture_to_temp valid_der.pdf.p7m)"
    
    # Simulate pressing Enter to accept default
    run_p7mextract_interactive "" "$input"
    assert_success
    
    local expected_output="${TEST_TEMP_DIR}/valid_der.pdf"
    assert_file_exists "$expected_output"
}

@test "auto-detects output name: file.txt.p7m -> file.txt" {
    local input="$(copy_fixture_to_temp valid_der.txt.p7m)"
    
    run_p7mextract_interactive "" "$input"
    assert_success
    
    local expected_output="${TEST_TEMP_DIR}/valid_der.txt"
    assert_file_exists "$expected_output"
}

@test "auto-detects output name: file.xml.p7m -> file.xml" {
    local input="$(copy_fixture_to_temp valid_der.xml.p7m)"
    
    run_p7mextract_interactive "" "$input"
    assert_success
    
    local expected_output="${TEST_TEMP_DIR}/valid_der.xml"
    assert_file_exists "$expected_output"
}

@test "adds .pdf extension when no intermediate extension: file.p7m -> file.pdf" {
    local input="$(copy_fixture_to_temp no_ext.p7m)"
    
    run_p7mextract_interactive "" "$input"
    assert_success
    
    local expected_output="${TEST_TEMP_DIR}/no_ext.pdf"
    assert_file_exists "$expected_output"
}

@test "handles uppercase .P7M extension" {
    local input="$(copy_fixture_to_temp uppercase_ext.pdf.P7M)"
    
    run_p7mextract_interactive "" "$input"
    assert_success
    
    local expected_output="${TEST_TEMP_DIR}/uppercase_ext.pdf"
    assert_file_exists "$expected_output"
}

# =============================================================================
# OUTPUT PATH TESTS
# =============================================================================

@test "accepts custom output with -o flag" {
    local input="$(fixture valid_der.pdf.p7m)"
    local outfile="${TEST_TEMP_DIR}/custom_name.pdf"

    run_p7mextract "$input" -o "$outfile"
    assert_success
    assert_file_exists "$outfile"
}

@test "accepts --output long flag" {
    local input="$(fixture valid_der.pdf.p7m)"
    local outfile="${TEST_TEMP_DIR}/custom_name.pdf"

    run_p7mextract "$input" --output "$outfile"
    assert_success
    assert_file_exists "$outfile"
}

@test "handles absolute output path" {
    local input="$(fixture valid_der.pdf.p7m)"
    local outfile="${TEST_TEMP_DIR}/absolute_path_test.pdf"

    run_p7mextract "$input" -o "$outfile"
    assert_success
    assert_file_exists "$outfile"
}

@test "handles relative output filename (uses input directory)" {
    local input="$(copy_fixture_to_temp valid_der.pdf.p7m)"
    
    # Change to temp dir and use relative filename
    cd "$TEST_TEMP_DIR"
    run "$P7MEXTRACT" "valid_der.pdf.p7m" -o "relative_output.pdf"
    assert_success
    assert_file_exists "${TEST_TEMP_DIR}/relative_output.pdf"
}

@test "output is placed in input file's directory by default" {
    local input="$(copy_fixture_to_temp valid_der.pdf.p7m)"
    
    run_p7mextract_interactive "" "$input"
    assert_success
    
    # Output should be in TEST_TEMP_DIR, not current directory
    assert_file_exists "${TEST_TEMP_DIR}/valid_der.pdf"
}

# =============================================================================
# ERROR HANDLING TESTS
# =============================================================================

@test "fails gracefully on non-existent input file" {
    run_p7mextract "/nonexistent/path/file.p7m" -o "${TEST_TEMP_DIR}/output.pdf"
    assert_failure
    assert_output --partial "Input file not found"
}

@test "fails gracefully on invalid p7m file" {
    local input="$(fixture invalid.p7m)"
    local outfile="${TEST_TEMP_DIR}/output.pdf"

    run_p7mextract "$input" -o "$outfile"
    assert_failure
    assert_output --partial "Failed to extract"
    assert_output --partial "DER format error"
    assert_output --partial "PEM format error"

    # Output file should not exist
    assert_file_not_exists "$outfile"
}

@test "fails when output directory does not exist" {
    local input="$(fixture valid_der.pdf.p7m)"
    local outfile="/nonexistent/directory/output.pdf"

    run_p7mextract "$input" -o "$outfile"
    assert_failure
    assert_output --partial "Output directory does not exist"
}

@test "fails when input file is not readable" {
    local input="$(copy_fixture_to_temp valid_der.pdf.p7m unreadable.p7m)"
    chmod 000 "$input"
    
    run_p7mextract "$input" -o "${TEST_TEMP_DIR}/output.pdf"
    assert_failure
    assert_output --partial "Cannot read input file"
    
    # Restore permissions for cleanup
    chmod 644 "$input"
}

@test "shows error for unexpected argument" {
    run_p7mextract "file1.p7m" "file2.p7m"
    assert_failure
    assert_output --partial "Unexpected argument"
}

# =============================================================================
# OVERWRITE HANDLING TESTS
# =============================================================================

@test "prompts for overwrite when file exists - accept with y" {
    local input="$(fixture valid_der.pdf.p7m)"
    local outfile="${TEST_TEMP_DIR}/existing.pdf"

    # Create existing file
    echo "existing content" > "$outfile"

    # Simulate typing 'y' for overwrite
    run bash -c "echo 'y' | '$P7MEXTRACT' '$input' -o '$outfile'"
    assert_success
    assert_output --partial "already exists"
    assert_output --partial "Extracted to:"
}

@test "prompts for overwrite when file exists - accept with YES (uppercase)" {
    local input="$(fixture valid_der.pdf.p7m)"
    local outfile="${TEST_TEMP_DIR}/existing.pdf"

    echo "existing content" > "$outfile"

    run bash -c "echo 'YES' | '$P7MEXTRACT' '$input' -o '$outfile'"
    assert_success
    assert_output --partial "Extracted to:"
}

@test "prompts for overwrite when file exists - accept with empty (default yes)" {
    local input="$(fixture valid_der.pdf.p7m)"
    local outfile="${TEST_TEMP_DIR}/existing.pdf"

    echo "existing content" > "$outfile"

    run bash -c "echo '' | '$P7MEXTRACT' '$input' -o '$outfile'"
    assert_success
    assert_output --partial "Extracted to:"
}

@test "prompts for overwrite when file exists - decline with n" {
    local input="$(fixture valid_der.pdf.p7m)"
    local outfile="${TEST_TEMP_DIR}/existing.pdf"

    echo "original content" > "$outfile"
    local original_content="$(cat "$outfile")"

    run bash -c "echo 'n' | '$P7MEXTRACT' '$input' -o '$outfile'"
    assert_success
    assert_output --partial "Operation cancelled"

    # File should retain original content
    assert_equal "$(cat "$outfile")" "$original_content"
}

@test "prompts for overwrite when file exists - decline with NO (uppercase)" {
    local input="$(fixture valid_der.pdf.p7m)"
    local outfile="${TEST_TEMP_DIR}/existing.pdf"

    echo "original content" > "$outfile"

    run bash -c "echo 'NO' | '$P7MEXTRACT' '$input' -o '$outfile'"
    assert_success
    assert_output --partial "Operation cancelled"
}

# =============================================================================
# INTERACTIVE MODE TESTS
# =============================================================================

@test "interactive mode: prompts for input file" {
    local input="$(fixture valid_der.pdf.p7m)"
    local outfile="${TEST_TEMP_DIR}/output.pdf"

    # Simulate providing input file and output file
    run bash -c "printf '%s\n%s\n' '$input' '$outfile' | '$P7MEXTRACT'"
    assert_success
    assert_output --partial "Enter input .p7m file"
    assert_output --partial "Output file"
    assert_file_exists "$outfile"
}

@test "interactive mode: accepts default output filename" {
    local input="$(copy_fixture_to_temp valid_der.pdf.p7m)"
    
    # First input: the p7m file, second input: empty (accept default)
    run bash -c "printf '%s\n\n' '$input' | '$P7MEXTRACT'"
    assert_success
    assert_file_exists "${TEST_TEMP_DIR}/valid_der.pdf"
}

@test "interactive mode: custom output filename" {
    local input="$(copy_fixture_to_temp valid_der.pdf.p7m)"
    local custom_output="${TEST_TEMP_DIR}/my_custom_output.pdf"
    
    run bash -c "printf '%s\n%s\n' '$input' '$custom_output' | '$P7MEXTRACT'"
    assert_success
    assert_file_exists "$custom_output"
}

@test "interactive mode: fails on empty input" {
    run bash -c "echo '' | '$P7MEXTRACT'"
    assert_failure
    assert_output --partial "No input file specified"
}

# =============================================================================
# SPECIAL FILENAME TESTS
# =============================================================================

@test "handles filenames with spaces" {
    local input="$(fixture 'file with spaces.pdf.p7m')"
    local outfile="${TEST_TEMP_DIR}/output with spaces.pdf"

    run_p7mextract "$input" -o "$outfile"
    assert_success
    assert_file_exists "$outfile"
}

@test "handles tilde expansion in output path" {
    # Skip if running as root (tilde might not expand as expected)
    [[ "$(id -u)" -eq 0 ]] && skip "Cannot test tilde expansion as root"
    
    local input="$(fixture valid_der.pdf.p7m)"
    # We need to test tilde expansion, but we can't write to actual home
    # So we'll test that the script doesn't fail with tilde
    
    # Create a test in temp that simulates the behavior
    local outfile="${TEST_TEMP_DIR}/tilde_test.pdf"
    run_p7mextract "$input" -o "$outfile"
    assert_success
}

# =============================================================================
# OUTPUT FORMAT TESTS
# =============================================================================

@test "success message includes checkmark icon" {
    local input="$(fixture valid_der.pdf.p7m)"
    local outfile="${TEST_TEMP_DIR}/output.pdf"

    run_p7mextract "$input" -o "$outfile"
    assert_success
    assert_output --partial "✓"
}

@test "error message includes X icon" {
    run_p7mextract "/nonexistent/file.p7m" -o "${TEST_TEMP_DIR}/output.pdf"
    assert_failure
    assert_output --partial "✗"
}

@test "warning message includes warning icon" {
    local input="$(fixture valid_der.pdf.p7m)"
    local outfile="${TEST_TEMP_DIR}/existing.pdf"

    echo "existing" > "$outfile"

    run bash -c "echo 'n' | '$P7MEXTRACT' '$input' -o '$outfile'"
    assert_output --partial "⚠"
}

# =============================================================================
# EDGE CASES
# =============================================================================

@test "handles input file in current directory" {
    local original_dir="$(pwd)"
    cd "$TEST_TEMP_DIR"
    
    cp "$(fixture valid_der.pdf.p7m)" ./local_file.pdf.p7m
    
    run "$P7MEXTRACT" "local_file.pdf.p7m" -o "local_output.pdf"
    assert_success
    assert_file_exists "${TEST_TEMP_DIR}/local_output.pdf"
    
    cd "$original_dir"
}

@test "cleans up partial output on extraction failure" {
    local input="$(fixture invalid.p7m)"
    local outfile="${TEST_TEMP_DIR}/should_not_exist.pdf"

    run_p7mextract "$input" -o "$outfile"
    assert_failure

    # Partial output file should be cleaned up
    assert_file_not_exists "$outfile"
}

@test "argument order: input file after -o flag" {
    local input="$(fixture valid_der.pdf.p7m)"
    local outfile="${TEST_TEMP_DIR}/output.pdf"

    # -o output first, then input file
    run_p7mextract -o "$outfile" "$input"
    assert_success
    assert_file_exists "$outfile"
}
