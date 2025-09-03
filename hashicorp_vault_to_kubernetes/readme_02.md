#### Commands to Run

```
vault secrets enable -path=secret kv-v2
```

```
vault auth enable kubernetes
```

```
vault policy write app-policy -
```

```
vault kv put secret/app/database username=appuser password=supersecret123
```

```
vault kv get secret/app/database
```

```
vault auth list
```


---



# Enable KV v2 secrets engine

vault secrets enable -path=secret kv-v2

# Enable database secrets engine

vault secrets enable database

# Enable Kubernetes authentication

vault auth enable kubernetes

# Configure Kubernetes auth

vault write auth/kubernetes/config 
    token_reviewer_jwt="$(kubectl get secret vault-token -n vault -o jsonpath='{.data.token}' | base64 --decode)"
    kubernetes_host="https://kubernetes.default.svc:443"
    kubernetes_ca_cert="$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode)"

# Create policies for different roles

# Application policy

vault policy write app-policy - <<EOF
path "secret/data/app/*" {
  capabilities = ["read"]
}
path "database/creds/app-role" {
  capabilities = ["read"]
}
EOF

# Admin policy

vault policy write admin-policy - <<EOF
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "database/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

# Create Kubernetes roles

vault write auth/kubernetes/role/app-role 
    bound_service_account_names=app-service-account
    bound_service_account_namespaces=default
    policies=app-policy
    ttl=24h

vault write auth/kubernetes/role/admin-role 
    bound_service_account_names=vault-admin
    bound_service_account_namespaces=vault
    policies=admin-policy
    ttl=1h

# Store some initial secrets

vault kv put secret/app/database 
    username="appuser"
    password="supersecret123"
    host="postgres.example.com"
    database="myapp"

vault kv put secret/app/api-keys 
    stripe_key="sk_test_abc123"
    sendgrid_key="SG.xyz789"
    jwt_secret="my-jwt-secret-key"

# Verify secrets are stored

vault kv get secret/app/database
vault kv list secret/app/
