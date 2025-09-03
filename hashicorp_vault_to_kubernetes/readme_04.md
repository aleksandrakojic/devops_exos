Encrypt secret files using SOPS and demonstrate secure GitOps workflows with encrypted configurations.

#### Commands to Run

```
sops --encrypt --in-place secrets/app-config.dev.yaml
```

```
head -20 secrets/app-config.dev.yaml
```

```
sops --decrypt secrets/app-config.dev.yaml | head -10
```

```
./deploy-secrets.sh dev default
```

```
kubectl get secrets | grep app
```

```
sops --decrypt secrets/env-vars.dev.yaml
```

---


#### Code Example

```
# Encrypt the development secrets (using age)
sops --encrypt --in-place secrets/app-config.dev.yaml

# Encrypt the production secrets (using GPG)
sops --encrypt --in-place secrets/app-config.prod.yaml

# View encrypted file content
cat secrets/app-config.dev.yaml

# Decrypt and view (without modifying file)
sops --decrypt secrets/app-config.dev.yaml

# Edit encrypted file
sops secrets/app-config.dev.yaml

# Create encrypted environment file
cat > secrets/env-vars.dev.yaml <<EOF
database:
  host: db-dev.example.com
  port: 5432
  username: appuser
  password: dev-password-123
api:
  stripe_key: sk_test_dev_key_123
  sendgrid_key: SG.dev_key_456
  jwt_secret: dev-jwt-secret-789
redis:
  url: redis://redis-dev:6379/0
  password: dev-redis-pass
EOF

# Encrypt the environment file
sops --encrypt --in-place secrets/env-vars.dev.yaml

# Create a script to deploy encrypted secrets
cat > deploy-secrets.sh <<'EOF'
#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}
NAMESPACE=${2:-default}

echo "Deploying secrets for environment: $ENVIRONMENT"

# Decrypt and apply Kubernetes secrets
if [[ -f "secrets/app-config.$ENVIRONMENT.yaml" ]]; then
    echo "Applying app-config secret..."
    sops --decrypt secrets/app-config.$ENVIRONMENT.yaml | kubectl apply -n $NAMESPACE -f -
fi

# Convert environment variables to Kubernetes secret
if [[ -f "secrets/env-vars.$ENVIRONMENT.yaml" ]]; then
    echo "Creating environment variables secret..."
    sops --decrypt secrets/env-vars.$ENVIRONMENT.yaml | \
    yq eval '.database.password, .api.stripe_key, .api.sendgrid_key, .api.jwt_secret, .redis.password' | \
    kubectl create secret generic app-env-vars \
        --from-literal=DB_PASSWORD="$(sops --decrypt secrets/env-vars.$ENVIRONMENT.yaml | yq eval '.database.password' -)" \
        --from-literal=STRIPE_KEY="$(sops --decrypt secrets/env-vars.$ENVIRONMENT.yaml | yq eval '.api.stripe_key' -)" \
        --from-literal=JWT_SECRET="$(sops --decrypt secrets/env-vars.$ENVIRONMENT.yaml | yq eval '.api.jwt_secret' -)" \
        --namespace $NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
fi

echo "Secrets deployed successfully!"
EOF

chmod +x deploy-secrets.sh

# Test the deployment script
./deploy-secrets.sh dev default

# Verify secrets were created
kubectl get secrets
kubectl describe secret app-config
kubectl describe secret app-env-vars
```
