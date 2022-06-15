variable "name" {
  type        = string
  description = "Name of virtual machine"
}

variable "resource_group" {}

variable "subnet_id" {
  type = string
}

variable "public_ip_address_id" {
  type = string
}

variable "vm_size" {
  type    = string
  default = "Standard_B1ls"
}

variable "password" {
  type        = string
  default     = ""
  description = "Password for admin (default) user"
  sensitive   = true
}

variable "ssh_keys" {
  type        = list(string)
  default     = []
  description = "List of public key data"
}
