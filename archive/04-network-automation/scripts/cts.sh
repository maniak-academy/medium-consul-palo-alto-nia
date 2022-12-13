#!/bin/bash
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"

#Utils
sudo apt-get install unzip
sudo apt-get install unzip
sudo apt-get update
sudo apt-get install software-properties-common
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get jq


#Download Consul
CONSUL_VERSION="1.14.1"
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip

#Install Consul
unzip consul_${CONSUL_VERSION}_linux_amd64.zip
sudo chown root:root consul
sudo mv consul /usr/local/bin/
consul -autocomplete-install
complete -C /usr/local/bin/consul consul

#Install Consul Terraform Sync

export CTS_CONSUL_VERSION="0.6.0-beta1"
export CONSUL_URL="https://releases.hashicorp.com/consul-terraform-sync"


curl --silent --remote-name \
  ${CONSUL_URL}/${CTS_CONSUL_VERSION}/consul-terraform-sync_${CTS_CONSUL_VERSION}_linux_amd64.zip

curl --silent --remote-name \
  ${CONSUL_URL}/${CTS_CONSUL_VERSION}/consul-terraform-sync_${CTS_CONSUL_VERSION}_SHA256SUMS

curl --silent --remote-name \
  ${CONSUL_URL}/${CTS_CONSUL_VERSION}/consul-terraform-sync_${CTS_CONSUL_VERSION}_SHA256SUMS.sig

#Unzip the downloaded package and move the consul binary to /usr/bin/. Check consul is available on the system path.

unzip consul-terraform-sync_${CTS_CONSUL_VERSION}_linux_amd64.zip
mv consul-terraform-sync /usr/local/bin/consul-terraform-sync

sudo mkdir --parents /opt/consul


#Create Consul User
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir --parents /opt/consul
sudo chown --recursive consul:consul /opt/consul

#Create Systemd Config
sudo cat << EOF > /etc/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl
[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
KillMode=process
Restart=always
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF



#Create config dir
sudo mkdir --parents /etc/consul.d
sudo touch /etc/consul.d/consul.hcl
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul.hcl




#consul config
cat << EOF > /etc/consul.d/consul.hcl
data_dir = "/opt/consul"
datacenter = "academyDC1"
retry_join = ["${consul_server_ip}"]
EOF



# #Create Systemd Config for Consul Terraform Sync
sudo cat << EOF > /etc/systemd/system/consul-tf-sync.service
[Unit]
Description="HashiCorp Consul Terraform Sync - A Network Infra Automation solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target

[Service]
User=root
Group=root
ExecStart=/usr/bin/consul-terraform-sync start -config-file=/etc/consul-tf-sync.d/consul-tf-sync-secure.hcl
KillMode=process
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF


cat << EOF > /etc/consul-tf-sync.d/consul-tf-sync-secure.hcl
# Global Config Options
working_dir = "/opt/consul-tf-sync.d/"
log_level = "info"
buffer_period {
  min = "5s"
  max = "20s"
}

id = "consul-terraform-sync"

consul {
    address = "localhost:8500"
    service_registration {
      enabled = true
      service_name = "consul-terraform-sync"
      default_check {
        enabled = true
        address = "http://${local_ipv4}:8558"
      }
    }
}

vault {
  address = "$${VAULT_ADDR}"
  token   = "${vault_token}"
}

# Terraform Driver Options
driver "terraform" {
  log = true
  path = "/opt/consul-tf-sync.d/"
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
    }
  }
}

## Network Infrastructure Options


## Network Infrastructure Options


# Palo Alto Workflow Options
terraform_provider "panos" {
  alias = "panos1"
  hostname = "${panos_mgmt_addr}"
#  api_key  = "<api_key>"
  username = "${panos_username}"
  password = "{{ with secret \"net_infra/paloalto\" }}{{ .Data.data.panpassword }}{{ end }}"
}

## Consul Terraform Sync Task Definitions

# # Firewall operations task
task {
  name = "Dynamic_Address_Group_PaloAlto_FW"
  description = "Automate population of dynamic address group"
  module = "github.com/maniak-academy/panos-nia-dag"
  providers = ["panos.panos1"]
  condition "services" {
    names = ["web", "api", "db", "logging"]
  }  
  variable_files = ["/etc/consul-tf-sync.d/panos.tfvars"]
}
EOF

cat << EOF > /etc/consul-tf-sync.d/panos.tfvars
dag_prefix = "cts-addr-grp-"
EOF

#Enable the services
sudo systemctl enable consul
sudo service consul start
sudo service consul status
sudo systemctl enable consul-tf-sync
sudo service consul-tf-sync start
sudo service consul-tf-sync status



