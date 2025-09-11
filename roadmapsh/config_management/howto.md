
# 1. Directory Structure

Create the following directory structure:

```
ansible/
├── inventory.ini
├── setup.yml
└── roles/
    ├── base/
    │   ├── tasks/
    │   │   └── main.yml
    │   └── vars/
    │       └── main.yml
    ├── nginx/
    │   ├── tasks/
    │   │   └── main.yml
    ├── app/
    │   ├── tasks/
    │   │   └── main.yml
    │   ├── files/
    │   │   └── website.tar.gz
    └── ssh/
        ├── tasks/
        │   └── main.yml
        └── files/
            └── your_public_key.pub
```

---

# 2. Inventory File (`inventory.ini`)

```ini
[servers]
your_server_ip_or_hostname ansible_user=your_username
```

*(Replace `your_server_ip_or_hostname` and `your_username` accordingly.)*

---

# 3. The Main Playbook (`setup.yml`)

```yaml
---
- hosts: servers
  become: yes
  vars:
    # Add any global variables here
  roles:
    - base
    - nginx
    - app
    - ssh
```

To run specific roles:

```bash
ansible-playbook setup.yml --tags "nginx"
```

---

# 4. Roles Implementation

### a) `roles/base/tasks/main.yml`

```yaml
---
- name: Update apt cache and upgrade packages
  apt:
    update_cache: yes
    upgrade: dist
  tags: base

- name: Install common utilities
  apt:
    name:
      - curl
      - wget
      - vim
      - git
      - fail2ban
    state: present
  tags: base

- name: Enable and start fail2ban
  service:
    name: fail2ban
    state: started
    enabled: yes
  tags: base
```

### b) `roles/nginx/tasks/main.yml`

```yaml
---
- name: Install nginx
  apt:
    name: nginx
    state: present
  tags: nginx

- name: Ensure nginx is running
  service:
    name: nginx
    state: started
    enabled: yes
  tags: nginx

- name: Deploy nginx configuration (if needed)
  # Add any custom nginx config here
  # For now, just ensure default is active
  # Uncomment and customize if needed
  # template:
  #   src: nginx.conf.j2
  #   dest: /etc/nginx/nginx.conf
  # notify: reload nginx
  # tags: nginx

# handlers:
#   - name: reload nginx
#     service:
#       name: nginx
#       state: reloaded
```

### c) `roles/app/tasks/main.yml`

```yaml
---
- name: Upload website tarball
  copy:
    src: website.tar.gz
    dest: /tmp/website.tar.gz
  tags: app

- name: Create website directory
  file:
    path: /var/www/html/mywebsite
    state: directory
    owner: www-data
    group: www-data
  tags: app

- name: Extract website files
  unarchive:
    src: /tmp/website.tar.gz
    dest: /var/www/html/mywebsite
    remote_src: yes
  tags: app

- name: Set permissions
  file:
    path: /var/www/html/mywebsite
    recurse: yes
    owner: www-data
    group: www-data
  tags: app
```

*(Ensure your `roles/app/files/website.tar.gz` exists, or update to pull from a URL if using the stretch goal.)*

### d) `roles/ssh/tasks/main.yml`

```yaml
---
- name: Add SSH public key for access
  authorized_key:
    user: your_username
    state: present
    key: "{{ lookup('file', 'files/your_public_key.pub') }}"
  tags: ssh
```

*(Replace `your_username` with your actual SSH username.)*

---

# 5. Stretch Goal: Pull Repository in `app` Role

Modify `roles/app/tasks/main.yml`:

```yaml
- name: Clone website repository from GitHub
  git:
    repo: 'https://github.com/yourusername/yourwebsite.git'
    dest: /var/www/html/mywebsite
    version: main
  tags: app

- name: Set permissions
  file:
    path: /var/www/html/mywebsite
    recurse: yes
    owner: www-data
    group: www-data
```

*(Ensure the server has git installed: add `- name: Install git` in `base` role if needed.)*

---

# Usage Commands

- Run all roles:

```bash
ansible-playbook setup.yml
```

- Run only specific role(s):

```bash
ansible-playbook setup.yml --tags "nginx"
ansible-playbook setup.yml --tags "app"
ansible-playbook setup.yml --tags "ssh"
```

---

# Final notes:

- Make sure your server SSH access and firewall rules permit connection.
- Adjust the variables, paths, and hostnames as needed.
- Test each role separately if needed for troubleshooting.

---
