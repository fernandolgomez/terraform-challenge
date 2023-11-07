#General Variables
  location = "eastus"
  resource_group_name = "rg-fernandolucianogomez"


#VM Variables
  vm_names = ["TESTDC01", "TESTAPP01"]
  random_password_length = 16
  vm_size = "Standard_B2s"
  storage_account_type = "Standard_LRS"
  tags = [
      {
        AutoPatching = "FALSE"
        Defender     = "TRUE"
      },
      {
        AutoPatching = "TRUE"
        Defender     = "TRUE"
      }
    ]


#Network Variables
  vnet_name = "vnet-fernandolucianogomez"
  subnet_name = "subnet-fernandolucianogomez"
  node_address_space = ["1.0.0.0/16"]
  node_address_prefix = ["1.0.1.0/24"]


#Defender Variables
  email = "fernandolucianogomez@outlook.com"
  defender_tier = "Standard"
  phone_number = "+54-911-6979-6539"


#Log Analytics Variables
  log_analytics_name = "law01"
  log_analytics_sku = "PerGB2018"
  log_analytics_retention_in_days = 30

