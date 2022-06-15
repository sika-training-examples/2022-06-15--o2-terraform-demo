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

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_"
}

output "password" {
  value     = random_password.password.result
  sensitive = true
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

resource "azurerm_public_ip" "main" {
  name                = "ondrejsika"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_resource_group.training.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "main" {
  name                = "ondrejsika"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name

  ip_configuration {
    name                          = "net0"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.internal.id
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "ondrejsika"
  location              = azurerm_resource_group.training.location
  resource_group_name   = azurerm_resource_group.training.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "disk0"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "ondrejsika"
    admin_username = "default"
    admin_password = random_password.password.result
  }
  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      path     = "/home/default/.ssh/authorized_keys"
      key_data = azurerm_ssh_public_key.default.public_key
    }
    ssh_keys {
      path     = "/home/default/.ssh/authorized_keys"
      key_data = data.azurerm_ssh_public_key.petr.public_key
    }
  }
}

output "ip" {
  value = azurerm_public_ip.main.ip_address
}

output "ssh" {
  value = "default@${azurerm_public_ip.main.ip_address}"
}

resource "azurerm_public_ip" "foo" {
  name                = "foo"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_resource_group.training.location
  allocation_method   = "Static"
}


module "vm--foo" {
  source               = "./modules/vm"
  name                 = "foo"
  resource_group       = azurerm_resource_group.training
  public_ip_address_id = azurerm_public_ip.foo.id
  subnet_id            = azurerm_subnet.internal.id
  ssh_keys = [
    azurerm_ssh_public_key.default.public_key,
    data.azurerm_ssh_public_key.petr.public_key,
  ]
}
