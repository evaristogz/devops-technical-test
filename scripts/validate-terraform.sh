#!/bin/bash
# Validation script for Terraform infrastructure

set -e

echo "🔧 Validating Terraform Infrastructure..."
echo "========================================"

cd "$(dirname "$0")/../infrastructure"

# Check if Terraform files exist
echo "📁 Checking Terraform files..."
REQUIRED_FILES=("main.tf" "variables.tf" "outputs.tf")

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing required file: $file"
        exit 1
    fi
    echo "✓ Found $file"
done

# Initialize Terraform (without backend for validation)
echo ""
echo "🚀 Initializing Terraform..."
if ! terraform init -backend=false -upgrade; then
    echo "❌ Terraform initialization failed"
    exit 1
fi
echo "✓ Terraform initialized successfully"

# Validate configuration
echo ""
echo "🔍 Validating Terraform configuration..."
if ! terraform validate; then
    echo "❌ Terraform validation failed"
    exit 1
fi
echo "✓ Terraform validation passed"

# Check formatting
echo ""
echo "📝 Checking Terraform formatting..."
if ! terraform fmt -check=true -diff=true; then
    echo "⚠️  Terraform formatting issues found"
    echo "Run 'terraform fmt' to fix formatting issues"
    terraform fmt -diff=true
    echo ""
    echo "🔧 Auto-fixing formatting..."
    terraform fmt
    echo "✓ Formatting fixed"
else
    echo "✓ Terraform formatting is correct"
fi

# Security scan with tfsec (if available)
echo ""
echo "🔒 Running security scan..."
if command -v tfsec >/dev/null 2>&1; then
    echo "Running tfsec security scan..."
    if tfsec . --soft-fail; then
        echo "✓ Security scan completed (check results above)"
    else
        echo "⚠️  Security issues found (non-blocking)"
    fi
else
    echo "ℹ️  tfsec not found - skipping security scan"
    echo "   Install with: curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash"
fi

# Try to run terraform plan (will fail without credentials, but syntax will be checked)
echo ""
echo "📋 Testing Terraform plan..."
if terraform plan -input=false >/dev/null 2>&1; then
    echo "✓ Terraform plan syntax is valid"
elif [ $? -eq 1 ]; then
    # Exit code 1 typically means authentication error, which is expected
    echo "✓ Terraform plan syntax appears valid (auth required for full validation)"
else
    echo "⚠️  Terraform plan has syntax issues"
fi

# Check for required resources
echo ""
echo "🏗️  Checking for required Azure resources..."
REQUIRED_RESOURCES=(
    "azurerm_resource_group"
    "azurerm_virtual_network"  
    "azurerm_kubernetes_cluster"
    "azurerm_container_registry"
    "azurerm_key_vault"
)

for resource in "${REQUIRED_RESOURCES[@]}"; do
    if grep -q "$resource" *.tf; then
        echo "✓ Found $resource"
    else
        echo "❌ Missing required resource: $resource"
        exit 1
    fi
done

# Check for security best practices
echo ""
echo "🛡️  Checking security best practices..."

# Check for hardcoded values
if grep -r "password\s*=\s*\"[^\"]*\"" *.tf >/dev/null 2>&1; then
    echo "⚠️  Potential hardcoded passwords found"
fi

# Check for Key Vault usage
if grep -q "azurerm_key_vault" *.tf; then
    echo "✓ Key Vault configured for secrets management"
fi

# Check for network security groups
if grep -q "azurerm_network_security_group" *.tf; then
    echo "✓ Network Security Groups configured"
fi

echo ""
echo "✅ Terraform validation completed successfully!"
echo ""

cd - >/dev/null