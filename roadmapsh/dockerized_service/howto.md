
# **Part 1 — Creating a Node.js Service**

### **1.1. Initialize your project**

Create a folder, e.g., `node-service/`, and initialize a Node.js project:

```bash
mkdir node-service
cd node-service
npm init -y
```

### **1.2. Install dependencies**

We'll use `express` for the server and `dotenv` for environment variables:

```bash
npm install express dotenv basic-auth
```

### **1.3. Create `.env` file**

Create a `.env` file (make sure to add it to `.gitignore`):

```plaintext
SECRET_MESSAGE=This is a secret message!
USERNAME=admin
PASSWORD=pass123
```

### **1.4. Create `app.js`**

Here's the code with `/` and `/secret` routes, including Basic Auth:

```js
require('dotenv').config();
const express = require('express');
const basicAuth = require('basic-auth');

const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Hello, world!');
});

app.get('/secret', (req, res) => {
  const user = basicAuth(req);
  const { USERNAME, PASSWORD, SECRET_MESSAGE } = process.env;

  if (!user || user.name !== USERNAME || user.pass !== PASSWORD) {
    res.set('WWW-Authenticate', 'Basic realm="Restricted Area"');
    return res.status(401).send('Access denied');
  }

  res.send(SECRET_MESSAGE);
});

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
```

### **1.5. Run locally**

```bash
node app.js
```

Test:

- Visit `http://localhost:3000/` → "Hello, world!"
- Visit `http://localhost:3000/secret` → prompts for username/password

---

# **Part 2 — Dockerizing the Node.js Service**

### **2.1. Create Dockerfile**

In the same folder:

```dockerfile
FROM node:14-alpine

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy app source code
COPY . .

# Expose port
EXPOSE 3000

# Start the app
CMD ["node", "app.js"]
```

### **2.2. Use Docker Ignore**

Create `.dockerignore`:

```
node_modules
.env
Dockerfile
.git
```

**Important:** Do **not** include `.env` in the image for security reasons.

### **2.3. Build and run locally**

```bash
docker build -t my-node-service .
docker run -d -p 3000:3000 --name node-service my-node-service
```

Test:

- Visit `http://localhost:3000/` and `/secret` (using Basic Auth)

---

# **Part 3 — Setup a Remote Linux Server**

You can set up a server on DigitalOcean, AWS, or any provider:

- Create a droplet/instance
- SSH into it
- Install Docker:

```bash
sudo apt update
sudo apt install docker.io
sudo systemctl enable --now docker
```

- Configure firewall rules to allow port 3000 or 80 (for production)

---

# **Part 4 — CI/CD: Build, Push, Deploy with GitHub Actions**

### **4.1. Use a Container Registry**

You can use Docker Hub or GitHub Container Registry:

- **Docker Hub**: Create an account, create a repository, get your credentials.
- **GHCR**: Use GitHub Container Registry (more integrated with secrets in GitHub).

### **4.2. Sample GitHub Actions Workflow**

Create a `.github/workflows/deploy.yml`:

```yaml
name: Build and Deploy Node Service

on:
  push:
    branches:
      - main

env:
  IMAGE_NAME: ghcr.io/yourusername/node-service

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      # Alternatively, for Docker Hub:
      # - name: Log in to Docker Hub
      #   uses: docker/login-action@v2
      #   with:
      #     username: ${{ secrets.DOCKER_USERNAME }}
      #     password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build Docker image
        run: |
          docker build -t ${{ env.IMAGE_NAME }} .

      - name: Push Docker image
        run: |
          docker push ${{ env.IMAGE_NAME }}

      - name: Deploy to remote server
        uses: appleboy/ssh-action@v0.1.8
        with:
          host: ${{ secrets.REMOTE_HOST }}
          username: ${{ secrets.REMOTE_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            docker pull ${{ env.IMAGE_NAME }}
            docker stop node-service || true
            docker rm node-service || true
            docker run -d --name node-service -p 80:3000 ${{ env.IMAGE_NAME }}
```

### **4.3. Secrets Management**

In your GitHub repo:

- **Secrets needed:**

  - `GITHUB_TOKEN` (auto provided)
  - `SSH_PRIVATE_KEY` (your private SSH key with access to server)
  - `REMOTE_HOST` (your server's IP)
  - `REMOTE_USER` (your SSH username)
- **Note:** Store your Docker registry credentials securely if using Docker Hub.

---

# **Additional Tips**

- **Environment variables in Docker**: To pass environment variables like `SECRET_MESSAGE`, `USERNAME`, `PASSWORD`, you'd need to set them at runtime with `docker run -e` or via a Docker Compose file. For simplicity, you can bake them into the image during build or set them on deployment.
- **Security**:

  - Keep secrets out of your code.
  - Use secrets management provided by GitHub.
  - Avoid including `.env` in the Docker image; pass secrets as environment variables at runtime.

---

# **Summary**

- **Part 1**: Build a simple Node.js server with protected route and environment variables.
- **Part 2**: Dockerize the server, exclude `.env`.
- **Part 3**: Set up remote Linux server with Docker.
- **Part 4**: Use GitHub Actions to build, push, and deploy the Docker container, managing secrets securely.
