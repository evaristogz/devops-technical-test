#!/bin/bash
# Validation script for GitHub Actions workflow

set -e

echo "🔄 Validating GitHub Actions workflow..."
echo "======================================"

cd "$(dirname "$0")/.."

# Check if workflow file exists
WORKFLOW_FILE=".github/workflows/ci-cd.yml"

if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "❌ GitHub Actions workflow file not found: $WORKFLOW_FILE"
    exit 1
fi

echo "✓ Found GitHub Actions workflow file"

# Basic YAML syntax check
echo ""
echo "📝 Checking YAML syntax..."
if python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW_FILE', 'r'))" 2>/dev/null; then
    echo "✓ YAML syntax is valid"
elif command -v yamllint >/dev/null 2>&1; then
    if yamllint "$WORKFLOW_FILE"; then
        echo "✓ YAML syntax is valid (yamllint)"
    else
        echo "❌ YAML syntax errors found"
        exit 1
    fi
else
    echo "ℹ️  Cannot validate YAML syntax (install python3-yaml or yamllint)"
fi

# actionlint validation (if available)
echo ""
echo "🔧 Advanced workflow validation..."
if command -v actionlint >/dev/null 2>&1; then
    echo "Running actionlint..."
    if actionlint "$WORKFLOW_FILE"; then
        echo "✓ actionlint validation passed"
    else
        echo "❌ actionlint found issues"
        exit 1
    fi
else
    echo "ℹ️  actionlint not found - install for better validation"
    echo "   Install: go install github.com/rhymond/actionlint/cmd/actionlint@latest"
fi

# Check for required workflow elements
echo ""
echo "🏗️  Checking workflow structure..."

REQUIRED_ELEMENTS=(
    "on:"
    "jobs:"
    "runs-on:"
)

for element in "${REQUIRED_ELEMENTS[@]}"; do
    if grep -q "$element" "$WORKFLOW_FILE"; then
        echo "✓ Found $element"
    else
        echo "❌ Missing required element: $element"
        exit 1
    fi
done

# Check for Azure-specific actions
echo ""
echo "☁️  Checking Azure integration..."

AZURE_ELEMENTS=(
    "azure/login"
    "azure/"
    "AZURE_"
)

AZURE_FOUND=0
for element in "${AZURE_ELEMENTS[@]}"; do
    if grep -q "$element" "$WORKFLOW_FILE"; then
        echo "✓ Found Azure integration: $element"
        AZURE_FOUND=1
    fi
done

if [ $AZURE_FOUND -eq 0 ]; then
    echo "⚠️  No Azure integration found in workflow"
fi

echo ""
echo "✅ GitHub Actions workflow validation completed!"
echo ""
echo "💡 Next steps:"
echo "   1. Complete TODO sections in $WORKFLOW_FILE"
echo "   2. Add proper Azure authentication (OIDC recommended)"
echo "   3. Add secrets to GitHub repository settings"
echo "   4. Test workflow with: git push origin main"

cd - >/dev/null
