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
There


terraform init
terraform apply 

more coming soon