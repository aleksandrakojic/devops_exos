Certainly! Here's a tutorial-style markdown document that outlines the steps to set up a custom domain for both GitHub Pages and a DigitalOcean droplet. Feel free to customize it with your actual domain name, provider details, and screenshots if needed.

---

# DNS Setup for Custom Domains

This tutorial explains how to configure DNS records to point a custom domain to **GitHub Pages** and a **DigitalOcean Droplet**.

---

## Part 1: Setting Up a Custom Domain for GitHub Pages

### Prerequisites:

- A GitHub Pages site (e.g., `https://<username>.github.io/<repo>/`)
- A registered custom domain (e.g., `mywebsite.com`)

### Steps:

1. **Access Your Domain Provider's DNS Settings**

   - Log in to your domain registrar (e.g., Cloudflare, Namecheap, GoDaddy).
2. **Create or Edit DNS Records**

   - **For Apex/Naked Domain (`mywebsite.com`):**

     - **Create an A record:**

       - Name: `@` or leave blank
       - Type: `A`
       - Value: `185.199.108.153`
       - TTL: Default or Automatic
     - **Repeat for other GitHub IPs for redundancy:**

       - `185.199.109.153`
       - `185.199.110.153`
       - `185.199.111.153`
   - **For Subdomain (`www.mywebsite.com`):**

     - **Create a CNAME record:**
       - Name: `www`
       - Type: `CNAME`
       - Value: `<username>.github.io` (your GitHub Pages URL)
       - TTL: Default or Automatic
3. **Configure GitHub Repository Custom Domain Settings**

   - Go to your GitHub repository.
   - Navigate to **Settings** → **Pages**.
   - Under **Custom domain**, enter `mywebsite.com`.
   - Save changes.
   - GitHub may automatically create HTTPS certificates via Let's Encrypt.
4. **Verify the Setup**

   - Wait for DNS propagation (can take a few minutes to hours).
   - Visit `http://mywebsite.com` and `https://mywebsite.com` to confirm.

---

## Part 2: Setting Up a Custom Domain for DigitalOcean Droplet

### Prerequisites:

- A running DigitalOcean droplet serving your static site
- Your droplet's public IP address (e.g., `203.0.113.10`)
- A registered domain name (e.g., `mydroplet.com`)

### Steps:

1. **Access Your Domain Provider's DNS Settings**
2. **Create DNS Records**

   - **A Record for Root Domain**

     - Name: `@`
     - Type: `A`
     - Value: `<Droplet IP Address>` (e.g., `203.0.113.10`)
     - TTL: Default or Automatic
   - **Optional: Subdomain (e.g., `www`)**

     - Name: `www`
     - Type: `CNAME`
     - Value: your domain (`mydroplet.com`)
     - TTL: Default or Automatic
3. **Configure Nginx or Web Server on the Droplet**

   - Ensure your web server (e.g., Nginx) is configured to serve your static site for the domain.
4. **Verify DNS Propagation**

   - Use tools like `dig` or online DNS checking tools to confirm records are propagated.
   - Visit `http://mydroplet.com` to verify your site loads.

---

## Additional Tips

- **SSL Certificates:** Use Let's Encrypt via Certbot to enable HTTPS for your custom domain.
- **DNS Propagation:** Changes can take anywhere from a few minutes up to 48 hours.

---

## Summary

| Domain Type          | DNS Records Needed                          | Target                                     | Notes                                 |
| -------------------- | ------------------------------------------- | ------------------------------------------ | ------------------------------------- |
| GitHub Pages         | A records for GitHub IPs, CNAME for `www` | GitHub Pages URL /`<username>.github.io` | Set in your DNS provider's dashboard  |
| DigitalOcean Droplet | A record for root, CNAME for subdomain      | Droplet IP address                         | Configure your web server accordingly |

---

**Remember:** Always double-check your DNS records and wait for propagation to complete before testing.

---

If you'd like, I can help you draft a customized version with your actual domain names and provider details!
