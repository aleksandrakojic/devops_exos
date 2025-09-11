Setting up a bastion host is a fundamental security practice for managing secure access to private infrastructure. I'll outline a comprehensive step-by-step guide, including configuration examples, best practices, and optional stretch goals like automation and security hardening. Additionally, I'll provide a sample `README.md` template for your submission.

---

# **Bastion Host Setup Guide**

## **Overview**

- **Objective:** Create a secure bastion host in a cloud environment to facilitate access to a private server.
- **Components:**
  - **Bastion Host:** Publicly accessible, acts as a gateway.
  - **Private Server:** Accessible only via bastion host.

---

## **Step 1: Choose a Cloud Provider**

You can use:

- **AWS EC2**
- **DigitalOcean Droplets**
- **GCP Compute Engine**
- **Azure VMs**

For this guide, I’ll use **AWS** as an example, but the process is similar across providers.

---

## **Step 2: Create the Servers**

### **A. Create the Bastion Host**

- Launch an EC2 instance (e.g., Amazon Linux 2, Ubuntu, etc.).
- Assign a **public IP**.
- Configure security group:
  - Allow inbound SSH (port 22) from your IP address (or a trusted range).
  - Block other inbound ports.
- Generate or upload a key pair (private key `.pem`) for SSH access.

### **B. Create the Private Server**

- Launch another EC2 instance.
- Assign it a **private IP** (keep it private, not publicly accessible).
- Configure security group:
  - Allow inbound SSH only from the bastion host's private IP (or security group).
  - Disallow SSH from anywhere else.
- Do **not** assign a public IP to this server.

---

## **Step 3: Configure SSH Access**

### **A. SSH into the Bastion Host**

```bash
ssh -i <path-to-bastion-key.pem> ec2-user@<bastion-public-ip>
```

### **B. Connect to the Private Server via Bastion**

From your local machine:

```bash
ssh -i <path-to-private-server-key.pem> -o ProxyJump=ec2-user@<bastion-public-ip> ec2-user@<private-server-private-ip>
```

Or, set up SSH config for convenience:

```bash
# ~/.ssh/config
Host bastion
    HostName <bastion-public-ip>
    User ec2-user
    IdentityFile ~/.ssh/bastion.pem

Host private-server
    HostName <private-server-private-ip>
    User ec2-user
    IdentityFile ~/.ssh/private-server.pem
    ProxyJump bastion
```

Then connect directly:

```bash
ssh private-server
```

---

## **Step 4: Harden Security**

### **A. Fail2Ban (optional but recommended)**

- Install Fail2Ban on both servers to protect against brute-force attacks:

```bash
sudo apt-get install fail2ban
# or for Amazon Linux:
sudo yum install fail2ban
```

- Configure Fail2Ban rules for SSH.

### **B. Use Strong SSH Keys & Disable Password Authentication**

- Generate SSH keys with strong passphrases.
- Configure `/etc/ssh/sshd_config`:

```bash
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
```

### **C. Enable MFA (Optional, for advanced security)**

- Set up MFA using tools like `Google Authenticator`.
- Integrate with SSH for multi-factor auth.

---

## **Step 5: Automate Deployment (Optional)**

Use **Terraform** or **Ansible** to script the infrastructure and configuration:

- **Terraform:** Define infrastructure as code, create servers, security groups, SSH keys.
- **Ansible:** Automate OS hardening, Fail2Ban, SSH config.

---

## **Step 6: Monitoring & Logging**

- Enable SSH access logs.
- Use `fail2ban` logs to monitor intrusion attempts.
- Optional: Integrate with monitoring tools (e.g., CloudWatch, Prometheus).

---

## **Sample `README.md` Template**

```markdown
# Bastion Host Setup for Secure Access to Private Infrastructure

## Overview

This project sets up a secure bastion host to facilitate SSH access to a private server. The bastion host acts as a gateway, reducing the attack surface by exposing only a single public endpoint.

## Infrastructure Components

- **Bastion Host**: Publicly accessible server with SSH enabled.
- **Private Server**: Internal server accessible only from the bastion host.

## Cloud Provider

- Provider: **AWS EC2**
- Region: **us-east-1** (or your region)

## Setup Steps

### 1. Create Servers

- Launch EC2 instances:
  - Bastion Host with a public IP.
  - Private Server without a public IP.

### 2. Configure Security Groups

- Bastion:
  - Allow inbound SSH from your IP.
- Private Server:
  - Allow inbound SSH only from Bastion’s private IP (or security group).

### 3. SSH Configuration

- Generate SSH key pairs for both servers.
- Add entries to your `~/.ssh/config`:

```plaintext
Host bastion
    HostName <bastion-public-ip>
    User ec2-user
    IdentityFile ~/.ssh/bastion.pem

Host private-server
    HostName <private-server-private-ip>
    User ec2-user
    IdentityFile ~/.ssh/private-server.pem
    ProxyJump bastion
```

- Connect:

```bash
ssh private-server
```

### 4. Security Hardening

- Disable password login.
- Install Fail2Ban.
- Use MFA for SSH (optional).

### 5. Automation (Optional)

- Use Terraform or Ansible scripts to deploy and configure instances automatically.

## Important Notes

- Never share private keys publicly.
- Use strong, unique SSH keys.
- Regularly update and patch your servers.
- Monitor SSH logs and intrusion attempts.

## Future Improvements

- Enable multi-factor authentication.
- Set up detailed monitoring and alerting.
- Automate deployment with Infrastructure as Code tools.

## References

- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [OpenSSH Configurations](https://man.openbsd.org/sshd_config)
- [Fail2Ban Documentation](https://fail2ban.readthedocs.io/)



# **Next Steps**
- Create the cloud infrastructure.
- Configure SSH keys and security groups.
- Set up SSH config on your local machine.
- Harden security practices.
- Optionally, automate with Terraform or Ansible.



Connect to EC2 using Bastion as Proxy:

```
ssh -i ~/.ssh/id_rsa -o ProxyJump=ec2-user@<bastion_public_ip> ec2-user@<private_ip>
```
