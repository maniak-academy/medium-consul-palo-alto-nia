# under connstruction still .


# medium-consul-palo-alto-nia

The follow repo builds an event-driven architecture that allows you to play with Vault, Consul, Boundary and delever a automation/zero-trust security solution to manage Palo Alto address groups based on what servers are registred and online in Consul.


![title](./images/consulnia.png)


## Prerequisites 

* Azure cloud subscrition
* Terraform installed on your machine to initiate the code
* Azure CLI

## How to start 

1. Log into your azure environment and get a subscription ```az account list ``` 
2. Need to accept the Azure Palo Alto marketpalce terms, replace MYSUB with your subscription ID

```
az vm image terms accept --publisher paloaltonetworks --offer vmseries-flex --plan bundle1 --subscription MYSUB
```
3. Install terraform  (brew install terraform)

### Download the repo
Pull the code from the repo 

``` 
git clone https://github.com/maniak-academy/medium-consul-palo-alto-nia.git
```

### Build the infrastructure

```
├── build-infra
│   ├── main.tf
│   ├── network
│   │   ├── main.tf
│   │   ├── output.tf
│   │   └── variables.tf
│   ├── output.tf
│   ├── pan-os
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── routes.tf
│   │   ├── security.tf
│   │   └── variables.tf
│   ├── sharedservices
│   │   ├── bastion.tf
│   │   ├── certs
│   │   ├── consul.tf
│   │   ├── outputs.tf
│   │   ├── scripts
│   │   │   ├── consul.sh
│   │   │   └── vault.sh
│   │   ├── variables.tf
│   │   └── vault.tf
│   ├── terraform.tfvars
│   ├── variables.tf
│   ├── version.tf
│   └── webservice
│       ├── certs
│       ├── outputs.tf
│       ├── scripts
│       │   └── juiceshop.sh
│       ├── ssh-web.tf
│       ├── variables.tf
│       └── web.tf
├── configuration
│   ├── main.tf
│   ├── pan-config
│   │   ├── main.tf
│   │   └── versions.tf
│   ├── panos_commit
│   │   └── panos-commit
│   ├── variables.tf
│   └── vault
│       ├── main.tf
│       └── variables.tf

```

1. First you will need to jump into the build-infra directory ``` cd build-infra ```
2. Initiate terraform with ```terraform init ```  to download the moudles required
3. Next.. ``` terraform plan ```
4. If everything passess, its time to execute terraform apply ``` terraform apply ```
5. The output will give you all the information to access all the devices

### Configure the infrasturature
Next step will be to configure the Palo Alto and Vault

1. Cd into configure directory ``` cd configure ```
2. executre

```
terraform init
terraform plan
terraform apply 
```

### Access
The default password for vault is root. You can log into the vault server to get the palo alto credentials.