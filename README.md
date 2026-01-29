# p7mextract

A bash utility to extract content from digitally signed `.p7m` files on macOS.

## Features

- Extract content from DER and PEM format p7m files (auto-detection)
- Interactive mode with smart default output filenames
- Overwrite confirmation with default to yes
- Colored output with status icons
- Detailed error messages for debugging

## Installation

### 1. Install the script

```bash
# Copy to your local bin
cp p7mextract ~/.local/bin/
chmod +x ~/.local/bin/p7mextract

# Ensure ~/.local/bin is in your PATH (add to ~/.zshrc if needed)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 2. Verify installation

```bash
p7mextract --help
```

## Usage

```bash
# Basic usage - will prompt for output filename
p7mextract document.pdf.p7m

# Specify output file
p7mextract document.p7m -o extracted.pdf

# Fully interactive mode
p7mextract
```

### Output filename logic

| Input | Proposed Output |
|-------|-----------------|
| `file.pdf.p7m` | `file.pdf` |
| `file.xml.p7m` | `file.xml` |
| `file.p7m` | `file.pdf` |

---

## Testing

This project uses [Bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System) for automated testing.

### Install Bats and dependencies

```bash
# Install Bats core
brew install bats-core

# Install helper libraries for better assertions
brew tap bats-core/bats-core
brew install bats-assert bats-support bats-file
```

### Setup test fixtures

Before running tests, generate the test fixture files:

```bash
cd test/fixtures
./setup_fixtures.sh
```

This creates valid and invalid p7m files for testing.

### Run tests

```bash
# Run all tests
bats test/p7mextract.bats

# Run with verbose output (tap format)
bats --tap test/p7mextract.bats

# Run specific test by name
bats test/p7mextract.bats --filter "extracts valid DER"

# Run with timing info
bats --timing test/p7mextract.bats
```

### Test output example

```
 ✓ displays help with --help
 ✓ displays help with -h
 ✓ extracts valid DER format p7m file
 ✓ extracts valid PEM format p7m file
 ✓ auto-detects output name from file.pdf.p7m
 ✓ adds .pdf extension when no intermediate extension
 ✓ accepts custom output with -o flag
 ✓ handles absolute output path
 ✓ handles relative output path
 ✓ fails gracefully on non-existent input file
 ✓ fails gracefully on invalid p7m file
 ✓ prompts for overwrite confirmation
 ✓ respects overwrite decline
 ✓ handles filenames with spaces
 ✓ handles tilde expansion in output path

15 tests, 0 failures
```

### CI Integration (GitHub Actions)

Create `.github/workflows/test.yml`:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Bats
        run: |
          brew install bats-core bats-assert bats-support bats-file
      
      - name: Setup test fixtures
        run: |
          cd test/fixtures
          chmod +x setup_fixtures.sh
          ./setup_fixtures.sh
      
      - name: Run tests
        run: bats test/p7mextract.bats
```

---

## Project structure

```
p7mextract/
├── README.md
├── p7mextract              # Main script
└── test/
    ├── p7mextract.bats     # Test suite
    ├── test_helper.bash    # Helper functions
    └── fixtures/
        ├── setup_fixtures.sh   # Generates test files
        ├── test_cert.pem       # Generated test certificate
        ├── test_key.pem        # Generated test private key
        ├── sample.pdf          # Sample PDF content
        ├── sample.txt          # Sample text content
        ├── valid_der.pdf.p7m   # Valid DER format signed file
        ├── valid_pem.pdf.p7m   # Valid PEM format signed file
        ├── no_ext.p7m          # Signed file without intermediate extension
        └── invalid.p7m         # Corrupted/invalid p7m file
```

---

## License

MIT
