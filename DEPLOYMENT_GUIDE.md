# OpenShift Pipelines - Deployment and Usage Guide

This guide provides step-by-step instructions to deploy and use the OpenShift Pipelines namespace creation system.

## 📋 Prerequisites

### 1. OpenShift Cluster Requirements
- OpenShift 4.8+ cluster with admin access
- OpenShift Pipelines Operator installed
- Storage class available for persistent volumes

### 2. Local Tools Required
- `oc` CLI tool installed and configured
- `git` CLI tool
- Access to your OpenShift cluster

### 3. GitHub Repository Access
- Access to push to `https://github.com/lostspy009/openshift-pipelines.git`
- GitHub Personal Access Token (for authentication)

## 🚀 Step 1: Verify Prerequisites

### Check OpenShift Connection
```bash
# Login to your OpenShift cluster
oc login --server=https://your-cluster-api-url:6443 --username=your-username

# Verify you're connected
oc whoami
oc cluster-info
```

### Check OpenShift Pipelines Operator
```bash
# Check if Tekton/OpenShift Pipelines is installed
oc get pods -n openshift-pipelines

# If not installed, install the operator through the OperatorHub:
# 1. Go to OperatorHub in OpenShift Console
# 2. Search for "Red Hat OpenShift Pipelines"
# 3. Install the operator
```

### Check Available Storage Classes
```bash
# List available storage classes
oc get storageclass

# Note the default storage class for later use
oc get storageclass | grep "(default)"
```

## 🔧 Step 2: Clone and Prepare Repository

### Clone the Repository
```bash
# Clone your repository
git clone https://github.com/lostspy009/openshift-pipelines.git
cd openshift-pipelines

# Make the deployment script executable
chmod +x deploy.sh
```

### Update Storage Class (if needed)
```bash
# If your cluster uses a different storage class, update it
# Edit the storage class in workspaces/pipeline-workspaces.yaml
oc get storageclass
vi workspaces/pipeline-workspaces.yaml

# Change 'gp3-csi' to your cluster's storage class name
```

## 🔐 Step 3: Configure Git Authentication

### Create GitHub Personal Access Token
1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Click "Generate new token (classic)"
3. Select scopes: `repo` (full repository access)
4. Copy the generated token

### Configure Git Credentials Secret
```bash
# Copy the template
cp config/git-credentials-template.yaml config/git-credentials.yaml

# Edit with your GitHub credentials
vi config/git-credentials.yaml
```

Update the secret with your information:
```yaml
stringData:
  username: your-github-username
  password: ghp_your_personal_access_token  # Your GitHub token
```

## 🚀 Step 4: Deploy Pipeline Components

### Run the Automated Deployment
```bash
# Run the deployment script
./deploy.sh
```

### Manual Deployment (Alternative)
If the script fails, deploy manually:

```bash
# Create namespace
oc create namespace openshift-pipelines

# Deploy RBAC
oc apply -f rbac/pipeline-rbac.yaml

# Deploy workspaces
oc apply -f workspaces/pipeline-workspaces.yaml

# Deploy tasks
oc apply -f tasks/

# Deploy main pipeline
oc apply -f tekton-pipeline.yaml

# Deploy git credentials
oc apply -f config/git-credentials.yaml
```

### Verify Deployment
```bash
# Check if all components are deployed
oc get pipeline -n openshift-pipelines
oc get task -n openshift-pipelines
oc get serviceaccount pipeline-service-account -n openshift-pipelines
oc get pvc -n openshift-pipelines
oc get secret git-credentials -n openshift-pipelines
```

## 🎯 Step 5: Run Your First Pipeline

### Customize the PipelineRun
```bash
# Copy the sample
cp runs/sample-pipelinerun.yaml runs/my-first-namespace.yaml

# Edit with your parameters
vi runs/my-first-namespace.yaml
```

