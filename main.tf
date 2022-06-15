locals {
  LOCATION = "westeurope"
}

resource "azurerm_resource_group" "training" {
  name     = "training-ondrejsika"
  location = local.LOCATION
}
