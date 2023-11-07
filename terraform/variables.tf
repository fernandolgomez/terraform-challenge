#variable for VM Names
variable "vm_names" {
  type    = list(string)
}

#variable for Azure location
variable "location" {
  type    = string
}

#variable for resource group name
variable "resource_group_name" {
  type    = string
}

#variable for VMs Tags
variable "tags" {
  type    = list(map(string))
}

#variable for network range
variable "node_address_space" {
  type    = list(string)
}

#variable for subnet prefix
variable "node_address_prefix" {
  type    = list(string)
}

#variable for virtual network name
variable "vnet_name" {
  type    = string
}

#variable for subnet name
variable "subnet_name" {
  type    = string
}

#variable for Defender contact information: email address
variable "email" {
  type    = string
}

#variable for Defender Tier
variable "defender_tier" {
  type    = string
}

#variable for Defender contact information: phone number
variable "phone_number" {
  type    = string
}

#variable for password length
variable "random_password_length" {
  type    = number
}

#variable for VM size
variable "vm_size" {
  type    = string
}

#variable for Storage Account type
variable "storage_account_type" {
  type    = string
}

#variable for Log Analytics Workspace name
variable "log_analytics_name" {
  type    = string
}

#variable for Log Analytics Workspace SKU
variable "log_analytics_sku" {
  type    = string
}

#variable for Log Analytics Workspace retention period
variable "log_analytics_retention_in_days" {
  type    = number
}
