
## **Overview of the Workflow**

1. **Provision server with Terraform**
2. **Configure server with Ansible (install Node.js, clone repo, run app)**
3. **Develop a simple Node.js app**
4. **Push code to GitHub**
5. **Automate deployment with GitHub Actions** (Option 1 or 2)

---

## **Step-by-step Guide**

### **Step 1: Provision a DigitalOcean Droplet with Terraform**

Use your existing Terraform scripts from previous projects, ensuring the droplet has SSH access configured.
**Output:** Server IP address for deployment.

---

### **Step 2: Write a simple Node.js app**

Create a repo with the following `app.js`:

```js
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Hello, world!');
});

const PORT = 80;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

Add `package.json`:

```json
{
  "name": "hello-world",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.17.1"
  }
}
```

Push your code to GitHub.

---

### **Step 3: Ansible Role for Application Deployment (`app` role)**

Create an Ansible role called `app`:

#### **tasks/main.yml**

```yaml
---
- name: Clone the repository
  git:
    repo: 'https://github.com/yourusername/your-nodejs-repo.git'
    dest: /opt/nodeapp
    version: main
  tags: app

- name: Install Node.js and npm
  apt:
    name:
      - nodejs
      - npm
    state: present
  tags: app

- name: Install app dependencies
  npm:
    path: /opt/nodeapp
    state: present
  tags: app

- name: Start the Node.js app
  shell: |
    cd /opt/nodeapp
    npm start &
  args:
    chdir: /opt/nodeapp
  tags: app

- name: Configure firewall to allow port 80
  ufw:
    rule: allow
    port: 80
    proto: tcp
  tags: app
```

*(Make sure the server has `ufw` enabled, or adjust accordingly.)*

---

### **Step 4: Run the playbook manually**

```bash
ansible-playbook node_service.yml --tags app
```

This should deploy and start the Node.js app accessible via the server's public IP on port 80.

---

### **Step 5: Automate deployment with GitHub Actions**

Create a GitHub Actions workflow `.github/workflows/deploy.yml`:

#### **Option 1: Run the playbook using SSH and Ansible**

```yaml
name: Deploy Node.js App

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v2

    - name: Set up SSH key
      uses: webfactory/ssh-agent@v0.5.3
      with:
        ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}

    - name: Install Ansible
      run: |
        sudo apt-get update
        sudo apt-get install -y ansible

    - name: Run deployment playbook
      run: |
        ansible-playbook -i <your_server_ip>, --private-key ~/.ssh/id_rsa --user root --tags app node_service.yml
```

*(Replace `<your_server_ip>` with your server's IP. Store your SSH private key in GitHub secrets as `SSH_PRIVATE_KEY`.)*

---

### **Option 2: Use SSH and rsync to deploy directly**

```yaml
name: Deploy Node.js App via SSH

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v2

    - name: Setup SSH
      uses: webfactory/ssh-agent@v0.5.3
      with:
        ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}

    - name: Rsync code to server
      run: |
        rsync -avz --delete ./ your_user@<your_server_ip>:/opt/nodeapp
        ssh your_user@<your_server_ip> 'cd /opt/nodeapp && npm install && pm2 restart all' # if using pm2
```

*(For production, consider using process managers like pm2 to manage Node.js processes.)*

---

## **Additional Tips**

- **Secrets Management:** Store SSH private key, server IP, and any API tokens as GitHub Secrets.
- **Port forwarding:** Ensure port 80 is open on your server's firewall.
- **Process Management:** Use `pm2` or similar to keep your Node.js app running and easily restart it.

---

## **Summary**

- Use Terraform to provision resources.
- Prepare a simple Node.js app and push to GitHub.
- Use Ansible to configure the server and deploy the app manually.
- Automate deployment via GitHub Actions with SSH or Ansible commands.

---
