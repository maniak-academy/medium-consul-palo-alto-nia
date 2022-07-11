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
CONSUL_VERSION="1.12.1"
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip

#Install Consul
unzip consul_${CONSUL_VERSION}_linux_amd64.zip
sudo chown root:root consul
sudo mv consul /usr/local/bin/
consul -autocomplete-install
complete -C /usr/local/bin/consul consul

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


cat << EOF > /etc/consul.d/consul.hcl
data_dir = "/opt/consul"
datacenter = "AcademyDC1"
ui = true
retry_join = ["${consul_server_ip}"]
EOF

#Install Dockers
sudo snap install docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose



cat << EOF > /etc/consul.d/fakeservice.hcl
service {
  id      = "fakeservice"
  name    = "fakeservice"
  tags    = ["production","fakeservice"]
  port    = 9090
  check {
    id       = "fakeservice"
    name     = "TCP on port 9090"
    tcp      = "localhost:9090"
    interval = "10s"
    timeout  = "1s"
  }
}
EOF



#Enable the service
sudo systemctl enable consul
sudo service consul start
sudo service consul status



#Install Dockers
sudo snap install docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


sleep 10
cat << EOF > docker-compose.yml
version: "3.7"
services:

  web:
    image: nicholasjackson/fake-service:v0.7.8
    environment:
      LISTEN_ADDR: 0.0.0.0:9090
      UPSTREAM_URIS: "http://api:9094"
      MESSAGE: "Hello World"
      NAME: "web"
      SERVER_TYPE: "http"
    ports:
    - "9090:9090"

  api:
    image: nicholasjackson/fake-service:v0.7.8
    environment:
      LISTEN_ADDR: 0.0.0.0:9094
      UPSTREAM_URIS: "http://backend1:9090/abc/123123, http://backend2:9090, http://backend3:9090, http://backend4:9090"
      UPSTREAM_WORKERS: 6
      MESSAGE: "API response"
      NAME: "api"
      SERVER_TYPE: "http"
      HTTP_CLIENT_APPEND_REQUEST: "true"

  backend1:
    image: nicholasjackson/fake-service:v0.7.8
    environment:
      LISTEN_ADDR: 0.0.0.0:80
      MESSAGE: "backend1 response"
      NAME: "backend1"
      SERVER_TYPE: "http"

  backend2:
    image: nicholasjackson/fake-service:v0.7.8
    environment:
      LISTEN_ADDR: 0.0.0.0:9090
      MESSAGE: "backend2 response"
      NAME: "backend2"
      SERVER_TYPE: "http"
      HTTP_CLIENT_APPEND_REQUEST: "true"

  backend3:
    image: nicholasjackson/fake-service:v0.7.8
    environment:
      LISTEN_ADDR: 0.0.0.0:9090
      MESSAGE: "backend3 response"
      NAME: "backend3"
      SERVER_TYPE: "http"
      HTTP_CLIENT_APPEND_REQUEST: "true"

  backend4:
    image: nicholasjackson/fake-service:v0.7.8
    environment:
      LISTEN_ADDR: 0.0.0.0:9090
      MESSAGE: "backend4 response"
      NAME: "backend4"
      SERVER_TYPE: "http"
      HTTP_CLIENT_APPEND_REQUEST: "true"

EOF
sudo docker-compose up -d
