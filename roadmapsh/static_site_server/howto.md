Great! Here's a step-by-step guide to help you set up a static website served with Nginx on a remote Linux server and use `rsync` for deployment:

---

## 1. Set Up a Remote Linux Server

- **Choose a provider** (e.g., DigitalOcean, AWS, Linode, etc.).
- **Create a server instance** (Droplet, EC2 instance, etc.).
- **Note the server's IP address**.
- **Get SSH access**: Ensure you have the SSH key or password to connect.

---

## 2. Connect to the Server via SSH

```bash
ssh username@your_server_ip
```

Replace `username` with your server user (often `root` or your created user).

---

## 3. Install and Configure Nginx

**On the server:**

```bash
sudo apt update
sudo apt install nginx
```

**Configure Nginx to serve your site:**

- Create a new server block:

```bash
sudo nano /etc/nginx/sites-available/mywebsite
```

- Add the following configuration (adjust paths and domain as needed):

```nginx
server {
    listen 80;
    server_name your_domain.com;  # or use server_name _; for IP

    root /var/www/mywebsite;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

- Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/mywebsite /etc/nginx/sites-enabled/
```

- Test and reload Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 4. Prepare Your Static Site

- Create a simple webpage locally:

```html
<!-- index.html -->
<!DOCTYPE html>
<html>
<head>
    <title>My Static Site</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>Hello from my static site!</h1>
    <img src="image.jpg" alt="Sample Image" width="300"/>
</body>
</html>
```

- Add an image (`image.jpg`) to the same folder.

---

## 5. Deploy Your Site Using rsync

Create a script `deploy.sh`:

```bash
#!/bin/bash

# Define variables
LOCAL_DIR="path/to/your/site"
REMOTE_USER="your_username"
REMOTE_HOST="your_server_ip"
REMOTE_DIR="/var/www/mywebsite"

# Sync files to server
rsync -avz --delete "$LOCAL_DIR/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"
```

Make it executable:

```bash
chmod +x deploy.sh
```

Run the script whenever you want to deploy updates:

```bash
./deploy.sh
```

---

## 6. Point Your Domain (Optional)

- Register a domain name.
- In your DNS provider, set an A record pointing to your server's IP.
- Wait for DNS propagation.

Your site will be accessible via your domain once DNS is set up.

---

## 7. Final Checks

- Access your site via domain or IP.
- Make updates locally.
- Run `./deploy.sh` to sync changes.

---

## Summary of Concepts Learned:

- How to set up a Linux server with Nginx
- Configuring Nginx to serve static files
- Using `rsync` to deploy static sites efficiently
- Basic DNS setup for domain pointing

---

If you'd like, I can help you craft a complete example project with sample files and scripts!
