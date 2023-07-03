locals {
  instances = csvdecode(file("${path.module}/test.csv"))
  
  
  All_Data= {
        for i in local.instances : i.no => {
            app_service_name = i.app_service_name
            Environement = i.env_name
            ResourceGroup = i.Rgname_name
            Locations = i.Locations
            App_Service_Plan = i.app_service_plan_name
           
            V_netNam = i.vnet_name
            V_net_AddressSpace = i.address_space
            V_net_integration_subnet_name = i.subnet_name
            V_net_integration_subnet_Address_prefix = i.subnet_address_prefix
            V_net_NSG_Name = i.NSG_Name
            route_table_name = i.route_table_name

            sku_name = i.sku_name
            os_type = i.os_type
        }
     }

  vnet_data_group_by = {
    for i in local.instances : i.vnet_name => {
      resource_group = i.Rgname_name
      address_space  = i.address_space
      subnet_name = i.subnet_name
      subnet_address_prefix = i.subnet_address_prefix
      NSG_Name = i.NSG_Name
    }...
  }

  vnet_data = {
    for k, v in local.vnet_data_group_by : k => distinct(v)
  }

  rg_group_by = {
    for i in local.instances : i.Rgname_name => {
    }...
  }
  rg_data = {
    for k, v in local.rg_group_by : k => distinct(v)
  }

  app_service_plan_group_by = {
    for i in local.instances : i.app_service_plan_name => {
  resource_group_name = i.Rgname_name
  os_type_1             = i.os_type
  sku_name_1            = i.sku_name
    }...
  }
   app_service_plan_data = {
    for k, v in local.app_service_plan_group_by : k => distinct(v)
  }
}

resource "azurerm_resource_group" "RGroups" {
  for_each = local.rg_data
  name     = each.key
  location = var.location
}

resource "azurerm_virtual_network" "Azure_vnet" {
  for_each = local.vnet_data
    name                = each.key
    address_space       = [each.value[0].address_space]
    resource_group_name = "${each.value[0].resource_group}"
    location            = var.location
    depends_on = [
    azurerm_resource_group.RGroups
  ]
}

resource "azurerm_subnet" "Subnet-main" {
  for_each = local.All_Data
  name                 = each.value.V_net_integration_subnet_name
  resource_group_name  = "${each.value.ResourceGroup}"
  virtual_network_name = each.value.V_netNam
  address_prefixes     = [each.value.V_net_integration_subnet_Address_prefix]

  delegation {
    name = "example-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
  depends_on = [
    azurerm_virtual_network.Azure_vnet
  ]
}

resource "azurerm_service_plan" "ServicePlan" {
  for_each = local.app_service_plan_data
  name                = each.key
  resource_group_name = "${each.value[0].resource_group_name}"
  location            = var.location
  os_type             = each.value[0].os_type_1
  sku_name            = each.value[0].sku_name_1
  depends_on = [
    azurerm_virtual_network.Azure_vnet
  ]
}

resource "azurerm_linux_web_app" "Service" {
  for_each = local.All_Data
  name                = each.value.app_service_name
  resource_group_name = "${each.value.ResourceGroup}"
  location            = var.location
  service_plan_id     = azurerm_service_plan.ServicePlan[each.value.App_Service_Plan].id
  virtual_network_subnet_id = azurerm_subnet.Subnet-main[each.key].id

  site_config {}
  depends_on = [
    azurerm_service_plan.ServicePlan
  ]
}

resource "azurerm_network_security_group" "NSG_Global" {
for_each = local.All_Data
  name                = each.value.V_net_NSG_Name
  location            = var.location
  resource_group_name = "${each.value.ResourceGroup}"

  tags = {
    environment = "Production"
  }
  depends_on = [
    azurerm_linux_web_app.Service
  ]
}

resource "azurerm_route_table" "example" {
  for_each = local.All_Data
  name                = each.value.route_table_name
  location            = var.location
  resource_group_name = "${each.value.ResourceGroup}"

  depends_on = [
    azurerm_network_security_group.NSG_Global
  ]
}