## Google Cloud Platform
Ansible contains modules for managing Google Cloud Platform resources, including creating instances, controlling network access, working with persistent disks, managing load balancers, and a lot more.

The Ansible GCP modules require both the `requests` and the `google-auth` libraries to be installed:

```
sudo apt install python3-pip
pip3 install requests google-auth
```


## Google Cloud Platform - GCE instance

In order to use **Ansible** for creating GCP resources and managing GCE instances, you will need to setup a **service account** with OS Login.

These are the steps:

1. Create a service account
2. Set up OS Login
3. (Conditional) Set user permission to `~/.ansible/cp/`
4. Using a service account

### 1. Create a Service Account

We are going to create a Service Account for provisioning and managing GCE instances via Ansible using specific roles for that purpose. It's important to make a distintion here regarding the type of authorization that is necessary for the next tasks:

- **Creating resources**: It is necessary the **service account** JSON key file.
- **Managing instances**: It is necessary the **service account**'s unique id adquired when OS Login is activated.

1. Create service account:
```
gcloud iam service-accounts create [NAME] \
     --display-name "Service account for Ansible"
```

2. Check the full account address created:
```
gcloud iam service-accounts list
```

3. Assign roles:
```
for role in \
  'roles/compute.instanceAdmin' \
  'roles/compute.instanceAdmin.v1' \
  'roles/compute.osAdminLogin' \
  'roles/iam.serviceAccountUser'
do \
  gcloud projects add-iam-policy-binding \
    [PROJECT_ID]\
    --member='serviceAccount:[NAME]@[PROJECT_ID].iam.gserviceaccount.com' \
    --role="${role}"
done
```

### 2. Set up OS Login

OS Login lets you securely SSH into GCE instances when using a **service account**. The benefit compared to traditional SSH is that it lets you interact with any host in a project without previously having to provision a Linux user and adding the SSH public key file in every instance. This means that a new **service account** created and with OS Login setup can interact inmediatly with all instances in a project.

Note that by default, all GCE instances created had SSH blocked, so OS Login comes handy in these situations also because it is not necessary to manually access via GCP SSH console or gcloud to enable SSH connections. We are looking for fully automatization, so we don't want  manual interactions with the instance.

The **service account** will become the Linux user of the instances and it won't need to manually SSH into any instance ever. As a result, security in the server is improved due to the blocked SSH daemon that every GCE instance has by default.

1. Enable OS Login in project-wide metadata so that it applies to all of the instances in your project
```
gcloud compute project-info add-metadata \
    --metadata enable-oslogin=TRUE
```

2. Generating Service Account Key file
```
gcloud iam service-accounts keys create --iam-account [ACCOUNT] [FILE].json
```

The `[FILE].json` file will be downloaded into the path directory where you ran the command.

3. Activate service account 
```
gcloud auth activate-service-account --key-file=[FILE].json
```

4. Adding SSH keys to a user account
- Swich to **service account**
```
gcloud config set account [ACCOUNT]
```
- Add SSH key
```
gcloud compute os-login ssh-keys add --key-file ~/.ssh/id_rsa.pub
```
- Switch back from **service account**
```
gcloud config set account your@gmail.com
```

5. Gather service account `uniqueId`
```
gcloud iam service-accounts describe \
    [ACCOUNT] \
        --format='value(uniqueId)'
```

6. (Optional) SSH into an instance using a service account

If you have previous instances created, you can SSH into them:

```
ssh -i .ssh/id_rsa [sa_<uniqueId>]@[INSTANCE_IP]
```

Note that we prefixed the `uniqueId` with `sa_`

### 3. (Conditional) Set user permissions to .ansible/cp/ 

If you are using a Playbook with `add_host` module, you must give user permissions to `~/.ansible/cp/` directory:

```
sudo chown -R $USER:$USER ~/.ansible/cp
```

### 4. Using a service account

1. For creating resources and instances, you just run:

```
ansible-playbook [FILE].yml
```

2. For managing instances, you run:
- Playbooks
```
ansible-playbook [FILE].yml -u [sa_<uniqueId>] 
```
- Ad-Hoc commands
```
ansible -i <inventory> all -m ping -u [sa_<uniqueId>]
```

