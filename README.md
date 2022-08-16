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

## Build the infrastructure
----------------------------------

### Deploy the Infrastrutre

1. First you will need to jump into the build-infra directory 

``` cd  01-deploy-infra ```

Run Terraform

```
terraform init
terraform plan
terraform apply 
```

2. The output will give you all the information to access all the devices

### Configure the Infrastrutre

1. First you will need to jump into the configure-infra directory 

``` cd  02-configure-infra ```

Run Terraform

```
terraform init
terraform plan
terraform apply 
```



### Deploy Apps

1. First you will need to jump into the deploy-apps directory 

``` cd  03-deploy-apps ```

Run Terraform

```
terraform init
terraform plan
terraform apply 
```


### Deploy Network Infrastructure Automation

1. First you will need to jump into the network automation directory 

``` cd  04-network-automation ```

Run Terraform

```
terraform init
terraform plan
terraform apply 
```