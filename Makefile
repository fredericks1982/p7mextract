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

.PHONY: all install test fixtures clean help

# Default target
all: test

# Install the script to ~/.local/bin
install:
	@mkdir -p ~/.local/bin
	@cp p7mextract ~/.local/bin/p7mextract
	@chmod +x ~/.local/bin/p7mextract
	@echo "✓ Installed to ~/.local/bin/p7mextract"
	@if echo "$$PATH" | tr ':' '\n' | grep -qx "$$HOME/.local/bin"; then \
		echo "✓ ~/.local/bin is already in your PATH"; \
	else \
		SHELL_NAME=$$(basename "$$SHELL"); \
		if [ "$$SHELL_NAME" = "zsh" ]; then \
			SHELL_RC="$$HOME/.zshrc"; \
		else \
			SHELL_RC="$$HOME/.bashrc"; \
		fi; \
		echo 'export PATH="$$HOME/.local/bin:$$PATH"' >> "$$SHELL_RC"; \
		echo "✓ Added ~/.local/bin to PATH in $$SHELL_RC"; \
		echo "  Restart your terminal or run: source $$SHELL_RC"; \
	fi

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
