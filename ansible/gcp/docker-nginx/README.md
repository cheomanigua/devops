# GCE - Docker - nginx

This project will provision a GCE instance and install Docker. We will then create a nginx image and run a nginx container in port 80.

You must comply with two requirements prior to running this project:

1. To have a GCE service account to run Ansible playbooks for provisioning GCE instances. please refer to [https://github.com/cheomanigua/ansible/tree/main/gcp](https://github.com/cheomanigua/ansible/tree/main/gcp)

2. Install the python docker module and the Ansible Galaxy plugin:
```
sudo apt install python-docker
ansible-galaxy collection install community.general
```

### Usage

```
git clone https://github.com/cheomanigua/ansible.git
cd ansible/gcp/docker-nginx
ansible-playbook create-instance.yml -u [sa_<uniqueId>] 
```

After serveral minutes, a new GCE instance will be created with docker, nginx server and a website running. Check your new site by visiting http://IP.address.of.instance