Update the parameters:
```yaml
params:
  - name: REQUESTER_ID
    value: john.doe  # Your username
  - name: NAMESPACE_NAME
    value: my-test-namespace  # Desired namespace name
  - name: CLUSTER_ENV
    value: dev  # Environment (dev/test/prod)
  - name: CLUSTER
    value: my-cluster  # Your cluster name
  - name: REQUESTS_CPU
    value: "2"  # CPU requests
  - name: LIMITS_CPU
    value: "4"  # CPU limits
  - name: MAX_PODS
    value: "10"  # Max pods
  - name: REQUESTS_MEMORY
    value: 1Gi  # Memory requests
  - name: LIMITS_MEMORY
    value: 2Gi  # Memory limits
  - name: LABELS
    value: '{"environment": "development", "team": "platform"}'  # Additional labels
```

### Execute the Pipeline
```bash
# Apply the PipelineRun
oc apply -f runs/my-first-namespace.yaml

# Watch the execution
oc get pipelinerun -n openshift-pipelines -w
```

## 📊 Step 6: Monitor Pipeline Execution

### Check Pipeline Status
```bash
# List all pipeline runs
oc get pipelinerun -n openshift-pipelines

# Get detailed status
oc describe pipelinerun create-namespace-run-my-test-namespace -n openshift-pipelines

# View real-time logs
oc logs -f pipelinerun/create-namespace-run-my-test-namespace -n openshift-pipelines
```

### Check Individual Tasks
```bash
# List task runs
oc get taskrun -n openshift-pipelines

# View specific task logs
oc logs -f taskrun/create-namespace-run-my-test-namespace-clone-manifest-repo -n openshift-pipelines
```

### Monitor Through OpenShift Console
1. Navigate to **Pipelines** → **Pipelines** in the OpenShift Console
2. Select `openshift-pipelines` namespace
3. Click on the `create-namespace` pipeline
4. View the pipeline runs and their status

## ✅ Step 7: Verify Results

### Check Created Namespace
```bash
# Verify the namespace was created
oc get namespace my-test-namespace

# Check namespace labels and annotations
oc describe namespace my-test-namespace
```

### Check Resource Quotas
```bash
# Verify resource quota
oc get resourcequota -n my-test-namespace
oc describe resourcequota compute-resources -n my-test-namespace

# Check limit ranges
oc get limitrange -n my-test-namespace
oc describe limitrange resource-limits -n my-test-namespace
```

### Check Network Policies
```bash
# Verify network policies
oc get networkpolicy -n my-test-namespace
oc describe networkpolicy deny-all-ingress -n my-test-namespace
```

### Check RBAC
```bash
# Verify role bindings
oc get rolebinding -n my-test-namespace
oc describe rolebinding john.doe-admin -n my-test-namespace

# Check service accounts
oc get serviceaccount -n my-test-namespace
```

### Check Git Repository
1. Go to your GitHub repository
2. Check if a new branch was created with your namespace manifests
3. Verify the manifests in `clusters/{CLUSTER_ENV}/{CLUSTER}/my-test-namespace/`

## 🔄 Step 8: Creating Additional Namespaces

### Using the Same Pipeline
```bash
# Create another PipelineRun for a different namespace
cp runs/my-first-namespace.yaml runs/another-namespace.yaml

# Edit the new file with different parameters
vi runs/another-namespace.yaml

# Change the namespace name and metadata
# Update the pipelinerun name to avoid conflicts

# Apply the new PipelineRun
oc apply -f runs/another-namespace.yaml
```

### Parameterized Execution
You can also run the pipeline with different parameters using `oc`:

