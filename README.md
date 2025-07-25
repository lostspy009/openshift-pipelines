# OpenShift Pipelines - Namespace Creation Pipeline

This repository contains a complete Tekton pipeline setup for automating namespace creation in OpenShift clusters with proper resource quotas, network policies, and RBAC configurations.

## 📁 Repository Structure

```
.
├── config/
│   └── git-credentials-template.yaml    # Git authentication template
├── rbac/
│   └── pipeline-rbac.yaml              # ServiceAccount and RBAC for pipeline
├── runs/
│   └── sample-pipelinerun.yaml         # Example PipelineRun
├── tasks/
│   ├── clone-manifest-repo-task.yaml   # Git repository cloning task
│   ├── namespace-manifest-create-task.yaml  # Namespace creation task
│   ├── default-quotas-manifest-create-task.yaml  # Resource quota task
│   ├── default-network-policies-manifest-create-task.yaml  # Network policies task
│   ├── default-rolebindings-manifest-create-task.yaml  # RBAC task
│   └── push-to-manifest-repo-task.yaml # Git push task
├── workspaces/
│   └── pipeline-workspaces.yaml        # Persistent volume claims for workspaces
├── deploy.sh                           # Automated deployment script
├── resource-quota.yaml                 # Example resource quota
├── tekton-pipeline.yaml                # Main Tekton pipeline
└── README.md                           # This file
```

## 🎯 Features

### Pipeline Capabilities
- **Automated Namespace Creation**: Creates namespaces with proper labels and annotations
- **Resource Management**: Applies resource quotas and limit ranges
- **Network Security**: Implements default network policies for security
- **RBAC Configuration**: Sets up proper role bindings and service accounts
- **Git Integration**: Commits and pushes manifests to git repository
- **Parameterized**: Fully configurable through pipeline parameters

### Generated Resources
For each namespace, the pipeline creates:
1. **Namespace** with proper metadata and labels
2. **ResourceQuota** for CPU, memory, and pod limits
3. **LimitRange** for default and maximum resource limits
4. **NetworkPolicies** for secure network access
5. **RoleBindings** for user and service account permissions
6. **ServiceAccounts** for application workloads

## 🚀 Quick Start

### Prerequisites
- OpenShift cluster with Tekton Pipelines operator installed
- `oc` CLI tool configured and authenticated
- Git repository access for manifest storage

### 1. Deploy Pipeline Components

```bash
# Clone or navigate to the repository
cd openshift-pipelines

# Run the deployment script
./deploy.sh
```

### 2. Configure Git Authentication

Edit the git credentials template:
```bash
cp config/git-credentials-template.yaml config/git-credentials.yaml
# Edit config/git-credentials.yaml with your actual credentials
oc apply -f config/git-credentials.yaml
```

### 3. Update Storage Configuration (if needed)

Check available storage classes and update if necessary:
```bash
oc get storageclass
# Edit workspaces/pipeline-workspaces.yaml if different storage class needed
```

### 4. Run the Pipeline

Edit the sample PipelineRun with your parameters:
```bash
cp runs/sample-pipelinerun.yaml runs/my-namespace-run.yaml
# Edit runs/my-namespace-run.yaml with your specific values
oc apply -f runs/my-namespace-run.yaml
```

## 📋 Pipeline Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `MANIFEST_GIT_REPO` | Git repository URL for manifests | `https://github.com/lostspy009/openshift-pipelines.git` | No |
| `MANIFEST_GIT_BRANCH` | Git branch for manifests | `main` | No |
| `REQUESTER_ID` | ID of the person requesting the namespace | - | Yes |
| `NAMESPACE_NAME` | Name of the namespace to create | - | Yes |
| `CLUSTER_ENV` | Cluster environment (dev/test/prod) | - | Yes |
| `CLUSTER` | Cluster name | - | Yes |
| `REQUESTS_CPU` | CPU resource requests | - | Yes |
| `LIMITS_CPU` | CPU resource limits | - | Yes |
| `MAX_PODS` | Maximum number of pods | - | Yes |
| `REQUESTS_MEMORY` | Memory resource requests | - | Yes |
| `LIMITS_MEMORY` | Memory resource limits | - | Yes |
| `ENABLE_BACKUP` | Enable Velero backups | `disabled` | No |
| `ISTIO_DISCOVERY` | Enable Istio service mesh | `disabled` | No |
| `ISTIO_REV` | Istio revision | `''` | No |
| `LABELS` | Additional namespace labels (JSON) | `{}` | No |
| `AUTO_MERGE_PR` | Automatically merge pull request | `false` | No |

