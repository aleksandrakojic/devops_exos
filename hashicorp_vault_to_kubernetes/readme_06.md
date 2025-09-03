##### Implement Security Best Practices and Auditing

Step 6

Mark Complete

Configure audit logging, secret rotation, and security policies for production-grade secret management.

#### Commands to Run

```
vault audit enable file file_path=/vault/logs/audit.log
```

```
vault secrets enable transit
```

```
vault write -f transit/keys/app-encryption
```

```
vault write transit/encrypt/app-encryption plaintext=$(base64 <<< 'test data')
```

```
kubectl apply -f security-monitoring.yaml
```

```
kubectl get cronjobs
```

#### Code Example

```
# Enable audit logging in Vault
vault audit enable file file_path=/vault/logs/audit.log

# Create transit encryption engine for application-level encryption
vault secrets enable transit
vault write -f transit/keys/app-encryption

# Create policy for transit encryption
vault policy write transit-policy - <<EOF
path "transit/encrypt/app-encryption" {
  capabilities = ["update"]
}
path "transit/decrypt/app-encryption" {
  capabilities = ["update"]
}
EOF

# Configure secret rotation for database credentials
vault secrets enable -path=database database

# Configure PostgreSQL database connection
vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    connection_url="postgresql://{{username}}:{{password}}@postgres:5432/myapp?sslmode=disable" \
    allowed_roles="app-role" \
    username="vault" \
    password="vaultpass"

# Create database role with rotation
vault write database/roles/app-role \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

# Create comprehensive security monitoring
cat > security-monitoring.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: vault-monitoring
data:
  check-vault-health.sh: |
    #!/bin/bash
    # Check Vault seal status
    if vault status | grep -q "Sealed.*false"; then
        echo "✓ Vault is unsealed"
    else
        echo "✗ Vault is sealed" >&2
        exit 1
    fi
  
    # Check audit log
    if [[ -f /vault/logs/audit.log ]]; then
        RECENT_EVENTS=$(tail -100 /vault/logs/audit.log | jq -r '.time' | wc -l)
        echo "✓ Audit log has $RECENT_EVENTS recent events"
    fi
  
    # Check for failed authentication attempts
    FAILED_AUTHS=$(tail -100 /vault/logs/audit.log | jq -r 'select(.type=="response" and .error != null) | .error' | wc -l)
    if [[ $FAILED_AUTHS -gt 10 ]]; then
        echo "⚠ Warning: $FAILED_AUTHS failed authentication attempts detected"
    fi
  
  rotate-secrets.sh: |
    #!/bin/bash
    echo "Starting secret rotation..."
  
    # Rotate database credentials
    vault read database/creds/app-role
  
    # Update application secrets
    NEW_JWT_SECRET=$(openssl rand -base64 64)
    vault kv put secret/app/api-keys \
        stripe_key="$(vault kv get -field=stripe_key secret/app/api-keys)" \
        sendgrid_key="$(vault kv get -field=sendgrid_key secret/app/api-keys)" \
        jwt_secret="$NEW_JWT_SECRET"
  
    echo "Secret rotation completed"
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: vault-health-check
spec:
  schedule: "*/5 * * * *"  # Every 5 minutes
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: vault-admin
          restartPolicy: OnFailure
          containers:
          - name: health-checker
            image: vault:latest
            env:
            - name: VAULT_ADDR
              value: "http://vault:8200"
            - name: VAULT_TOKEN
              valueFrom:
                secretKeyRef:
                  name: vault-token
                  key: token
            command: ["/bin/sh", "/scripts/check-vault-health.sh"]
            volumeMounts:
            - name: scripts
              mountPath: /scripts
          volumes:
          - name: scripts
            configMap:
              name: vault-monitoring
              defaultMode: 0755
EOF

kubectl apply -f security-monitoring.yaml

# Create alerting rules for Prometheus (if available)
cat > vault-alerts.yaml <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: vault-alerts
spec:
  groups:
  - name: vault.rules
    rules:
    - alert: VaultSealed
      expr: vault_core_unsealed == 0
      for: 0m
      labels:
        severity: critical
      annotations:
        summary: "Vault is sealed"
        description: "Vault instance {{ $labels.instance }} is sealed"
  
    - alert: VaultHighFailedLogins
      expr: increase(vault_audit_log_request_failure_total[5m]) > 10
      for: 2m
      labels:
        severity: warning
      annotations:
        summary: "High number of failed Vault login attempts"
        description: "More than 10 failed login attempts in the last 5 minutes"
EOF

# Test encryption/decryption
echo "Testing Vault transit encryption..."
vault write transit/encrypt/app-encryption plaintext=$(base64 <<< "sensitive data")
vault write transit/decrypt/app-encryption ciphertext="vault:v1:example-ciphertext"

# Show audit logs
echo "Recent audit events:"
vault audit list
kubectl exec -n vault vault-0 -- tail -5 /vault/logs/audit.log | jq .
```
