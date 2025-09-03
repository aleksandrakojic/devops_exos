#### Commands to Run

```
helm repo add hashicorp https://helm.releases.hashicorp.com
```

```
kubectl create namespace vault
```

```
helm install vault hashicorp/vault --namespace vault --set server.dev.enabled=true
```

```
kubectl get pods -n vault
```

```
export VAULT_ADDR='http://127.0.0.1:8200' && export VAULT_TOKEN='myroot'
```

```
vault status
```

---




# Add HashiCorp Helm repository

helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Create namespace

kubectl create namespace vault

# Install Vault in dev mode (for learning)

helm install vault hashicorp/vault 
  --namespace vault 
  --set "server.dev.enabled=true" 
  --set "server.dev.devRootToken=myroot" 
  --set "injector.enabled=false"

# Wait for Vault to be ready

kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault --timeout=300s

# Port forward to access Vault UI

kubectl port-forward -n vault svc/vault 8200:8200 &

# Install Vault CLI

wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vault

# Configure Vault CLI

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='myroot'

# Verify Vault is working

vault status
vault auth list
