## Installation on Ubuntu

```
sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```
Installation [Official documentation](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-on-ubuntu)

### Errors that may occur when running a Playbook or ad-hoc command 

1. `FAILED! => {"msg": "Failed to set permissions on the temporary files Ansible needs to create when becoming an unprivileged user (rc: 1, err: chown: changing ownership of '/var/tmp/ansible-tmp-1603916306.07-23747-73946564034153/': Operation not permitted`

This error occurs when  becoming an unprivilegded user and trying to run docker command.

- Check POSIX acl at [Understanding privilege escalation: become](https://docs.ansible.com/ansible/latest/user_guide/become.html#risks-of-becoming-an-unprivileged-user)
- Check [ansible.posix.authorized_key](https://docs.ansible.com/ansible/latest/collections/ansible/posix/authorized_key_module.html) module.
- Check [ansible.posix.acl](https://docs.ansible.com/ansible/latest/collections/ansible/posix/acl_module.html#ansible-collections-ansible-posix-acl-module) module.

2. `FAILED! => {"changed": false, "msg": "Failed to lock apt for exclusive operation"}`

**Solution**: Be sure that `become: yes` is present in your Playbook