```bash
# Create a PipelineRun with custom parameters
oc create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  name: create-namespace-run-$(date +%s)
  namespace: openshift-pipelines
spec:
  pipelineRef:
    name: create-namespace
  serviceAccountName: pipeline-service-account
  params:
    - name: REQUESTER_ID
      value: "jane.smith"
    - name: NAMESPACE_NAME
      value: "production-app"
    - name: CLUSTER_ENV
      value: "prod"
    - name: CLUSTER
      value: "prod-cluster-01"
    - name: REQUESTS_CPU
      value: "4"
    - name: LIMITS_CPU
      value: "8"
    - name: MAX_PODS
      value: "50"
    - name: REQUESTS_MEMORY
      value: "4Gi"
    - name: LIMITS_MEMORY
      value: "8Gi"
    - name: ENABLE_BACKUP
      value: "enabled"
    - name: LABELS
      value: '{"environment": "production", "criticality": "high"}'
  workspaces:
    - name: source
      persistentVolumeClaim:
        claimName: pipeline-source-workspace
    - name: output
      persistentVolumeClaim:
        claimName: pipeline-output-workspace
EOF
```

## 🛠️ Troubleshooting

### Common Issues and Solutions

#### 1. Pipeline Fails with Permission Errors
```bash
# Check RBAC
oc get clusterrolebinding pipeline-cluster-role-binding
oc describe clusterrolebinding pipeline-cluster-role-binding

# Recreate RBAC if needed
oc delete -f rbac/pipeline-rbac.yaml
oc apply -f rbac/pipeline-rbac.yaml
```

#### 2. Git Authentication Failures
```bash
# Check git credentials secret
oc get secret git-credentials -n openshift-pipelines
oc describe secret git-credentials -n openshift-pipelines

# Update credentials if needed
oc delete secret git-credentials -n openshift-pipelines
oc apply -f config/git-credentials.yaml
```

#### 3. Storage/PVC Issues
```bash
# Check PVC status
oc get pvc -n openshift-pipelines
oc describe pvc pipeline-source-workspace -n openshift-pipelines

# Check storage class
oc get storageclass
```

#### 4. Task Execution Failures
```bash
# Check task logs for specific errors
oc get taskrun -n openshift-pipelines
oc logs taskrun/<taskrun-name> -n openshift-pipelines

# Check if images are accessible
oc get events -n openshift-pipelines --sort-by='.lastTimestamp'
```

### Getting Detailed Information
```bash
# View all pipeline-related resources
oc get all -l app.kubernetes.io/name=openshift-pipelines -n openshift-pipelines

# Check events for troubleshooting
oc get events -n openshift-pipelines --sort-by='.lastTimestamp' | head -20

# Describe pipeline for configuration details
oc describe pipeline create-namespace -n openshift-pipelines
```

## 🔧 Advanced Usage

### Using with CI/CD Systems
You can integrate this with your CI/CD pipeline by creating PipelineRuns programmatically:

```bash
# Example: Jenkins pipeline step
curl -X POST \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H "Content-Type: application/yaml" \
  -d @runs/my-namespace.yaml \
  https://your-openshift-api/apis/tekton.dev/v1/namespaces/openshift-pipelines/pipelineruns
```

### Customizing for Your Organization
1. **Update Labels**: Modify task templates to include your organization's required labels
2. **Add Compliance Checks**: Insert additional tasks for security scanning or compliance validation
3. **Integrate with External Systems**: Add tasks for ITSM ticket creation or notifications
4. **Custom Network Policies**: Modify network policies to match your security requirements

## 📚 Next Steps

1. **Set up Monitoring**: Configure monitoring and alerting for pipeline executions
2. **Create Templates**: Build reusable templates for different types of namespaces
3. **Automate Further**: Integrate with GitOps workflows for continuous deployment
4. **Scale**: Consider using Tekton Triggers for event-driven pipeline execution

## 🎉 Success!

You now have a fully functional OpenShift Pipelines setup for automated namespace creation! The pipeline will:
- ✅ Create namespaces with proper metadata
- ✅ Apply resource quotas and limits
- ✅ Set up secure network policies
- ✅ Configure RBAC and service accounts
- ✅ Commit all manifests to your Git repository

Happy pipelining! 🚀
