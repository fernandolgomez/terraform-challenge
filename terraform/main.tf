terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {}

# Configure Azure Defender Alers
resource "azurerm_security_center_contact" "myDefenderInstance" {
  alert_notifications = true
  alerts_to_admins    = true
  email    = var.email
  phone = var.phone_number
}

# Configure Azure Defender for Servers
resource "azurerm_security_center_subscription_pricing" "mdc_servers" {
  tier          = var.defender_tier
  resource_type = "VirtualMachines"
}


# Define the Azure policy rule that will install Azure Defender for Servers extension when VM tag is Defender=TRUE
variable "policy_rule" {
  default = <<POLICY_RULE
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Compute/virtualMachines"
      },
      {
        "field": "Microsoft.Compute/virtualMachines/storageProfile.osDisk.osType",
        "like": "Windows*"
      },
      {
        "field": "tags['Defender']",
        "equals": "TRUE"
      }
    ]
  },
  "then": {
    "effect": "DeployIfNotExists",
    "details": {
      "roleDefinitionIds": [
        "/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
      ],
      "type": "Microsoft.Compute/virtualMachines/extensions",
      "name": "MDE.Windows",
      "existenceCondition": {
        "allOf": [
          {
            "field": "Microsoft.Compute/virtualMachines/extensions/publisher",
            "equals": "Microsoft.Azure.AzureDefenderForServers"
          },
          {
            "field": "Microsoft.Compute/virtualMachines/extensions/type",
            "equals": "MDE.Windows"
          },
          {
            "field": "Microsoft.Compute/virtualMachines/extensions/provisioningState",
            "equals": "Succeeded"
          }
        ]
      },
      "deployment": {
        "properties": {
          "mode": "incremental",
          "parameters": {
            "vmName": {
              "value": "[field('name')]"
            },
            "location": {
              "value": "[field('location')]"
            },
            "azureResourceId": {
              "value": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Compute/virtualMachines/',field('name'))]"
            }
          },
          "template": {
            "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
            "contentVersion": "1.0.0.0",
            "parameters": {
              "vmName": {
                "type": "string"
              },
              "location": {
                "type": "string"
              },
              "azureResourceId": {
                "type": "string"
              }
            },
            "resources": [
              {
                "apiVersion": "2020-06-01",
                "name": "[concat(parameters('vmName'), '/MDE.Windows')]",
                "type": "Microsoft.Compute/virtualMachines/extensions",
                "location": "[parameters('location')]",
                "properties": {
                  "autoUpgradeMinorVersion": true,
                  "publisher": "Microsoft.Azure.AzureDefenderForServers",
                  "type": "MDE.Windows",
                  "typeHandlerVersion": "1.0",
                  "settings": {
                    "azureResourceId": "[parameters('azureResourceId')]",
                    "vNextEnabled": "true",
                    "installedBy": "Policy"
                  },
                  "protectedSettings": {
                    "defenderForEndpointOnboardingScript": "[reference(subscriptionResourceId('Microsoft.Security/mdeOnboardings', 'Windows'), '2021-10-01-preview', 'full').properties.onboardingPackageWindows]"
                  }
                }
              }
            ]
          }
        }
      }
    }
  }
}
POLICY_RULE
}

# Create the Azure policy definition using previuos policy rule
resource "azurerm_policy_definition" "defender_policy" {
  name         = "enable-defender-policy"
  description  = "Enable Azure Defender for VMs with the Defender tag set to TRUE"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Enable Azure Defender for VMs with Defender tag"
  policy_rule = var.policy_rule
}

# Assign the Azure Policy to your Azure subscription
resource "azurerm_subscription_policy_assignment" "defender_policy_assignment" {
  name                  = "defender-policy-assignment"
  subscription_id       = data.azurerm_subscription.current.id
  policy_definition_id = azurerm_policy_definition.defender_policy.id
  # Add a system-assigned managed identity
    identity {
      type = "SystemAssigned"
    }
  location             = var.location
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create a virtual network for Virtual Machines
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.node_address_space

}

# Create a Subnet for Virtual Machines
resource "azurerm_subnet" "subnet" {
  name                = var.subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name = azurerm_resource_group.rg.name
  address_prefixes     = var.node_address_prefix
}

