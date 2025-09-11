
# **Part 1: Building the Todo API with Node.js & MongoDB**

## **1.1. Initialize Your Project**

Create a directory, e.g., `todo-api/`, and initialize:

```bash
mkdir todo-api
cd todo-api
npm init -y
```

## **1.2. Install Dependencies**

```bash
npm install express mongoose nodemon
```

For development, add a script for `nodemon` in `package.json`:

```json
"scripts": {
  "start": "node app.js",
  "dev": "nodemon app.js"
}
```

## **1.3. Create `app.js`**

Here's a simple Express API connected to MongoDB:

```js
const express = require('express');
const mongoose = require('mongoose');

require('dotenv').config();

const app = express();
app.use(express.json());

const port = 3000;

// MongoDB connection
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});
const db = mongoose.connection;
db.on('error', console.error.bind(console, 'MongoDB connection error:'));

// Todo schema
const todoSchema = new mongoose.Schema({
  title: String,
  completed: Boolean,
});
const Todo = mongoose.model('Todo', todoSchema);

// Routes

// GET /todos
app.get('/todos', async (req, res) => {
  const todos = await Todo.find();
  res.json(todos);
});

// POST /todos
app.post('/todos', async (req, res) => {
  const newTodo = new Todo(req.body);
  await newTodo.save();
  res.status(201).json(newTodo);
});

// GET /todos/:id
app.get('/todos/:id', async (req, res) => {
  const todo = await Todo.findById(req.params.id);
  if (!todo) return res.status(404).json({ error: 'Not found' });
  res.json(todo);
});

// PUT /todos/:id
app.put('/todos/:id', async (req, res) => {
  const updatedTodo = await Todo.findByIdAndUpdate(req.params.id, req.body, { new: true });
  if (!updatedTodo) return res.status(404).json({ error: 'Not found' });
  res.json(updatedTodo);
});

// DELETE /todos/:id
app.delete('/todos/:id', async (req, res) => {
  const deleted = await Todo.findByIdAndDelete(req.params.id);
  if (!deleted) return res.status(404).json({ error: 'Not found' });
  res.json({ message: 'Deleted' });
});

app.listen(port, () => {
  console.log(`API listening on port ${port}`);
});
```

## **1.4. Create `.env`**

```plaintext
MONGO_URI=mongodb://mongo:27017/todoapp
```

---

# **Part 2: Dockerize the Application**

## **2.1. Create `Dockerfile`**

```dockerfile
FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .

EXPOSE 3000

CMD ["node", "app.js"]
```

## **2.2. Create `docker-compose.yml`**

```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      MONGO_URI: mongodb://mongo:27017/todoapp
    depends_on:
      - mongo

  mongo:
    image: mongo:4.4
    volumes:
      - mongo-data:/data/db
    ports:
      - "27017:27017"

volumes:
  mongo-data:
```

### **2.3. Run Locally**

```bash
docker-compose up --build
```

Visit `http://localhost:3000`.

---

# **Part 3: Setup Remote Server with Terraform & Ansible**

### **3.1. Use Terraform to Create the Server**

Create a Terraform script (example for AWS):

```hcl
# main.tf
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "docker_server" {
  ami           = "ami-0c94855ba95c71c99" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name      = "your-ssh-key"

  tags = {
    Name = "docker-server"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "sudo chkconfig docker on",
      "sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
    ]
  }
}
```

Run:

```bash
terraform init
terraform apply
```

Use your key to SSH into the server.

### **3.2. Use Ansible to Configure**

Create an Ansible playbook (`setup.yml`) to deploy your app:

```yaml
- hosts: your_server_ip
  become: yes
  vars:
    repo_url: 'git@github.com:yourusername/todo-api.git'
  tasks:
    - name: Install Docker
      yum:
        name: docker
        state: present
    - name: Start Docker service
      service:
        name: docker
        state: started
        enabled: yes
    - name: Install Git
      yum:
        name: git
        state: present
    - name: Clone repo
      git:
        repo: '{{ repo_url }}'
        dest: /opt/todo-api
        version: main
    - name: Build and run containers
      shell: |
        cd /opt/todo-api
        docker-compose down
        docker-compose up -d --build
```

Run:

```bash
ansible-playbook -i hosts setup.yml
```

---

# **Part 4: CI/CD with GitHub Actions**

### **4.1. Setup Workflow**

Create `.github/workflows/deploy.yml`:

```yaml
name: CI/CD for Todo API

on:
  push:
    branches:
      - main

env:
  IMAGE_NAME: yourdockerhubusername/todo-api

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Log in to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build Docker image
        run: |
          docker build -t ${{ env.IMAGE_NAME }} .

      - name: Push Docker image
        run: |
          docker push ${{ env.IMAGE_NAME }}

      - name: SSH and Deploy
        uses: appleboy/ssh-action@v0.1.8
        with:
          host: ${{ secrets.REMOTE_HOST }}
          username: ${{ secrets.REMOTE_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            docker pull ${{ env.IMAGE_NAME }}
            docker-compose -f /path/to/your/docker-compose.yml down
            docker-compose -f /path/to/your/docker-compose.yml up -d --build
```

### **4.2. Secrets**

Set secrets in GitHub:

- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`
- `REMOTE_HOST`
- `REMOTE_USER`
- `SSH_PRIVATE_KEY`

### **4.3. Bonus: Setup Nginx Reverse Proxy**

Create a separate container with Nginx as reverse proxy, routing `http://your_domain.com` to your app.

**Sample `docker-compose.override.yml`:**

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - api
```

**Sample `nginx.conf`:**

```nginx
server {
    listen 80;
    server_name your_domain.com;

    location / {
        proxy_pass http://api:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

# **Final Notes**

- Push your code to GitHub.
- Adjust Terraform and Ansible scripts for your environment.
- Automate deployment with GitHub Actions.
- Configure your DNS and SSL as needed.

---
