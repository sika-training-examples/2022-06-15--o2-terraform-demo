locals {
  LOCATION = "westeurope"
}

resource "azurerm_resource_group" "training" {
  name     = "training-ondrejsika"
  location = local.LOCATION
  tags = {
    terraform = "terraform"
  }
}

resource "azurerm_ssh_public_key" "default" {
  name                = "ondrejsika"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_resource_group.training.location
  public_key          = file("./ssh-keys/ondrejsika.pub")
}


data "azurerm_resource_group" "petr" {
  name = "training-simik"
}

data "azurerm_ssh_public_key" "petr" {
  name                = "petrsimik"
  resource_group_name = data.azurerm_resource_group.petr.name
}

output "ssh_key_ids" {
  value = [
    azurerm_ssh_public_key.default.id,
    data.azurerm_ssh_public_key.petr.id,
  ]
}

resource "azurerm_virtual_network" "main" {
  name                = "ondrejsika"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name
}

resource "azurerm_subnet" "internal" {
  name                 = "ondrejsika-internal"
  resource_group_name  = azurerm_resource_group.training.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]
}


locals {
  hello_vms = {
    "0" = {}
    "1" = {}
  }
  custom_data = <<EOF
#cloud-config
write_files:
- path: /html/index.html
  permissions: "0755"
  owner: root:root
  content: |
    <h1>Hello from Cloud Init
runcmd:
  - |
    apt update
    apt install -y curl sudo git nginx
    curl -fsSL https://ins.oxs.cz/slu-linux-amd64.sh | sudo sh
    cp /html/index.html /var/www/html/index.html
EOF
}

resource "azurerm_public_ip" "hello" {
  for_each = local.hello_vms

  name                = "hello${each.key}"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_resource_group.training.location
  allocation_method   = "Static"
}

module "vm--hello" {
  for_each = local.hello_vms
  source   = "./modules/vm"

  name                 = "hello${each.key}"
  resource_group       = azurerm_resource_group.training
  public_ip_address_id = azurerm_public_ip.hello[each.key].id
  subnet_id            = azurerm_subnet.internal.id
  custom_data          = local.custom_data
  ssh_keys = [
    azurerm_ssh_public_key.default.public_key,
    data.azurerm_ssh_public_key.petr.public_key,
  ]
}

output "ips" {
  value = {
    for name, ip in azurerm_public_ip.hello :
    name => ip.ip_address
  }
}

module "azure-k8s" {
  source                 = "ondrejsika/azure-k8s/module"
  version                = "0.2.1"
  azurerm_resource_group = azurerm_resource_group.training
  kubernetes_version     = "1.23.5"
  name                   = "ondrejsika"
  node_count             = 1
}

output "kubeconfig" {
  value     = module.azure-k8s.kubeconfig
  sensitive = true
}
