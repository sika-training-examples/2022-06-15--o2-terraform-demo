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
