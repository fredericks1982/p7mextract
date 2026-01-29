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

# setup_fixtures.sh - Generate test fixture files for p7mextract tests
# Run this script once before running the test suite

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔧 Setting up test fixtures..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 1. Create a self-signed certificate for testing
echo -e "${YELLOW}Creating test certificate...${NC}"
openssl req -x509 -newkey rsa:2048 -keyout test_key.pem -out test_cert.pem -days 365 -nodes -subj "/CN=Test/O=Test/C=IT" 2>/dev/null

# 2. Create sample content files
echo -e "${YELLOW}Creating sample content files...${NC}"

# Sample PDF-like content (minimal PDF structure)
cat > sample.pdf << 'EOF'
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>
endobj
4 0 obj
<< /Length 44 >>
stream
BT /F1 12 Tf 100 700 Td (Test PDF Content) Tj ET
endstream
endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000214 00000 n 
trailer << /Size 5 /Root 1 0 R >>
startxref
307
%%EOF
EOF

# Sample text content
echo "This is a test text file for p7mextract testing." > sample.txt

# Sample XML content
cat > sample.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<document>
    <title>Test Document</title>
    <content>This is test content for p7mextract.</content>
</document>
EOF

# 3. Create signed p7m files in DER format
echo -e "${YELLOW}Creating DER format p7m files...${NC}"

# Valid DER format with .pdf extension
openssl smime -sign -in sample.pdf -out valid_der.pdf.p7m -signer test_cert.pem -inkey test_key.pem -outform DER -nodetach 2>/dev/null

# Valid DER format with .txt extension
openssl smime -sign -in sample.txt -out valid_der.txt.p7m -signer test_cert.pem -inkey test_key.pem -outform DER -nodetach 2>/dev/null

# Valid DER format with .xml extension
openssl smime -sign -in sample.xml -out valid_der.xml.p7m -signer test_cert.pem -inkey test_key.pem -outform DER -nodetach 2>/dev/null

# Valid DER format without intermediate extension (should default to .pdf)
openssl smime -sign -in sample.pdf -out no_ext.p7m -signer test_cert.pem -inkey test_key.pem -outform DER -nodetach 2>/dev/null

# 4. Create signed p7m files in PEM format
echo -e "${YELLOW}Creating PEM format p7m files...${NC}"

openssl smime -sign -in sample.pdf -out valid_pem.pdf.p7m -signer test_cert.pem -inkey test_key.pem -outform PEM -nodetach 2>/dev/null

# 5. Create invalid/corrupted p7m file
echo -e "${YELLOW}Creating invalid p7m file...${NC}"
echo "This is not a valid p7m file, just random garbage data." > invalid.p7m

# 6. Create files with special names
echo -e "${YELLOW}Creating files with special names...${NC}"

# File with spaces in name
openssl smime -sign -in sample.pdf -out "file with spaces.pdf.p7m" -signer test_cert.pem -inkey test_key.pem -outform DER -nodetach 2>/dev/null

# File with uppercase extension (use different base name to avoid case-insensitive filesystem issue)
openssl smime -sign -in sample.pdf -out "uppercase_ext.pdf.P7M" -signer test_cert.pem -inkey test_key.pem -outform DER -nodetach 2>/dev/null

# 7. Create a read-only file for permission testing
echo -e "${YELLOW}Creating permission test files...${NC}"
cp valid_der.pdf.p7m readonly_test.pdf.p7m
# Note: We'll set permissions in the test itself to avoid issues

# 8. Summary
echo ""
echo -e "${GREEN}✓ Fixtures created successfully!${NC}"
echo ""
echo "Created files:"
ls -la *.p7m *.pdf *.txt *.xml *.pem 2>/dev/null | awk '{print "  " $NF " (" $5 " bytes)"}'

echo ""
echo "You can now run: bats ../p7mextract.bats"
