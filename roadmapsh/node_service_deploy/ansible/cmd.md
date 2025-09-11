### **Run the playbook manually:**


```
ansible-playbook -i <server_ip>, --private-key ~/.ssh/id_rsa --become -u root node_service.yml --tags app
node_service.yml --tags app
```
