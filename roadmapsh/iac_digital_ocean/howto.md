
# Part 1: Set Up Terraform for DigitalOcean

## 1. Prerequisites

- **DigitalOcean API Token:** Generate from your DigitalOcean dashboard.
- **Terraform installed:** Download from [terraform.io](https://www.terraform.io/downloads.html).

## 2. Terraform Configuration Files

### a) Create a working directory:

```bash
mkdir digitalocean-terraform
cd digitalocean-terraform
```

### b) Provider configuration (`main.tf`)

```hcl
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = "<YOUR_DIGITALOCEAN_ACCESS_TOKEN>"
}
```

*(Replace `<YOUR_DIGITALOCEAN_ACCESS_TOKEN>` with your actual token or use environment variables for security.)*

### c) Define the Droplet (`droplet.tf`)

```hcl
resource "digitalocean_droplet" "web" {
  name   = "terraform-droplet"
  region = "nyc3"  # or your preferred region
  size   = "s-1vcpu-1gb"  # Basic size
  image  = "ubuntu-20-04-x64"  # Ubuntu image
  ssh_keys = [<SSH_KEY_ID>]  # Optional: specify your SSH key ID for access
}

output "droplet_ip" {
  value = digitalocean_droplet.web.ipv4_address
}
```

*(You can get your SSH key ID by importing your key or from your DigitalOcean dashboard.)*

### d) Initialize and apply

```bash
terraform init
terraform apply
```

- Confirm when prompted.
- After the apply, note the output IP address.

---

# Part 2: SSH into the Droplet

```bash
ssh root@<droplet_ip>
```

*(Use your private key if needed: `ssh -i /path/to/key root@<droplet_ip>`)*

---

# Part 3: Optional - Configure with Ansible (Stretch Goal)

### a) Prepare Ansible Playbook

Use the previous `setup.yml` or similar, with the inventory pointing to your new droplet IP.

### b) Inventory (`inventory.ini`)

```ini
[servers]
<droplet_ip> ansible_user=root
```

### c) Run Ansible Playbook

```bash
ansible-playbook -i inventory.ini setup.yml
```

*(Ensure SSH keys are configured for passwordless access, or specify `--ask-pass`.)*

---

# Additional Tips:

- Use environment variables for sensitive data like your API token:

```bash
export DIGITALOCEAN_TOKEN="your_token_here"
```

And modify `provider` block:

```hcl
token = var.do_token
```

with a variable declared:

```hcl
variable "do_token" {
  default = ""
}
```

and set via CLI or environment.

- You can also manage the SSH keys via Terraform by importing a key resource.

---

# Summary:

- Write Terraform scripts to create a DigitalOcean droplet.
- Retrieve and SSH into the droplet.
- Optionally, run an Ansible playbook to configure the server.

---

Would you like me to prepare the complete example Terraform files with placeholders filled, or help you with the Ansible configuration for the stretch goal?
