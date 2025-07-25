#!/bin/bash

# OpenShift Pipelines Setup Script
# This script deploys all the necessary components for the namespace creation pipeline

set -e

NAMESPACE="openshift-pipelines"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Setting up OpenShift Pipelines for namespace creation..."

# Function to check if namespace exists
check_namespace() {
    if ! oc get namespace "$NAMESPACE" &>/dev/null; then
        echo "📦 Creating namespace: $NAMESPACE"
        oc create namespace "$NAMESPACE"
    else
        echo "✅ Namespace $NAMESPACE already exists"
    fi
}

# Function to apply manifests
apply_manifests() {
    local dir=$1
    local description=$2
    
    if [ -d "$SCRIPT_DIR/$dir" ]; then
        echo "📋 Applying $description..."
        oc apply -f "$SCRIPT_DIR/$dir/" -n "$NAMESPACE"
        echo "✅ $description applied successfully"
    else
        echo "⚠️  Directory $dir not found, skipping $description"
    fi
}

# Function to apply single manifest
apply_manifest() {
    local file=$1
    local description=$2
    
    if [ -f "$SCRIPT_DIR/$file" ]; then
        echo "📋 Applying $description..."
        oc apply -f "$SCRIPT_DIR/$file"
        echo "✅ $description applied successfully"
    else
        echo "⚠️  File $file not found, skipping $description"
    fi
}

# Main setup process
main() {
    echo "🔍 Checking prerequisites..."
    
    # Check if oc is available
    if ! command -v oc &> /dev/null; then
        echo "❌ OpenShift CLI (oc) is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we're logged in to OpenShift
    if ! oc whoami &>/dev/null; then
        echo "❌ Not logged in to OpenShift. Please run 'oc login' first"
        exit 1
    fi
    
    echo "✅ Prerequisites check passed"
    
    # Create namespace
    check_namespace
    
    # Apply RBAC first
    apply_manifests "rbac" "RBAC configuration"
    
    # Apply workspaces
    apply_manifests "workspaces" "Pipeline workspaces"
    
    # Apply tasks
    apply_manifests "tasks" "Tekton tasks"
    
    # Apply main pipeline
    apply_manifest "tekton-pipeline.yaml" "Main pipeline"
    
    echo ""
    echo "🎉 Setup completed successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Configure git credentials:"
    echo "   - Edit config/git-credentials-template.yaml with your actual credentials"
    echo "   - Apply it: oc apply -f config/git-credentials-template.yaml"
    echo ""
    echo "2. Update storage class in workspaces/pipeline-workspaces.yaml if needed"
    echo ""
    echo "3. Run a test pipeline:"
    echo "   - Edit runs/sample-pipelinerun.yaml with your parameters"
    echo "   - Apply it: oc apply -f runs/sample-pipelinerun.yaml"
    echo ""
    echo "4. Monitor pipeline execution:"
    echo "   - oc get pipelinerun -n $NAMESPACE"
    echo "   - oc logs -f pipelinerun/create-namespace-run-<namespace-name> -n $NAMESPACE"
    echo ""
    echo "📂 Available resources:"
    echo "   - Pipeline: create-namespace"
    echo "   - Tasks: clone-manifest-repo, namespace-manifest-create, default-quotas-manifest-create, default-network-policies-manifest-create, default-rolebindings-manifest-create, push-to-manifest-repo"
    echo "   - ServiceAccount: pipeline-service-account"
    echo ""
}

# Run main function
main "$@"
