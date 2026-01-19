#!/bin/bash
# Auto-scoring script for submissions (reference only)

set -e

echo "🏆 DevOps Technical Test - Auto Evaluation"
echo "=========================================="
echo "Note: This is for reference only, not official scoring"
echo ""

cd "$(dirname "$0")/.."

TOTAL_SCORE=0
MAX_SCORE=100

# Terraform (25 points)
echo "🔧 Evaluating Terraform..."
TERRAFORM_SCORE=0
if [ -f "infrastructure/main.tf" ] && grep -q "azurerm_resource_group" infrastructure/main.tf; then
    TERRAFORM_SCORE=$((TERRAFORM_SCORE + 5))
    echo "✓ Resource Group defined (+5)"
fi

if grep -q "azurerm_kubernetes_cluster" infrastructure/*.tf; then
    TERRAFORM_SCORE=$((TERRAFORM_SCORE + 8))
    echo "✓ AKS Cluster defined (+8)"
fi

if grep -q "azurerm_container_registry" infrastructure/*.tf; then
    TERRAFORM_SCORE=$((TERRAFORM_SCORE + 4))
    echo "✓ ACR defined (+4)"
fi

if grep -q "azurerm_key_vault" infrastructure/*.tf; then
    TERRAFORM_SCORE=$((TERRAFORM_SCORE + 4))
    echo "✓ Key Vault defined (+4)"
fi

if grep -q "azurerm_virtual_network" infrastructure/*.tf; then
    TERRAFORM_SCORE=$((TERRAFORM_SCORE + 4))
    echo "✓ Virtual Network defined (+4)"
fi

echo "Terraform Score: $TERRAFORM_SCORE/25"
TOTAL_SCORE=$((TOTAL_SCORE + TERRAFORM_SCORE))

# Kubernetes (25 points)
echo ""
echo "☸️  Evaluating Kubernetes..."
K8S_SCORE=0
K8S_FILES=$(find k8s-manifests -name "*.yaml" -o -name "*.yml" 2>/dev/null | wc -l)

if [ "$K8S_FILES" -gt 5 ]; then
    K8S_SCORE=$((K8S_SCORE + 10))
    echo "✓ Multiple manifests created (+10)"
fi

if grep -q "kind: Deployment" k8s-manifests/**/*.yaml k8s-manifests/*.yaml 2>/dev/null; then
    K8S_SCORE=$((K8S_SCORE + 5))
    echo "✓ Deployments defined (+5)"
fi

if grep -q "kind: Service" k8s-manifests/**/*.yaml k8s-manifests/*.yaml 2>/dev/null; then
    K8S_SCORE=$((K8S_SCORE + 3))
    echo "✓ Services defined (+3)"
fi

if grep -q "HorizontalPodAutoscaler" k8s-manifests/**/*.yaml k8s-manifests/*.yaml 2>/dev/null; then
    K8S_SCORE=$((K8S_SCORE + 3))
    echo "✓ HPA configured (+3)"
fi

if grep -q "resources:" k8s-manifests/**/*.yaml k8s-manifests/*.yaml 2>/dev/null; then
    K8S_SCORE=$((K8S_SCORE + 4))
    echo "✓ Resource limits defined (+4)"
fi

echo "Kubernetes Score: $K8S_SCORE/25"
TOTAL_SCORE=$((TOTAL_SCORE + K8S_SCORE))

# Helm (20 points)
echo ""
echo "⚙️  Evaluating Helm Chart..."
HELM_SCORE=0

if [ -f "helm-chart/Chart.yaml" ] && [ -f "helm-chart/values.yaml" ]; then
    HELM_SCORE=$((HELM_SCORE + 5))
    echo "✓ Basic chart structure (+5)"
fi

if [ -d "helm-chart/templates" ] && [ "$(ls -A helm-chart/templates 2>/dev/null)" ]; then
    HELM_SCORE=$((HELM_SCORE + 8))
    echo "✓ Templates directory with content (+8)"
fi

if [ -f "helm-chart/values.schema.json" ]; then
    HELM_SCORE=$((HELM_SCORE + 3))
    echo "✓ Values schema defined (+3)"
fi

if [ -d "helm-chart/environments" ] && [ "$(ls -A helm-chart/environments 2>/dev/null)" ]; then
    HELM_SCORE=$((HELM_SCORE + 4))
    echo "✓ Environment-specific values (+4)"
fi

echo "Helm Score: $HELM_SCORE/20"
TOTAL_SCORE=$((TOTAL_SCORE + HELM_SCORE))

# GitHub Actions (20 points)
echo ""
echo "🔄 Evaluating GitHub Actions..."
CI_SCORE=0

if [ -f ".github/workflows/ci-cd.yml" ]; then
    CI_SCORE=$((CI_SCORE + 5))
    echo "✓ CI/CD workflow file exists (+5)"
    
    if grep -q "terraform" .github/workflows/ci-cd.yml; then
        CI_SCORE=$((CI_SCORE + 5))
        echo "✓ Terraform integration (+5)"
    fi
    
    if grep -q "docker" .github/workflows/ci-cd.yml; then
        CI_SCORE=$((CI_SCORE + 5))
        echo "✓ Docker build integration (+5)"
    fi
    
    if grep -q "helm" .github/workflows/ci-cd.yml; then
        CI_SCORE=$((CI_SCORE + 3))
        echo "✓ Helm deployment (+3)"
    fi
    
    if grep -q "azure" .github/workflows/ci-cd.yml; then
        CI_SCORE=$((CI_SCORE + 2))
        echo "✓ Azure integration (+2)"
    fi
fi

echo "GitHub Actions Score: $CI_SCORE/20"
TOTAL_SCORE=$((TOTAL_SCORE + CI_SCORE))

# Documentation (10 points)
echo ""
echo "📚 Evaluating Documentation..."
DOC_SCORE=0

# Check if README has been modified from original
if [ -f "README.md" ] && [ -s "README.md" ]; then
    DOC_SCORE=$((DOC_SCORE + 3))
    echo "✓ README.md present (+3)"
fi

# Check for code comments and documentation
COMMENT_FILES=$(find . -name "*.tf" -o -name "*.yaml" -o -name "*.yml" | xargs grep -l "#.*TODO.*completed\|#.*COMPLETED\|# Added by" 2>/dev/null | wc -l)
if [ "$COMMENT_FILES" -gt 3 ]; then
    DOC_SCORE=$((DOC_SCORE + 4))
    echo "✓ Good documentation practices (+4)"
fi

# Check for architectural decisions documentation
if grep -qi "decision\|rationale\|assumption" README.md 2>/dev/null; then
    DOC_SCORE=$((DOC_SCORE + 3))
    echo "✓ Architectural decisions documented (+3)"
fi

echo "Documentation Score: $DOC_SCORE/10"
TOTAL_SCORE=$((TOTAL_SCORE + DOC_SCORE))

# Final Results
echo ""
echo "🏆 FINAL EVALUATION RESULTS"
echo "=========================="
echo "Total Score: $TOTAL_SCORE/$MAX_SCORE"
echo ""

if [ $TOTAL_SCORE -ge 80 ]; then
    echo "🎉 EXCELLENT! Outstanding DevOps implementation"
    echo "Grade: A (80-100 points)"
elif [ $TOTAL_SCORE -ge 65 ]; then
    echo "✅ GOOD! Solid DevOps foundation with room for improvement"
    echo "Grade: B (65-79 points)"
elif [ $TOTAL_SCORE -ge 50 ]; then
    echo "⚠️  ACCEPTABLE! Basic requirements met, needs significant improvement"
    echo "Grade: C (50-64 points)"
else
    echo "❌ NEEDS IMPROVEMENT! Major gaps in implementation"
    echo "Grade: D (0-49 points)"
fi

echo ""
echo "Note: This auto-evaluation is for reference only."
echo "Manual review will consider code quality, security, and best practices."
