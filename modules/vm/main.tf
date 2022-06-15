locals {
  password = var.password == "" ? random_password.password[0].result : var.password
}

resource "random_password" "password" {
  count            = var.password == "" ? 1 : 0
  length           = 16
  special          = true
  override_special = "_"
}

resource "azurerm_network_interface" "this" {
  name                = var.name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name

  ip_configuration {
    name                          = "net0"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet_id
    public_ip_address_id          = var.public_ip_address_id
  }
}

resource "azurerm_virtual_machine" "this" {
  name                  = var.name
  location              = var.resource_group.location
  resource_group_name   = var.resource_group.name
  network_interface_ids = [azurerm_network_interface.this.id]
  vm_size               = var.vm_size

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = var.name
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.name
    admin_username = "default"
    admin_password = local.password
    custom_data    = var.custom_data
  }
  os_profile_linux_config {
    disable_password_authentication = false
    dynamic "ssh_keys" {
      for_each = var.ssh_keys
      content {
        path     = "/home/default/.ssh/authorized_keys"
        key_data = ssh_keys.value
      }
    }
  }
}
