#!/bin/bash
# Validation script for Helm chart

set -e

echo "⚙️  Validating Helm chart..."
echo "============================"

cd "$(dirname "$0")/.."

# Check if helm-chart directory exists
if [ ! -d "helm-chart" ]; then
    echo "❌ helm-chart directory not found"
    exit 1
fi

echo "📁 Checking Helm chart structure..."

# Check for required files
REQUIRED_FILES=(
    "helm-chart/Chart.yaml"
    "helm-chart/values.yaml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ Found $file"
    else
        echo "❌ Missing required file: $file"
        exit 1
    fi
done

cd helm-chart

# Helm lint
echo ""
echo "🔍 Running Helm lint..."
if helm lint .; then
    echo "✓ Helm lint passed"
else
    echo "❌ Helm lint failed"
    exit 1
fi

# Template rendering test
echo ""
echo "🎨 Testing template rendering..."
if helm template test-release . --debug >/dev/null; then
    echo "✓ Template rendering successful"
else
    echo "❌ Template rendering failed"
    helm template test-release . --debug
    exit 1
fi

# Test with different values files
echo ""
echo "📝 Testing with environment-specific values..."

for values_file in environments/values-*.yaml; do
    if [ -f "$values_file" ]; then
        echo "Testing with $values_file..."
        if helm template test-release . -f "$values_file" >/dev/null 2>&1; then
            echo "✓ $values_file"
        else
            echo "❌ $values_file failed"
            helm template test-release . -f "$values_file"
            exit 1
        fi
    fi
done

# Schema validation (if schema exists)
if [ -f "values.schema.json" ]; then
    echo ""
    echo "📋 Schema validation..."
    echo "✓ values.schema.json found"
    # Note: Helm 3.7+ has built-in schema validation
else
    echo ""
    echo "ℹ️  values.schema.json not found - consider adding for validation"
fi

echo ""
echo "✅ Helm chart validation completed!"
echo ""
echo "💡 Next steps:"
echo "   1. Add templates/ directory with Kubernetes manifests"
echo "   2. Implement _helpers.tpl with reusable templates"
echo "   3. Add tests/ directory with connectivity tests"
echo "   4. Test deployment: helm install test-release ./helm-chart"

cd - >/dev/null
