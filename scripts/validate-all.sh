#!/bin/bash
# Master validation script - runs all validations

set -e

echo "🚀 DevOps Technical Test - Complete Validation Suite"
echo "==================================================="
echo ""

SCRIPT_DIR="$(dirname "$0")"
cd "$SCRIPT_DIR/.."

# Initialize counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run validation and track results
run_validation() {
    local test_name="$1"
    local script_path="$2"
    
    echo "🧪 Running $test_name..."
    echo "----------------------------------------"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ -x "$script_path" ]; then
        if $script_path; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
            echo "✅ $test_name - PASSED"
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
            echo "❌ $test_name - FAILED"
        fi
    else
        echo "⚠️  $test_name - Script not found or not executable: $script_path"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    echo ""
}

# Run all validations
echo "Starting comprehensive validation..."
echo ""

# 1. Terraform validation
run_validation "Terraform Infrastructure" "./scripts/validate-terraform.sh"

# 2. Kubernetes manifests validation  
run_validation "Kubernetes Manifests" "./scripts/validate-kubernetes.sh"

# 3. Helm chart validation
run_validation "Helm Chart" "./scripts/validate-helm.sh"

# 4. GitHub Actions validation
run_validation "GitHub Actions Workflow" "./scripts/validate-github-actions.sh"

# 5. Documentation validation
run_validation "Documentation" "./scripts/validate-docs.sh"

# Summary
echo "📊 VALIDATION SUMMARY"
echo "===================="
echo "Total tests: $TOTAL_TESTS"
echo "✅ Passed: $PASSED_TESTS"
echo "❌ Failed: $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo "🎉 ALL VALIDATIONS PASSED!"
    echo ""
    echo "Your solution is ready for submission. Next steps:"
    echo "1. Review your implementation once more"
    echo "2. Update documentation with any final changes"
    echo "3. Commit your changes"  
    echo "4. Create a Pull Request with detailed description"
    echo ""
    exit 0
else
    echo "🔥 SOME VALIDATIONS FAILED"
    echo ""
    echo "Please fix the issues above before submitting your solution."
    echo "You can run individual validation scripts to focus on specific areas:"
    echo ""
    echo "  ./scripts/validate-terraform.sh"
    echo "  ./scripts/validate-kubernetes.sh"
    echo "  ./scripts/validate-helm.sh"  
    echo "  ./scripts/validate-github-actions.sh"
    echo "  ./scripts/validate-docs.sh"
    echo ""
    exit 1
fi