# Create NICs for Virtual Machines
resource "azurerm_network_interface" "nic" {
    count = length(var.vm_names)

  name = "${var.vm_names[count.index]}-NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create password for Virtual Machines users
resource "random_password" "vm" {
  length           = var.random_password_length
  special          = true
  override_special = "_%@"
}

# Create Windows Virtual Machines
resource "azurerm_windows_virtual_machine" "vm" {
  count = length(var.vm_names)
  name                  = var.vm_names[count.index]
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.vm_size
  admin_username      = "adminuser"
  admin_password = random_password.vm.result
  network_interface_ids = [element(azurerm_network_interface.nic.*.id, count.index)]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  tags                  = var.tags[count.index]
}

# Create Log Analytics
resource "azurerm_log_analytics_workspace" "logging_ws" {
 name                = var.log_analytics_name
 location            = azurerm_resource_group.rg.location
 resource_group_name = azurerm_resource_group.rg.name
 sku                 = var.log_analytics_sku
 retention_in_days   = var.log_analytics_retention_in_days
}

# Install Log Analytics agent on Windows Virtual Machines
resource "azurerm_virtual_machine_extension" "ama" {
 count = length(var.vm_names)
 name                       = "AzureMonitorAgent"
 virtual_machine_id         = element(azurerm_windows_virtual_machine.vm.*.id, count.index)
 publisher                  = "Microsoft.Azure.Monitor"
 type                       = "AzureMonitorWindowsAgent"
 type_handler_version       = "1.10"
 auto_upgrade_minor_version = "true"
}

#Create maintenance configuration for Windows Virtual Machines
resource "azurerm_maintenance_configuration" "maintenance_configuration" {
  location = azurerm_resource_group.rg.location
  name     = "installs_only_security_and_critical_updates"
  in_guest_user_patch_mode = "User"
  resource_group_name = azurerm_resource_group.rg.name
  scope               = "InGuestPatch"
  tags                = {}
  visibility          = "Custom"
  timeouts {
    create = null
    delete = null
    read   = null
    update = null
  }

  install_patches {
    reboot = "IfRequired"
    windows {
      classifications_to_include = [
        "Critical", "Security"
      ]
    }
  }

  
  window {
    duration             = "03:55"
    expiration_date_time = null
    recur_every          = "1Month Second Sunday"
    start_date_time      = "2023-11-03 00:00"
    time_zone            = "Argentina Standard Time"
  }

}

#create maintenance assignment for Windows Virtual Machines
resource "azurerm_subscription_policy_assignment" "test" {
  description          = null
  display_name         = "Schedule recurring updates using Azure Update Manager"
  enforce              = true
  location             = "eastus"
  metadata             = "{\"assignedBy\":\"Fernando Gomez\",\"createdBy\":\"a9d82c3d-45ea-4fe3-833f-63f5f6626be3\",\"createdOn\":\"2023-11-06T03:50:28.1505664Z\",\"parameterScopes\":{\"locations\":\"/subscriptions/496a2d32-9f6f-46cf-b821-211ae3b5de98\"},\"updatedBy\":null,\"updatedOn\":null}"
  name                 = "Schedule recurring updates using Azure Update Manager"
  not_scopes           = []
  #parameters           = "{\"maintenanceConfigurationResourceId\":{\"value\":\"/subscriptions/496a2d32-9f6f-46cf-b821-211ae3b5de98/resourcegroups/rg-fernandolucianogomez/providers/microsoft.maintenance/maintenanceconfigurations/installs_only_security_and_critical_updates\"},\"operatingSystemTypes\":{\"value\":[\"Windows\"]},\"tagValues\":{\"value\":[{\"key\":\"AutoPatching\",\"value\":\"TRUE\"}]}}"
  parameters           = "{\"maintenanceConfigurationResourceId\":{\"value\":\"${azurerm_maintenance_configuration.maintenance_configuration.id}\"},\"operatingSystemTypes\":{\"value\":[\"Windows\"]},\"tagValues\":{\"value\":[{\"key\":\"AutoPatching\",\"value\":\"TRUE\"}]}}"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/ba0df93e-e4ac-479a-aac2-134bbae39a1a"
  subscription_id      = data.azurerm_subscription.current.id
  identity {
    identity_ids = []
    type         = "SystemAssigned"
  }
}