## 🔧 Customization

### Adding Custom Tasks

1. Create a new task file in the `tasks/` directory
2. Add the task reference to `tekton-pipeline.yaml`
3. Update dependencies with `runAfter` if needed

### Modifying Templates

The task files contain the templates for generated manifests. Modify these to match your organization's standards:

- `tasks/namespace-manifest-create-task.yaml` - Namespace template
- `tasks/default-quotas-manifest-create-task.yaml` - Resource quota templates
- `tasks/default-network-policies-manifest-create-task.yaml` - Network policy templates
- `tasks/default-rolebindings-manifest-create-task.yaml` - RBAC templates

### Storage Classes

Update the storage class in `workspaces/pipeline-workspaces.yaml` to match your cluster's available storage classes:

```bash
oc get storageclass
```

## 📊 Monitoring

### Check Pipeline Status
```bash
# List all pipeline runs
oc get pipelinerun -n openshift-pipelines

# Get detailed status
oc describe pipelinerun <pipelinerun-name> -n openshift-pipelines

# View logs
oc logs -f pipelinerun/<pipelinerun-name> -n openshift-pipelines
```

### Check Task Status
```bash
# List task runs
oc get taskrun -n openshift-pipelines

# View specific task logs
oc logs -f taskrun/<taskrun-name> -n openshift-pipelines
```

## 🔐 Security Considerations

### RBAC
The pipeline requires cluster-level permissions to create namespaces and manage resources. The provided RBAC configuration follows the principle of least privilege.

### Git Credentials
- Store git credentials securely using Kubernetes secrets
- Use personal access tokens instead of passwords
- Consider using SSH keys for better security

### Network Policies
The generated network policies implement a "default deny" approach with explicit allow rules for:
- Same namespace communication
- OpenShift monitoring
- OpenShift ingress

## 🛠️ Troubleshooting

### Common Issues

1. **Pipeline Fails with Permission Errors**
   - Ensure RBAC is properly applied
   - Check if the service account has necessary permissions

2. **Git Authentication Failures**
   - Verify git credentials secret is correct
   - Ensure the secret is in the same namespace as the pipeline

3. **Storage Issues**
   - Check if the specified storage class exists
   - Verify PVCs are successfully bound

4. **Task Execution Failures**
   - Check individual task logs for specific errors
   - Verify all required parameters are provided

### Getting Help

```bash
# Check pipeline details
oc describe pipeline create-namespace -n openshift-pipelines

# Check task details
oc describe task <task-name> -n openshift-pipelines

# View events
oc get events -n openshift-pipelines --sort-by='.lastTimestamp'
```

## 📈 Extending the Pipeline

### Adding Approval Gates
Consider adding manual approval tasks for production deployments:

```yaml
- name: manual-approval
  taskRef:
    name: manual-approval-task
  runAfter:
    - namespace-manifest-create
```

### Integration with External Systems
- Add tasks for ITSM ticket creation
- Integrate with compliance scanning tools
- Add notification tasks (Slack, email, etc.)

### Multi-Cluster Support
The pipeline already supports multiple clusters through the `CLUSTER_ENV` and `CLUSTER` parameters. Extend this by:
- Adding cluster-specific configurations
- Implementing cluster selection logic
- Adding cluster health checks

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For issues and questions:
- Create an issue in this repository
- Contact the platform team
- Check the troubleshooting section above
