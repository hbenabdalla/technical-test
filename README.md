# technical-test Containerization Section

## Containers images

1. [The Frontend image](https://hub.docker.com/layers/bahamdi/ex/ariane/images/sha256-bdc6e97f45aa1001c810c338abab3b999b143c1e601445e0f65e50d37e4c7c9d)

```
docker pull bahamdi/ex:ariane
```
2. [The Backend image](https://hub.docker.com/layers/bahamdi/ex/falcon/images/sha256-e08f547a227cd37cf7e3664d1eb5d3f8f23788452506ac9454b0f3de734ccfaf)

```
docker pull bahamdi/ex:falcon
```
3. [The Redis image](https://hub.docker.com/layers/bahamdi/ex/redis/images/sha256-61903f324d85a1e36ffc9f05415da4b7a18723453b9afa654024d8c719e3b304)

```
docker pull bahamdi/ex:redis
```
## Kubernetes Manifests and commands

All project manifests are under folder `manifests`

1. Create required Namespace

> We are creating a namespace named `exns`

```
kubectl create ns exns
```
2. We need to create the persistent volume and the claim

```
kubectl apply -f persistent-volumes.yaml
```
3. Create the ConfigMaps and the secrets

> We have to change the code in the backend application so it will get the `Redis` Host and port from Environement Variables. 

```
kubectl apply -f configmaps.yaml
kubectl apply -f secrets.yaml
```
4. We start by deploying the Redis instance as it is required for the Backend.

```
kubectl apply -f redis-deployment.yaml
```

5. We deploy the Backend App

```
kubectl apply -f backend-deployment.yaml
```

6. Now we deploy the Frontend App

```
kubectl apply -f frontend-deployment.yaml
```

> I created ingress services for both the Frontend and Backend App to be able to test them. But in production we need to avoid exposing the Backend for security concerns.

# technical-test Terraform Section
## Installation

Follow these steps to install Terraform and set up our environment:

1. Terraform installation

```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```
2. Verify the installation

```
terraform -v
```

3. AWS CLI installation

```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
4. Verify AWS installation

```
aws --version
```
5. Configure AWS

```
aws configure
```
> We need to create credentials from AWS Console

6. Plan terraform execution

```
terraform plan -out=tfplan
```
> The output file named `tfplan` will serve to play the terraform script.

7. Run the terraform plan

```
terraform apply "tfplan"
```


# technical-test Ansible Section

This project contains two Ansible playbooks used to manage user accounts, configure systems and encrypt user's passwords. The instructions below will guide you through setting up the environment and running the playbooks.


## Installation

Follow these steps to install Ansible and set up your environment:

### Install Ansible with pipx

pipx is a tool that allows you to install Python applications in isolated environments. Here's how to install Ansible using pipx:

1. Install pipx (if not already installed):

```
python3 -m pip install --user pipx
python3 -m pipx ensurepath
```

2. Install Ansible using pipx:

```
pipx install ansible
```

3. Verify Ansible Installation: After installing, verify that Ansible is correctly installed:

```
ansible --version
```
## Connecting to AWS using Dynamic Inventory

To interact with AWS resources dynamically, we use the AWS EC2 Dynamic Inventory. This method fetches host information directly from AWS, so you don't have to manually define the host inventory.

### Prerequisites

AWS CLI Configuration: We must have the AWS CLI installed and configured with appropriate credentials.
+ If you haven't already configured your AWS credentials, use the following command:

```
aws configure
```
+ Install boto3 (Python SDK for AWS): Ensure that boto3 is installed to interact with AWS.

```
pipx install boto3 botocore
```

+ Dynamic Inventory Plugin: Ensure the Ansible dynamic inventory plugin for AWS is available. This is included by default in newer versions of Ansible.


> Based on the required security groups rules created in the terraform script we will not be able to run our Ansible playbooks on VMs unless we add security groups to allow our public IP to SSH to the `bastion` instance "Ariane" and the add security groups to allow SSH from `Ariane` to the rest of instances.</br>

> The Ansible playbook will require *package installation* also like "Docker" and to *download images* from ECR so we needed to add *Private Subnet Route Table* and associate it to the *private subnet* to allow this task success.
  
### Setting Up Dynamic Inventory for AWS
1. Create or Edit aws_ec2.yml: Here's an example of an aws_ec2.yml file used for dynamic inventory:

```
plugin: aws_ec2
regions:
  - us-east-1
filters:
  tag:Name: "technical-test-*" # Matches all instances starting with "technical-test-"
keyed_groups:
  - key: tags.Name
    prefix: "aws_"
hostnames:
  - tag:Name
compose:
  ansible_user: "'ec2-user'"
  ansible_host: private_ip_address
```

> Here we use the tag:Name to select our concerned instances and we use the private_ip_address as we are going to use the ariane instance as Bastion because Falcon and Redis instances are in the private subnet.

### Configuring `ansible.cfg`

To simplify our Ansible setup and enable features such as using a bastion host and dynamic inventory, we will configure our `ansible.cfg` file as follows:

1. Edit or create a file named `ansible.cfg` in the root of our project directory.
2. Add the following configuration to use `ariane` as the bastion host through it's public-ip:

```ini
[defaults]
inventory = ./aws_ec2.yml
private_key_file = /home/hamdi/project/terraform/hamdi-key
[inventory]
enable_plugins = aws_ec2
[ssh_connection]
ssh_args = -o ForwardAgent=yes -o ProxyCommand="ssh -i /home/hamdi/project/terraform/hamdi-key -W %h:%p ec2-user@ariane-public-ip"
```

> We need to provide the private key used during the VMs provisionning
> We need to provide the Public IP Address of the Ariane instance from AWS so we can use it as proxy for Ansible

## Running Playbooks

### Running the Main Playbook

1. Ensure that the environment is set up (see Installation for setup instructions).

2. Navigate to your Ansible project directory where the main_playbook.yml is located.

3. Run the Main Playbook: Our playbook is called main.yml, we can execute it:

```
ansible-playbook main.yml
```

The playbook will run all the tasks defined in it, such as managing user accounts, applying configurations, and other specified automation steps.

### Running encrypt_pwd.yml Playbook

> The encrypt_pwd.yml playbook encrypts user passwords stored in a YAML file locally. We keep this task separate in a diffrent playbook to avoid breaking the users passwords during the main playbook execution.

1. Ensure you have the user_accounts.yml file with user details, including unencrypted passwords under vars folder.
2. Run the encrypt_pwd.yml playbook to encrypt the passwords:

```
ansible-playbook encrypt_pwd.yml
```
