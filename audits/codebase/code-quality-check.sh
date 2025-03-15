#!/bin/bash

# Code Quality Check Script
# This script analyzes the codebase for quality issues
# Usage: ./code-quality-check.sh [directory]

set -e

# Default to current directory if not specified
if [ -z "$1" ]; then
    CODE_DIR="."
else
    CODE_DIR="$1"
fi

# Create output directory
OUTPUT_DIR="code-audit-$(date +%Y-%m-%d)"
mkdir -p "$OUTPUT_DIR"

echo "Starting code quality check for directory: $CODE_DIR"
echo "Results will be saved to: $OUTPUT_DIR"

# Function to count lines of code by file type
count_lines() {
    echo "Counting lines of code by file type..."

    # Create a file to store the results
    LOC_FILE="$OUTPUT_DIR/lines-of-code.md"

    echo "# Lines of Code Analysis" > "$LOC_FILE"
    echo "" >> "$LOC_FILE"
    echo "Date: $(date)" >> "$LOC_FILE"
    echo "Directory: $CODE_DIR" >> "$LOC_FILE"
    echo "" >> "$LOC_FILE"
    echo "## File Type Summary" >> "$LOC_FILE"
    echo "" >> "$LOC_FILE"
    echo "| File Type | Files | Lines | Blank Lines | Comment Lines | Code Lines |" >> "$LOC_FILE"
    echo "|-----------|-------|-------|-------------|---------------|------------|" >> "$LOC_FILE"

    # Run cloc if available, otherwise use wc
    if command -v cloc &> /dev/null; then
        cloc "$CODE_DIR" --md --quiet --report-file="$OUTPUT_DIR/cloc-output.md"
        # Extract the table part and append to our file
        sed -n '/File Type/,/^$/p' "$OUTPUT_DIR/cloc-output.md" >> "$LOC_FILE"
    else
        # Fallback to using find and wc for basic counting
        echo "cloc not found, using basic counting method..."

        # Count for JavaScript/TypeScript files
        JS_TS_FILES=$(find "$CODE_DIR" -type f -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" | wc -l)
        JS_TS_LINES=$(find "$CODE_DIR" -type f -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" -exec cat {} \; | wc -l)
        echo "| JavaScript/TypeScript | $JS_TS_FILES | $JS_TS_LINES | N/A | N/A | N/A |" >> "$LOC_FILE"

        # Count for HTML/CSS files
        HTML_CSS_FILES=$(find "$CODE_DIR" -type f -name "*.html" -o -name "*.css" -o -name "*.scss" -o -name "*.sass" | wc -l)
        HTML_CSS_LINES=$(find "$CODE_DIR" -type f -name "*.html" -o -name "*.css" -o -name "*.scss" -o -name "*.sass" -exec cat {} \; | wc -l)
        echo "| HTML/CSS | $HTML_CSS_FILES | $HTML_CSS_LINES | N/A | N/A | N/A |" >> "$LOC_FILE"

        # Count for JSON files
        JSON_FILES=$(find "$CODE_DIR" -type f -name "*.json" | wc -l)
        JSON_LINES=$(find "$CODE_DIR" -type f -name "*.json" -exec cat {} \; | wc -l)
        echo "| JSON | $JSON_FILES | $JSON_LINES | N/A | N/A | N/A |" >> "$LOC_FILE"

        # Count for Markdown files
        MD_FILES=$(find "$CODE_DIR" -type f -name "*.md" | wc -l)
        MD_LINES=$(find "$CODE_DIR" -type f -name "*.md" -exec cat {} \; | wc -l)
        echo "| Markdown | $MD_FILES | $MD_LINES | N/A | N/A | N/A |" >> "$LOC_FILE"

        # Get total
        TOTAL_FILES=$(($JS_TS_FILES + $HTML_CSS_FILES + $JSON_FILES + $MD_FILES))
        TOTAL_LINES=$(($JS_TS_LINES + $HTML_CSS_LINES + $JSON_LINES + $MD_LINES))
        echo "| Total | $TOTAL_FILES | $TOTAL_LINES | N/A | N/A | N/A |" >> "$LOC_FILE"
    fi

    echo "✅ Lines of code analysis completed and saved to $LOC_FILE"
}

# Function to run ESLint if available
run_eslint() {
    echo "Running ESLint analysis..."

    if command -v eslint &> /dev/null; then
        # Create ESLint output file
        ESLINT_FILE="$OUTPUT_DIR/eslint-results.md"

        echo "# ESLint Analysis" > "$ESLINT_FILE"
        echo "" >> "$ESLINT_FILE"
        echo "Date: $(date)" >> "$ESLINT_FILE"
        echo "Directory: $CODE_DIR" >> "$ESLINT_FILE"
        echo "" >> "$ESLINT_FILE"

        # Run ESLint and capture the output
        ESLINT_OUTPUT=$(eslint "$CODE_DIR" -f json || true)

        # Save the raw output
        echo "$ESLINT_OUTPUT" > "$OUTPUT_DIR/eslint-results.json"

        # Process the output to create a markdown summary
        echo "## Summary" >> "$ESLINT_FILE"
        echo "" >> "$ESLINT_FILE"

        # Count total errors and warnings
        ERROR_COUNT=$(echo "$ESLINT_OUTPUT" | jq '[.[] | .errorCount] | add // 0')
        WARNING_COUNT=$(echo "$ESLINT_OUTPUT" | jq '[.[] | .warningCount] | add // 0')

        echo "- Total Errors: $ERROR_COUNT" >> "$ESLINT_FILE"
        echo "- Total Warnings: $WARNING_COUNT" >> "$ESLINT_FILE"
        echo "" >> "$ESLINT_FILE"

        # Create a table of files with issues
        echo "## Files with Issues" >> "$ESLINT_FILE"
        echo "" >> "$ESLINT_FILE"
        echo "| File | Errors | Warnings |" >> "$ESLINT_FILE"
        echo "|------|--------|----------|" >> "$ESLINT_FILE"

        echo "$ESLINT_OUTPUT" | jq -r '.[] | select(.errorCount > 0 or .warningCount > 0) | "| \(.filePath) | \(.errorCount) | \(.warningCount) |"' >> "$ESLINT_FILE"

        # List the most common issues
        echo "" >> "$ESLINT_FILE"
        echo "## Most Common Issues" >> "$ESLINT_FILE"
        echo "" >> "$ESLINT_FILE"
        echo "| Rule | Count |" >> "$ESLINT_FILE"
        echo "|------|-------|" >> "$ESLINT_FILE"

        echo "$ESLINT_OUTPUT" | jq -r '[.[].messages[].ruleId] | group_by(.) | map({rule: .[0], count: length}) | sort_by(.count) | reverse | .[] | "| \(.rule // "syntax error") | \(.count) |"' >> "$ESLINT_FILE"

        echo "✅ ESLint analysis completed and saved to $ESLINT_FILE"
    else
        echo "⚠️ ESLint not found, skipping static analysis"
    fi
}

# Function to check package dependencies
check_dependencies() {
    echo "Analyzing package dependencies..."

    # Create dependencies output file
    DEP_FILE="$OUTPUT_DIR/dependencies-analysis.md"

    echo "# Dependencies Analysis" > "$DEP_FILE"
    echo "" >> "$DEP_FILE"
    echo "Date: $(date)" >> "$DEP_FILE"
    echo "Directory: $CODE_DIR" >> "$DEP_FILE"
    echo "" >> "$DEP_FILE"

    # Check if package.json exists
    if [ -f "$CODE_DIR/package.json" ]; then
        echo "## Node.js Dependencies" >> "$DEP_FILE"
        echo "" >> "$DEP_FILE"

        # Extract dependencies from package.json
        DEPS=$(jq -r '.dependencies // {}' "$CODE_DIR/package.json")
        DEV_DEPS=$(jq -r '.devDependencies // {}' "$CODE_DIR/package.json")

        # Count dependencies
        DEP_COUNT=$(echo "$DEPS" | jq 'length')
        DEV_DEP_COUNT=$(echo "$DEV_DEPS" | jq 'length')

        echo "- Production Dependencies: $DEP_COUNT" >> "$DEP_FILE"
        echo "- Development Dependencies: $DEV_DEP_COUNT" >> "$DEP_FILE"
        echo "" >> "$DEP_FILE"

        # List production dependencies
        echo "### Production Dependencies" >> "$DEP_FILE"
        echo "" >> "$DEP_FILE"
        echo "| Package | Version |" >> "$DEP_FILE"
        echo "|---------|---------|" >> "$DEP_FILE"

        jq -r '.dependencies // {} | to_entries[] | "| \(.key) | \(.value) |"' "$CODE_DIR/package.json" >> "$DEP_FILE"

        # List development dependencies
        echo "" >> "$DEP_FILE"
        echo "### Development Dependencies" >> "$DEP_FILE"
        echo "" >> "$DEP_FILE"
        echo "| Package | Version |" >> "$DEP_FILE"
        echo "|---------|---------|" >> "$DEP_FILE"

        jq -r '.devDependencies // {} | to_entries[] | "| \(.key) | \(.value) |"' "$CODE_DIR/package.json" >> "$DEP_FILE"

        # Run npm audit if available
        if command -v npm &> /dev/null; then
            echo "" >> "$DEP_FILE"
            echo "## Security Audit" >> "$DEP_FILE"
            echo "" >> "$DEP_FILE"

            cd "$CODE_DIR" && npm audit --json > "$OUTPUT_DIR/npm-audit.json" 2>/dev/null || true

            # Check if audit produced output
            if [ -s "$OUTPUT_DIR/npm-audit.json" ]; then
                # Extract vulnerability counts
                AUDIT_SUMMARY=$(jq '.metadata.vulnerabilities' "$OUTPUT_DIR/npm-audit.json" 2>/dev/null || echo '{"info": 0, "low": 0, "moderate": 0, "high": 0, "critical": 0}')

                INFO=$(echo "$AUDIT_SUMMARY" | jq '.info // 0')
                LOW=$(echo "$AUDIT_SUMMARY" | jq '.low // 0')
                MODERATE=$(echo "$AUDIT_SUMMARY" | jq '.moderate // 0')
                HIGH=$(echo "$AUDIT_SUMMARY" | jq '.high // 0')
                CRITICAL=$(echo "$AUDIT_SUMMARY" | jq '.critical // 0')

                echo "| Severity | Count |" >> "$DEP_FILE"
                echo "|----------|-------|" >> "$DEP_FILE"
                echo "| Info | $INFO |" >> "$DEP_FILE"
                echo "| Low | $LOW |" >> "$DEP_FILE"
                echo "| Moderate | $MODERATE |" >> "$DEP_FILE"
                echo "| High | $HIGH |" >> "$DEP_FILE"
                echo "| Critical | $CRITICAL |" >> "$DEP_FILE"

                # If there are vulnerabilities, list them
                if [ "$(($INFO + $LOW + $MODERATE + $HIGH + $CRITICAL))" -gt 0 ]; then
                    echo "" >> "$DEP_FILE"
                    echo "### Vulnerability Details" >> "$DEP_FILE"
                    echo "" >> "$DEP_FILE"
                    echo "| Package | Severity | Vulnerable Versions | Recommendation |" >> "$DEP_FILE"
                    echo "|---------|----------|---------------------|---------------|" >> "$DEP_FILE"

                    jq -r '.vulnerabilities // {} | to_entries[] | .value | "| \(.name) | \(.severity) | \(.range) | \(.recommendation // "No fix available") |"' "$OUTPUT_DIR/npm-audit.json" >> "$DEP_FILE" 2>/dev/null || echo "| Error parsing audit data | | | |" >> "$DEP_FILE"
                fi
            else
                echo "No vulnerability data available or npm audit failed." >> "$DEP_FILE"
            fi
        else
            echo "npm not found, skipping security audit." >> "$DEP_FILE"
        fi
    else
        echo "No package.json found in $CODE_DIR, skipping dependency analysis." >> "$DEP_FILE"
    fi

    echo "✅ Dependency analysis completed and saved to $DEP_FILE"
}

# Function to analyze test coverage
analyze_test_coverage() {
    echo "Analyzing test coverage..."

    # Create test coverage output file
    TEST_FILE="$OUTPUT_DIR/test-coverage-analysis.md"

    echo "# Test Coverage Analysis" > "$TEST_FILE"
    echo "" >> "$TEST_FILE"
    echo "Date: $(date)" >> "$TEST_FILE"
    echo "Directory: $CODE_DIR" >> "$TEST_FILE"
    echo "" >> "$TEST_FILE"

    # Check if tests directory exists
    if [ -d "$CODE_DIR/__tests__" ] || [ -d "$CODE_DIR/tests" ] || [ -d "$CODE_DIR/test" ]; then
        echo "Test directories found. Counting test files..." >> "$TEST_FILE"
        echo "" >> "$TEST_FILE"

        # Count test files
        TEST_FILES=$(find "$CODE_DIR" -type f -path "*/test*/*" -o -path "*/__tests__/*" -o -name "*.test.js" -o -name "*.test.ts" -o -name "*.spec.js" -o -name "*.spec.ts" | wc -l)

        echo "- Test Files Found: $TEST_FILES" >> "$TEST_FILE"
        echo "" >> "$TEST_FILE"

        # List test files
        echo "## Test Files" >> "$TEST_FILE"
        echo "" >> "$TEST_FILE"

        find "$CODE_DIR" -type f -path "*/test*/*" -o -path "*/__tests__/*" -o -name "*.test.js" -o -name "*.test.ts" -o -name "*.spec.js" -o -name "*.spec.ts" | sort | while read -r file; do
            echo "- ${file#$CODE_DIR/}" >> "$TEST_FILE"
        done

        # Check for Jest coverage reports
        if [ -d "$CODE_DIR/coverage" ]; then
            echo "" >> "$TEST_FILE"
            echo "## Coverage Report" >> "$TEST_FILE"
            echo "" >> "$TEST_FILE"

            # Try to extract coverage data from lcov-report or other summaries
            if [ -f "$CODE_DIR/coverage/lcov-report/index.html" ]; then
                echo "Coverage report found at coverage/lcov-report/index.html" >> "$TEST_FILE"
                echo "" >> "$TEST_FILE"
                echo "Please run 'npm test -- --coverage' for detailed coverage information." >> "$TEST_FILE"
            elif [ -f "$CODE_DIR/coverage/coverage-summary.json" ]; then
                echo "Coverage summary found:" >> "$TEST_FILE"
                echo "" >> "$TEST_FILE"

                # Extract coverage data from summary JSON
                jq -r '.total | "- Statements: \(.statements.pct)%\n- Branches: \(.branches.pct)%\n- Functions: \(.functions.pct)%\n- Lines: \(.lines.pct)%"' "$CODE_DIR/coverage/coverage-summary.json" >> "$TEST_FILE"
            else
                echo "Coverage report directory exists but no readable summary found." >> "$TEST_FILE"
                echo "Please run 'npm test -- --coverage' for detailed coverage information." >> "$TEST_FILE"
            fi
        else
            echo "" >> "$TEST_FILE"
            echo "No coverage reports found." >> "$TEST_FILE"
            echo "Please run 'npm test -- --coverage' to generate coverage data." >> "$TEST_FILE"
        fi
    else
        echo "No test directories found." >> "$TEST_FILE"
    fi

    echo "✅ Test coverage analysis completed and saved to $TEST_FILE"
}

# Function to analyze code complexity
analyze_complexity() {
    echo "Analyzing code complexity..."

    # Create complexity output file
    COMPLEXITY_FILE="$OUTPUT_DIR/code-complexity-analysis.md"

    echo "# Code Complexity Analysis" > "$COMPLEXITY_FILE"
    echo "" >> "$COMPLEXITY_FILE"
    echo "Date: $(date)" >> "$COMPLEXITY_FILE"
    echo "Directory: $CODE_DIR" >> "$COMPLEXITY_FILE"
    echo "" >> "$COMPLEXITY_FILE"

    # If complexity analysis tools are available, use them
    if command -v jscpd &> /dev/null; then
        echo "## Code Duplication Analysis" >> "$COMPLEXITY_FILE"
        echo "" >> "$COMPLEXITY_FILE"

        # Run jscpd for code duplication
        jscpd "$CODE_DIR" --output "$OUTPUT_DIR/jscpd" --reporters "json" --silent || true

        if [ -f "$OUTPUT_DIR/jscpd/jscpd-report.json" ]; then
            # Extract duplication data
            DUPLICATION=$(jq '.statistics.total' "$OUTPUT_DIR/jscpd/jscpd-report.json")

            echo "### Duplication Statistics" >> "$COMPLEXITY_FILE"
            echo "" >> "$COMPLEXITY_FILE"
            echo "| Metric | Value |" >> "$COMPLEXITY_FILE"
            echo "|--------|-------|" >> "$COMPLEXITY_FILE"
            echo "| Total Files | $(echo "$DUPLICATION" | jq '.sources') |" >> "$COMPLEXITY_FILE"
            echo "| Total Lines | $(echo "$DUPLICATION" | jq '.lines') |" >> "$COMPLEXITY_FILE"
            echo "| Duplicated Lines | $(echo "$DUPLICATION" | jq '.duplicatedLines') |" >> "$COMPLEXITY_FILE"
            echo "| Duplication Percentage | $(echo "$DUPLICATION" | jq '.percentage')% |" >> "$COMPLEXITY_FILE"

            echo "" >> "$COMPLEXITY_FILE"
            echo "### Files with Highest Duplication" >> "$COMPLEXITY_FILE"
            echo "" >> "$COMPLEXITY_FILE"
            echo "| File | Duplicated Lines | Percentage |" >> "$COMPLEXITY_FILE"
            echo "|------|-----------------|------------|" >> "$COMPLEXITY_FILE"

            jq -r '.duplicates | sort_by(-.fragments[0].lines | length) | limit(10; .[]) | "| \(.fragments[0].name) | \(.fragments[0].lines | length) | \(.fragments[0].lines | length * 100 / (.fragments[0].end - .fragments[0].start) | floor)% |"' "$OUTPUT_DIR/jscpd/jscpd-report.json" >> "$COMPLEXITY_FILE" 2>/dev/null || echo "Error parsing duplication data" >> "$COMPLEXITY_FILE"
        else
            echo "jscpd ran but did not produce expected output." >> "$COMPLEXITY_FILE"
        fi
    else
        echo "jscpd not found, skipping code duplication analysis." >> "$COMPLEXITY_FILE"
    fi

    # Manual complexity analysis for large files
    echo "" >> "$COMPLEXITY_FILE"
    echo "## File Size Analysis" >> "$COMPLEXITY_FILE"
    echo "" >> "$COMPLEXITY_FILE"
    echo "### Largest Files" >> "$COMPLEXITY_FILE"
    echo "" >> "$COMPLEXITY_FILE"
    echo "| File | Lines | Bytes |" >> "$COMPLEXITY_FILE"
    echo "|------|-------|-------|" >> "$COMPLEXITY_FILE"

    # Find top 10 largest files by line count
    find "$CODE_DIR" -type f -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" | xargs wc -l 2>/dev/null | sort -nr | head -n 10 | while read -r lines file; do
        if [ "$file" != "total" ]; then
            size=$(ls -l "$file" | awk '{print $5}')
            echo "| ${file#$CODE_DIR/} | $lines | $size |" >> "$COMPLEXITY_FILE"
        fi
    done

    # Identify files with long functions or methods
    echo "" >> "$COMPLEXITY_FILE"
    echo "### Function Length Analysis" >> "$COMPLEXITY_FILE"
    echo "" >> "$COMPLEXITY_FILE"
    echo "Identifying potentially complex functions (based on line count)..." >> "$COMPLEXITY_FILE"
    echo "" >> "$COMPLEXITY_FILE"

    # This is a simple approximation, a proper parser would be better
    echo "#### Files containing functions with more than 50 lines:" >> "$COMPLEXITY_FILE"
    echo "" >> "$COMPLEXITY_FILE"

    find "$CODE_DIR" -type f -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" | while read -r file; do
        # Check for function/method definitions followed by large blocks
        grep -n -A 1 -E "(function |=>|\) {| class .* {)" "$file" 2>/dev/null | grep -A 1 "{" | grep -v "=" | while read -r line; do
            if [[ "$line" =~ [0-9]+: ]]; then
                lineno=$(echo "$line" | grep -o -E "^[0-9]+")

                # Count braces to find function end
                if [ -n "$lineno" ]; then
                    # Simple approach: count lines until we see probable end of function
                    endline=$(tail -n +$lineno "$file" | grep -n -E "^}$|^  }$|^    }$" | head -n 1 | cut -d: -f1)
                    if [ -n "$endline" ]; then
                        functionlength=$((endline))
                        if [ $functionlength -gt 50 ]; then
                            echo "- ${file#$CODE_DIR/}:$lineno (~$functionlength lines)" >> "$COMPLEXITY_FILE"
                        fi
                    fi
                fi
            fi
        done
    done

    echo "✅ Code complexity analysis completed and saved to $COMPLEXITY_FILE"
}

# Function to generate summary report
generate_summary() {
    echo "Generating summary report..."

    # Create summary file
    SUMMARY_FILE="$OUTPUT_DIR/summary.md"

    echo "# Code Quality Audit Summary" > "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    echo "Date: $(date)" >> "$SUMMARY_FILE"
    echo "Directory: $CODE_DIR" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"

    echo "## Overview" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"

    # Copy LOC summary if it exists
    if [ -f "$OUTPUT_DIR/lines-of-code.md" ]; then
        # Extract file type table
        sed -n '/File Type Summary/,/^$/p' "$OUTPUT_DIR/lines-of-code.md" >> "$SUMMARY_FILE"
    fi

    # Summarize ESLint findings if they exist
    if [ -f "$OUTPUT_DIR/eslint-results.md" ]; then
        echo "" >> "$SUMMARY_FILE"
        echo "## Code Quality Issues" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"

        # Extract error and warning counts
        sed -n '/Summary/,/^$/p' "$OUTPUT_DIR/eslint-results.md" >> "$SUMMARY_FILE"

        # Extract most common issues table
        echo "" >> "$SUMMARY_FILE"
        echo "### Most Common Issues" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
        sed -n '/Most Common Issues/,/^$/p' "$OUTPUT_DIR/eslint-results.md" | grep -v "Most Common Issues" | grep -v "^$" | head -n 6 >> "$SUMMARY_FILE"
    fi

    # Summarize dependency findings if they exist
    if [ -f "$OUTPUT_DIR/dependencies-analysis.md" ]; then
        echo "" >> "$SUMMARY_FILE"
        echo "## Dependencies" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"

        # Extract dependency counts
        sed -n '/Node.js Dependencies/,/^$/p' "$OUTPUT_DIR/dependencies-analysis.md" >> "$SUMMARY_FILE"

        # Extract security findings if they exist
        if grep -q "Vulnerability Details" "$OUTPUT_DIR/dependencies-analysis.md"; then
            echo "" >> "$SUMMARY_FILE"
            echo "### Security Vulnerabilities" >> "$SUMMARY_FILE"
            echo "" >> "$SUMMARY_FILE"
            sed -n '/Severity/,/^$/p' "$OUTPUT_DIR/dependencies-analysis.md" >> "$SUMMARY_FILE"
        fi
    fi

    # Summarize test coverage if available
    if [ -f "$OUTPUT_DIR/test-coverage-analysis.md" ]; then
        echo "" >> "$SUMMARY_FILE"
        echo "## Testing" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"

        # Extract test file count
        grep "Test Files Found" "$OUTPUT_DIR/test-coverage-analysis.md" >> "$SUMMARY_FILE"

        # Extract coverage data if available
        if grep -q "Coverage summary found" "$OUTPUT_DIR/test-coverage-analysis.md"; then
            echo "" >> "$SUMMARY_FILE"
            sed -n '/Coverage summary found/,/^$/p' "$OUTPUT_DIR/test-coverage-analysis.md" >> "$SUMMARY_FILE"
        fi
    fi

    # Summarize code complexity if available
    if [ -f "$OUTPUT_DIR/code-complexity-analysis.md" ]; then
        echo "" >> "$SUMMARY_FILE"
        echo "## Code Complexity" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"

        # Extract duplication percentage if available
        if grep -q "Duplication Percentage" "$OUTPUT_DIR/code-complexity-analysis.md"; then
            grep "Duplication Percentage" "$OUTPUT_DIR/code-complexity-analysis.md" >> "$SUMMARY_FILE"
        fi

        # List top 3 largest files
        echo "" >> "$SUMMARY_FILE"
        echo "### Largest Files" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
        sed -n '/File \| Lines \| Bytes/,/^$/p' "$OUTPUT_DIR/code-complexity-analysis.md" | head -n 4 >> "$SUMMARY_FILE"
    fi

    echo "" >> "$SUMMARY_FILE"
    echo "## Recommendations" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    echo "1. Review the detailed reports for comprehensive findings" >> "$SUMMARY_FILE"
    echo "2. Address any security vulnerabilities identified in the dependency analysis" >> "$SUMMARY_FILE"
    echo "3. Fix the most common ESLint issues to improve code quality" >> "$SUMMARY_FILE"
    echo "4. Consider refactoring any files with high complexity or excessive size" >> "$SUMMARY_FILE"
    echo "5. Improve test coverage in areas with insufficient tests" >> "$SUMMARY_FILE"

    echo "✅ Summary report generated and saved to $SUMMARY_FILE"
}

# Run all the analysis functions
count_lines
run_eslint
check_dependencies
analyze_test_coverage
analyze_complexity
generate_summary

echo "Code quality check completed! All results saved to $OUTPUT_DIR"
echo "Summary report available at $OUTPUT_DIR/summary.md"
