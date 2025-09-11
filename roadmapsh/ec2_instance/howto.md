
# AWS EC2 Static Website Deployment – Step-by-Step Guide

## 1. Create an AWS Account

- Visit [AWS](https://aws.amazon.com/) and sign up.
- Complete identity verification and billing setup (you can use the free tier).

## 2. Familiarize Yourself with AWS Console

- Log in at [AWS Management Console](https://console.aws.amazon.com/).
- Explore core services: EC2, VPC, Route 53, Certificate Manager.

---

## 3. Launch an EC2 Instance

### a. Choose AMI

- Search for **Ubuntu Server 20.04 LTS** (or latest) in the EC2 launch wizard.

### b. Instance Details

- Select **t2.micro** (eligible for free tier).
- Use default VPC/subnet.

### c. Configure Security Group

- Create or select a security group.
- Add inbound rules:
  - SSH (port 22) from your IP.
  - HTTP (port 80) from anywhere (or your IP for testing).

### d. Key Pair

- Create a new key pair, download the `.pem` file.
- Keep it safe — you'll need it for SSH.

### e. Launch

- Review and launch the instance.
- Wait for the status to be **running**.

---

## 4. Connect to Your EC2 Instance

```bash
ssh -i /path/to/your-key.pem ubuntu@<Public-IP>
```

- Replace `/path/to/your-key.pem` with your key path.
- Replace `<Public-IP>` with your instance’s public IP.

---

## 5. Set Up the Web Server

### a. Update packages

```bash
sudo apt update && sudo apt upgrade -y
```

### b. Install Nginx

```bash
sudo apt install nginx -y
```

### c. Start and enable Nginx

```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

### d. Verify

- Visit `http://<Public-IP>` in your browser.
- You should see the default Nginx page.

---

## 6. Deploy Your Static Website

### a. Create an HTML file

```bash
echo "<!DOCTYPE html>
<html>
<head>
<title>My Static Website</title>
</head>
<body>
<h1>Hello from AWS EC2!</h1>
<p>This is a static website hosted on EC2.</p>
</body>
</html>" > index.html
```

### b. Replace default Nginx page

```bash
sudo mv index.html /var/www/html/index.html
```

### c. Check your website in browser

- Refresh `http://<Public-IP>` to see your custom page.

---

## 7. (Optional) Set Up a Custom Domain with Route 53

- Register a domain or use an existing one.
- Create a hosted zone in Route 53.
- Add an A record pointing to your EC2 public IP.
- Update your domain’s nameservers to Route 53.

## 8. (Optional) Enable HTTPS with Let's Encrypt

- Install Certbot:

```bash
sudo apt install certbot python3-certbot-nginx -y
```

- Obtain and install the SSL:

```bash
sudo certbot --nginx -d yourdomain.com
```

- Follow prompts to secure your site.

## 9. (Optional) Automate Deployment with CI/CD

- Use AWS CodePipeline, CodeBuild, and CodeDeploy.
- Automate pushing changes from GitHub or other repositories directly to your EC2/web server.

---

# Summary of Commands

```bash
# Connect to EC2
ssh -i /path/to/key.pem ubuntu@<Public-IP>

# Update packages & install nginx
sudo apt update && sudo apt upgrade -y
sudo apt install nginx -y

# Start nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Deploy static site
echo "<html>...</html>" | sudo tee /var/www/html/index.html
```

---

# Final Tips

- Keep your private key secure.
- Use security groups wisely; only open necessary ports.
- Regularly update your server.
- For production, consider setting up a domain, SSL, and automated deployment pipelines.

---

Would you like me to prepare a sample script, detailed commands, or diagrams to illustrate the process further?
