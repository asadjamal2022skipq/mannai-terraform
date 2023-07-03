locals {

  instances = csvdecode(file("${path.module}/test.csv"))
    All_Data= {
        for i in local.instances : i.no => {
            app_service_name = i.app_service_name
            Environement = i.env_name
            ResourceGroup = i.Rgname_name
            Locations = i.Locations
            App_Service_Plan = i.app_service_plan_name
           
            /* V_netName_name = i.vnet_name */
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
    for i in local.instances : "${i.vnet_name}" => {
      resource_group = i.Rgname_name
      address_space  = i.address_space
      subnet_name = i.subnet_name
      subnet_address_prefix = i.subnet_address_prefix

    }...
  }
  vnet_data = {
    for k, v in local.vnet_data_group_by : k => distinct(v)
  }

  /* vnet_name = distinct([for x in local.All_Data : x.V_netName_name]) */

  rg_data = distinct(local.instances.*.Rgname_name)
  
  /* vnet_data = zipmap(local.instances.*.vnet_name,local.instances.*.address_space) */


  /* vnet_data2 = zipmap(local.instances.*.vnet_name,local.instances.*.address_space) */

  /* vnet_data2 = flatten({
    for i in local.instances : [
      /* address_space = i.address_space */
      /* for k, v in vnet_data : k => {
        resource_group = i.Rgname_name
        address_space = v
      }
    ]
  }) */

  /* vnet_data = {
    for i in local.instances : i.no => [
      for v, k in local.vnet_data2: {
      resource_group = i.Rgname_name
      address_space = v
      } 
      if i.vnet_name != v
    ] 
 } */

  /* rg_data = distinct([for x in local.All_Data : x.ResourceGroup])
  service_name_data = distinct([for x in local.All_Data : x.app_service_name]) */


 /* list_vnet_without_duplicates = distinct([for s in local.instances : s.vnet_name =>
        {
            address_space = s.address_space
            resource_group = s.Rgname_name
            subnet_name = s.subnet_name
            subnet_address_prefix = s.subnet_address_prefix
          }
        ]) */
}




resource "azurerm_resource_group" "RGroups" {
  for_each = local.All_Data
  name     = each.value.ResourceGroup
  location = var.location
}

resource "azurerm_virtual_network" "Azure_vnet" {
  for_each = local.vnet_data
  name                = each.key
  address_space       = [each.value.address_space]
  location            = var.location
  resource_group_name = each.value.resource_group
}

/* resource "azurerm_subnet" "Subnet-main" {
  for_each = local.All_Data
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
  for_each = local.All_Data
  name                = each.value.App_Service_Plan
  resource_group_name = each.value.ResourceGroup
  location            = each.value.Locations
  os_type             = each.value.os_type
  sku_name            = each.value.sku_name
}

resource "azurerm_linux_web_app" "Service" {
  for_each = local.All_Data
  name                = each.value.app_service_name
  resource_group_name = each.value.ResourceGroup
  location            = each.value.Locations
  service_plan_id     = azurerm_service_plan.ServicePlan[each.key].id
  virtual_network_subnet_id = azurerm_subnet.Subnet-main[each.key].id
  site_config {}
}

resource "azurerm_network_security_group" "NSG_Global" {
for_each = local.All_Data
  name                = each.value.V_net_NSG_Name
  location            = each.value.Locations
  resource_group_name = each.value.ResourceGroup

  tags = {
    environment = "Production"
  }
} */