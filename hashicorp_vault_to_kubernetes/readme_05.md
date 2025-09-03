Deploy applications that dynamically fetch secrets from Vault using the Vault Agent Injector.

#### Commands to Run

```
kubectl create serviceaccount app-service-account
```

```
kubectl apply -f vault-app-deployment.yaml
```

```
kubectl get pods | grep vault-app
```

```
kubectl exec deployment/vault-app -- ls /vault/secrets/
```

```
kubectl exec deployment/vault-app -- head /vault/secrets/database-config
```

```
kubectl logs deployment/vault-app -c vault-agent
```

#### Code Example

```
# Enable and configure Vault Injector
helm upgrade vault hashicorp/vault \
  --namespace vault \
  --set "injector.enabled=true" \
  --set "server.dev.enabled=true" \
  --set "server.dev.devRootToken=myroot"

# Create service account for the application
kubectl create serviceaccount app-service-account

# Create sample application that uses Vault secrets
cat > vault-app-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vault-app
  labels:
    app: vault-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vault-app
  template:
    metadata:
      labels:
        app: vault-app
      annotations:
        vault.hashicorp.com/agent-inject: 'true'
        vault.hashicorp.com/role: 'app-role'
        vault.hashicorp.com/agent-inject-secret-database-config: 'secret/data/app/database'
        vault.hashicorp.com/agent-inject-template-database-config: |
          {{- with secret "secret/data/app/database" -}}
          DATABASE_URL="postgresql://{{ .Data.data.username }}:{{ .Data.data.password }}@{{ .Data.data.host }}/{{ .Data.data.database }}"
          DATABASE_HOST="{{ .Data.data.host }}"
          DATABASE_USER="{{ .Data.data.username }}"
          DATABASE_PASSWORD="{{ .Data.data.password }}"
          DATABASE_NAME="{{ .Data.data.database }}"
          {{- end }}
        vault.hashicorp.com/agent-inject-secret-api-keys: 'secret/data/app/api-keys'
        vault.hashicorp.com/agent-inject-template-api-keys: |
          {{- with secret "secret/data/app/api-keys" -}}
          STRIPE_API_KEY="{{ .Data.data.stripe_key }}"
          SENDGRID_API_KEY="{{ .Data.data.sendgrid_key }}"
          JWT_SECRET="{{ .Data.data.jwt_secret }}"
          {{- end }}
    spec:
      serviceAccountName: app-service-account
      containers:
      - name: app
        image: nginx:alpine
        command: ['/bin/sh']
        args: ['-c', 'while true; do echo "App running with Vault secrets"; sleep 30; done']
        volumeMounts:
        - name: vault-secrets
          mountPath: /vault/secrets
          readOnly: true
      volumes:
      - name: vault-secrets
        emptyDir: {}
EOF

# Deploy the application
kubectl apply -f vault-app-deployment.yaml

# Wait for deployment
kubectl wait --for=condition=available deployment/vault-app --timeout=300s

# Check that Vault Agent injected secrets
kubectl exec deployment/vault-app -- ls -la /vault/secrets/
kubectl exec deployment/vault-app -- cat /vault/secrets/database-config
kubectl exec deployment/vault-app -- cat /vault/secrets/api-keys

# Create a more complex example with secret rotation
cat > vault-rotation-job.yaml <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: secret-rotation
spec:
  schedule: "0 2 * * 0"  # Weekly at 2 AM Sunday
  jobTemplate:
    spec:
      template:
        metadata:
          annotations:
            vault.hashicorp.com/agent-inject: 'true'
            vault.hashicorp.com/role: 'admin-role'
            vault.hashicorp.com/agent-inject-secret-rotate: 'secret/data/app/database'
            vault.hashicorp.com/agent-inject-template-rotate: |
              #!/bin/sh
              # Generate new password
              NEW_PASSWORD=$(openssl rand -base64 32)
              # Update Vault with new password
              vault kv put secret/app/database password="$NEW_PASSWORD"
              # Here you would also update the actual database user
              echo "Password rotated successfully"
        spec:
          serviceAccountName: vault-admin
          restartPolicy: OnFailure
          containers:
          - name: rotator
            image: vault:latest
            command: ['/bin/sh', '/vault/secrets/rotate']
EOF

kubectl apply -f vault-rotation-job.yaml
```
