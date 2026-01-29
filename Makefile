.PHONY: all install test fixtures clean help

# Default target
all: test

# Install the script to ~/.local/bin
install:
	@mkdir -p ~/.local/bin
	@cp p7mextract ~/.local/bin/p7mextract
	@chmod +x ~/.local/bin/p7mextract
	@echo "✓ Installed to ~/.local/bin/p7mextract"

# Setup test fixtures
fixtures:
	@cd test/fixtures && chmod +x setup_fixtures.sh && ./setup_fixtures.sh

# Run all tests
test: fixtures
	@bats test/p7mextract.bats

# Run tests with verbose output
test-verbose: fixtures
	@bats --tap test/p7mextract.bats

# Run tests with timing
test-timing: fixtures
	@bats --timing test/p7mextract.bats

# Run a specific test (usage: make test-filter FILTER="extracts valid")
test-filter: fixtures
	@bats test/p7mextract.bats --filter "$(FILTER)"

# Clean generated fixtures
clean:
	@rm -f test/fixtures/*.pem
	@rm -f test/fixtures/*.pdf
	@rm -f test/fixtures/*.txt
	@rm -f test/fixtures/*.xml
	@rm -f test/fixtures/*.p7m
	@rm -f test/fixtures/*.P7M
	@echo "✓ Cleaned test fixtures"

# Show help
help:
	@echo "Available targets:"
	@echo "  make install       - Install p7mextract to ~/.local/bin"
	@echo "  make test          - Run all tests"
	@echo "  make test-verbose  - Run tests with TAP output"
	@echo "  make test-timing   - Run tests with timing info"
	@echo "  make test-filter FILTER=\"pattern\" - Run specific tests"
	@echo "  make fixtures      - Generate test fixtures only"
	@echo "  make clean         - Remove generated fixtures"
