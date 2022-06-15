output "password" {
  value     = local.password
  sensitive = true
}

output "azurerm_network_interface" {
  value = azurerm_network_interface.this
}


output "azurerm_virtual_machine" {
  value = azurerm_virtual_machine.this
}