### Useful commands for managing accounts

```
gcloud auth list
gcloud config list
gcloud config configurations list
gcloud config set account [your@gmail.com] or [ACCOUNT]
gcloud iam service-accounts list
gcloud iam service-accounts describe [ACCOUNT]
gcloud iam service-accounts keys list --iam-account=[ACCOUNT]
gcloud projects get-iam-policy [PROJECT_ID]
```


## GCE Dynamic Inventory

The best way to interact with your hosts is to use the **gcp_compute** inventory plugin, which dynamically queries GCE and tells Ansible what nodes can be managed.

To be able to use this GCE dynamic inventory plugin, you need to enable it first by adding `gcp_compute` in the **[inventory]** section of the **ansible.cfg** file:

```
[inventory]
enable_plugins = host_list, virtualbox, yaml, constructed, gcp_compute
```

Then, create a file in the root of your project's working directory with the suffix `.gcp.yml`: `<filename>.gcp.yml`

The gcp_compute inventory script takes in the same authentication information as any module.

Here’s an example of a valid inventory file:

```ini
plugin: gcp_compute
projects:
  - vpn-server-sasp
service_account_file: /home/cheo/sergio/gce_sa_keys/ansible-sa.json
auth_kind: serviceaccount
scopes:
 - 'https://www.googleapis.com/auth/cloud-platform'
 - 'https://www.googleapis.com/auth/compute.readonly'



zones: # populate inventory with instances in these regions
  #- us-central1-a
filters:
#   - machineType = n1-standard-1
#   - scheduling.automaticRestart = true AND machineType = n1-standard-1
keyed_groups:
  # Create groups from GCE labels
  - prefix: gcp
    key: labels
  - prefix: zone
    key: zone
  # Create groups by filtering key-values on lables and lists
groups:
  cms: "'server' in (labels|list)"
  development: "'python3' in name"
hostnames:
  # List host by name instead of the default public ip
  - name
compose:
  # Set an inventory parameter to use the Public IP address to connect to the host
  # For Private ip use "networkInterfaces[0].networkIP"
  ansible_host: networkInterfaces[0].accessConfigs[0].natIP
```

To show a list of GCP instances based on filters, labels, zones, etc configured in the inventory file `<filename>.gcp.yml`, run:

```
ansible-inventory -i <filename>.gcp.yml --graph
```

- Result (example):

```
@all:
  |--@cms:
  |  |--terraform-instance
  |--@development:
  |  |--python3-test
  |--@gcp_server_wordpress:
  |  |--terraform-instance
  |--@ungrouped:
  |--@zone_us_central1_a:
  |  |--python3-test
  |  |--terraform-instance
  |  |--test-vm
```

With this information, you can execute **Ad-Hoc** commands or **Playbooks** targeting **all** hosts, a specific **group** host or a specific **instance** host.

### Ad-Hoc commands and GCE Dynamic Inventory
```
ansible -i <filename>.gcp.yml all -m ping -u [sa_<uniqueId>]
ansible -i <filename>.gcp.yml cms -m shell -a 'uname -a' -u [sa_<uniqueId>]
ansible -i <filename>.gcp.yml terraform-instance -m shell -a 'uname -a' -u [sa_<uniqueId>]
```

You can add `<filename>.gcp.yml` under `[defaults]` in the `ansible.cfg` to avoid typing `-i <filename>.gcp.yml` each time:
```
[inventory]
enable_plugins = host_list, virtualbox, yaml, constructed, gcp_compute

[defaults]
inventory = <filename>.gcp.yml
```

### Playbooks and GCE Dynamic Inventory

- **example-playbook.yml**

```
- name: Update the repositories
  gather_facts: no
  hosts: development # targetting development group host
  become: yes
  roles:
    - update-repositories
```

- Run:
```
ansible-playbook example-playbook.yml -u [sa_<uniqueId>]
```


Re: [Google Cloud Compute Engine inventory source](https://docs.ansible.com/ansible/latest/collections/google/cloud/gcp_compute_inventory.html#ansible-collections-google-cloud-gcp-compute-inventory)
