# p7mextract

A bash utility to extract content from digitally signed `.p7m` files (PKCS#7 format). Auto-detects DER and PEM encoding.

## Features

- Extract content from DER and PEM format p7m files (auto-detection)
- Interactive mode with smart default output filenames
- Overwrite confirmation with default to yes
- Colored output with status icons
- Detailed error messages for debugging

## Installation

```bash
# Copy to your local bin
cp p7mextract ~/.local/bin/
chmod +x ~/.local/bin/p7mextract

# Ensure ~/.local/bin is in your PATH (add to ~/.zshrc or ~/.bashrc if needed)
export PATH="$HOME/.local/bin:$PATH"
```

Verify installation:

```bash
p7mextract --help
```

### Requirements

- Bash
- OpenSSL (with smime support)

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

## Development

### Running tests

This project uses [Bats](https://github.com/bats-core/bats-core) for automated testing.

```bash
# Install Bats and helpers (macOS)
brew install bats-core bats-assert bats-support bats-file

# Run all tests
make test
```

Tests also run automatically on every push and pull request via GitHub Actions.

## License

Apache License 2.0 — see [LICENSE](LICENSE) for details.
