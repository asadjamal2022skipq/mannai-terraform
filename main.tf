locals {
    instances = csvdecode(file("test.csv"))
    rgData= {
        for i in local.instances : i.Rgname_name => {
            Locations = i.Locations
        }
     }
    vnetData= {
        for i in local.instances : i.app_service_name => {
            Locations = i.Locations
            Environement = i.env_name
            ResourceGroup = i.Rgname_name
            Locations = i.Locations
            App_Service_Plan = i.app_service_plan_name
            V_netName = i.vnet_name
            V_net_AddressSpace = i.vnet_address_space
            V_net_integration_subnet_name = i.V_net_integ_subnet_name
            V_net_integration_subnet_Address_prefix = i.V_net_integ_subnet_address_prefix
            V_net_NSG_Name = i.V-net_NSG_Name
            Web_subnet_name = i.web_subnet_name
            Web_Subnet_prefix = i.web_subnet_prefix
            sku_name = i.sku_name
            os_type = i.os_type

        }
     }
}

resource "azurerm_resource_group" "RGroups" {
  for_each = local.vnetData
  name     = each.value.ResourceGroup
  location = each.value.Locations
}

resource "azurerm_virtual_network" "Azure_vnet" {
  for_each = local.vnetData
  name                = each.value.V_netName
  address_space       = [each.value.V_net_AddressSpace]
  location            = each.value.Locations
  resource_group_name = each.value.ResourceGroup
}

resource "azurerm_subnet" "Subnet-main" {
  for_each = local.vnetData
  name                 = each.value.V_net_integration_subnet_name
  resource_group_name  = each.value.ResourceGroup
  virtual_network_name = azurerm_virtual_network.Azure_vnet[each.key].name
  address_prefixes     = [each.value.V_net_integration_subnet_Address_prefix]

  delegation {
    name = "example-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_service_plan" "ServicePlan" {
  for_each = local.vnetData
  name                = each.value.App_Service_Plan
  resource_group_name = each.value.ResourceGroup
  location            = each.value.Locations
  os_type             = each.value.os_type
  sku_name            = each.value.sku_name
}

resource "azurerm_linux_web_app" "Service" {
  for_each = local.vnetData
  name                = each.key
  resource_group_name = each.value.ResourceGroup
  location            = each.value.Locations
  service_plan_id     = azurerm_service_plan.ServicePlan[each.key].id
  virtual_network_subnet_id = azurerm_subnet.Subnet-main[each.key].id
  site_config {}
}