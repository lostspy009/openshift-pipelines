# PipelineRun Naming Guide

## ❌ **Common Error**
```yaml
metadata:
  name: create-namespace-run-$(params.NAMESPACE_NAME)  # INVALID - Cannot use parameters in metadata.name
```

## ✅ **Correct Approaches**

### Option 1: Static Names with Descriptive Suffixes
```yaml
metadata:
  name: create-namespace-run-my-app-dev
  # or
  name: create-namespace-run-$(date +%Y%m%d-%H%M%S)  # Use in shell, not YAML
```

### Option 2: Using generateName for Dynamic Names
```yaml
metadata:
  generateName: create-namespace-run-
  # Kubernetes will append random characters automatically
```

### Option 3: Timestamp-based Names (Recommended)
```bash
# Create unique names when applying
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
sed "s/create-namespace-run-sample/create-namespace-run-${TIMESTAMP}/" runs/sample-pipelinerun.yaml | oc apply -f -
```

## 🔧 **Quick Fix for Your File**

Your file has been fixed. You can now run:
```bash
oc apply -f runs/my-test.yaml
```

## 📝 **Best Practices**

1. **Use descriptive names**: Include environment, app name, or purpose
2. **Add timestamps**: For unique executions
3. **Use generateName**: For automatic unique naming
4. **Avoid parameters**: in metadata.name field

## 🚀 **Example Usage**

```bash
# Method 1: Direct apply (your file is now fixed)
oc apply -f runs/my-test.yaml

# Method 2: Create with generateName
cat > my-namespace-run.yaml << EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: create-namespace-run-
  namespace: openshift-pipelines
spec:
  # ... rest of your spec
EOF

# Method 3: Dynamic naming with timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
cp runs/sample-pipelinerun.yaml runs/run-${TIMESTAMP}.yaml
sed -i "s/create-namespace-run-sample/create-namespace-run-${TIMESTAMP}/" runs/run-${TIMESTAMP}.yaml
oc apply -f runs/run-${TIMESTAMP}.yaml
```
