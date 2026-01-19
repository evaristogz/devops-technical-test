#!/bin/bash
# Validation script for Kubernetes manifests

set -e

echo "☸️  Validating Kubernetes manifests..."
echo "====================================="

cd "$(dirname "$0")/.."

# Check if k8s-manifests directory exists
if [ ! -d "k8s-manifests" ]; then
    echo "❌ k8s-manifests directory not found"
    exit 1
fi

echo "📁 Checking Kubernetes manifests directory..."

# Check for YAML files
YAML_FILES=$(find k8s-manifests -name "*.yaml" -o -name "*.yml" 2>/dev/null || echo "")
if [ -z "$YAML_FILES" ]; then
    echo "⚠️  No YAML files found in k8s-manifests/"
    echo "   Create manifests as described in k8s-manifests/README.md"
    exit 1
fi

echo "✓ Found YAML files to validate"

# Basic YAML syntax validation
echo ""
echo "🔍 Validating YAML syntax..."
SYNTAX_ERRORS=0

while IFS= read -r file; do
    if [ -f "$file" ]; then
        # Use kubectl dry-run for validation
        if kubectl --dry-run=client apply -f "$file" >/dev/null 2>&1; then
            echo "✓ $file"
        else
            echo "❌ $file - syntax error"
            kubectl --dry-run=client apply -f "$file" 2>&1 | head -5
            SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
        fi
    fi
done <<< "$YAML_FILES"

if [ $SYNTAX_ERRORS -gt 0 ]; then
    echo ""
    echo "❌ Found $SYNTAX_ERRORS files with syntax errors"
    exit 1
fi

# Check for required files (basic structure)
echo ""
echo "🏗️  Checking for required manifest types..."

REQUIRED_KINDS=(
    "Namespace"
    "Deployment" 
    "Service"
)

for kind in "${REQUIRED_KINDS[@]}"; do
    if grep -r "kind: $kind" k8s-manifests/ >/dev/null 2>&1; then
        echo "✓ Found $kind manifests"
    else
        echo "⚠️  No $kind manifests found"
    fi
done

# Advanced validation (if tools available)
echo ""
echo "🔧 Advanced validation..."

# kubeval validation
if command -v kubeval >/dev/null 2>&1; then
    echo "Running kubeval validation..."
    if kubeval k8s-manifests/**/*.yaml k8s-manifests/*.yaml 2>/dev/null; then
        echo "✓ kubeval validation passed"
    else
        echo "⚠️  kubeval found issues (non-blocking)"
    fi
else
    echo "ℹ️  kubeval not found - install for better validation"
fi

# kube-score analysis  
if command -v kube-score >/dev/null 2>&1; then
    echo "Running kube-score analysis..."
    if kube-score score k8s-manifests/**/*.yaml k8s-manifests/*.yaml 2>/dev/null | head -20; then
        echo "✓ kube-score analysis completed"
    else
        echo "ℹ️  kube-score analysis completed (see results above)"
    fi
else
    echo "ℹ️  kube-score not found - install for security analysis"
fi

echo ""
echo "✅ Kubernetes validation completed!"
echo ""
echo "💡 Next steps:"
echo "   1. Create all required manifests listed in k8s-manifests/README.md"
echo "   2. Ensure proper resource requests/limits are set"
echo "   3. Add health checks and security contexts"
echo "   4. Test with: kubectl apply --dry-run=client -f k8s-manifests/"
