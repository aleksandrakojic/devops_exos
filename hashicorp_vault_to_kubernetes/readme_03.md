#### Commands to Run

```
sops --version
```

```
age-keygen -o key.txt
```

```
gpg --list-secret-keys
```

```
cat .sops.yaml
```

```
ls -la secrets/
```

---


#### Code Example

```
# Install SOPS
wget https://github.com/mozilla/sops/releases/download/v3.7.3/sops-v3.7.3.linux.amd64
sudo mv sops-v3.7.3.linux.amd64 /usr/local/bin/sops
sudo chmod +x /usr/local/bin/sops

# Install age (modern encryption tool)
wget https://github.com/FiloSottile/age/releases/download/v1.1.1/age-v1.1.1-linux-amd64.tar.gz
tar xzf age-v1.1.1-linux-amd64.tar.gz
sudo mv age/age /usr/local/bin/
sudo mv age/age-keygen /usr/local/bin/

# Generate age key pair
age-keygen -o key.txt
echo "Age public key: $(grep 'public key:' key.txt | cut -d' ' -f4)"

# Create GPG key for demo (alternative to age)
gpg --batch --full-generate-key <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: DevOps Demo
Name-Email: devops@example.com
Expire-Date: 1y
Passphrase: 
%commit
EOF

# Get GPG key fingerprint
GPG_KEY=$(gpg --list-secret-keys --keyid-format LONG | grep sec | cut -d'/' -f2 | cut -d' ' -f1)
echo "GPG Key ID: $GPG_KEY"

# Create SOPS configuration
cat > .sops.yaml <<EOF
creation_rules:
  - path_regex: \.dev\.yaml$
    age: age1example... # Replace with your age public key
    encrypted_regex: '^(data|stringData)$'
  - path_regex: \.prod\.yaml$
    pgp: '$GPG_KEY'
    encrypted_regex: '^(data|stringData|password|secret)$'
  - path_regex: secrets/.*\.yaml$
    age: age1example... # Replace with your age public key
    pgp: '$GPG_KEY'
EOF

# Create sample secret files
mkdir -p secrets

# Development secrets
cat > secrets/app-config.dev.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: app-config
  namespace: development
type: Opaque
data:
  database_url: cG9zdGdyZXM6Ly91c2VyOnBhc3NAZGItZGV2OjU0MzIvYXBwZGI=
  api_key: ZGV2LWFwaS1rZXktMTIz
  redis_url: cmVkaXM6Ly9yZWRpcy1kZXY6NjM3OS8w
EOF

# Production secrets
cat > secrets/app-config.prod.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: app-config
  namespace: production
type: Opaque
data:
  database_url: cG9zdGdyZXM6Ly91c2VyOnNlY3VyZXBhc3NAZGItcHJvZDo1NDMyL2FwcGRi
  api_key: cHJvZC1hcGkta2V5LXh5ejc4OQ==
  redis_url: cmVkaXM6Ly9yZWRpcy1wcm9kOjYzNzkvMA==
  stripe_webhook_secret: d2hzZWNfc3VwZXJzZWNyZXRrZXk=
EOF
```
