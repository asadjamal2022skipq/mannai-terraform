# Locals containing of all data filtering
locals {  
# Pulling data from CSV file and Decoding
  linux_csv = csvdecode(file("${path.module}/linux_app.csv"))
  windows_csv = csvdecode(file("${path.module}/windows_app.csv"))

# Extracting all Data from Both CSV Files
  windows_data_all = {
    for i in local.windows_csv : i.sl_no => {
      app_service_name = i.app_service_name
      environment = i.environment
      resource_group = i.resource_group
      app_service_plan_name = i.app_service_plan_name
      app_service_name = i.app_service_name
      vnet_name = i.vnet_name
      address_space = i.address_space
      subnet_name = i.subnet_name
      subnet_address_prefix = i.subnet_address_prefix
      nsg_name = i.nsg_name
      route_table_name = i.route_table_name
      sku_name = i.sku_name
      os_type = i.os_type
      version_stack = i.version_stack
      application_stack = i.application_stack
    }
  }
  
  linux_data_all = {
    for i in local.linux_csv : i.sl_no => {
      app_service_name = i.app_service_name
      environment = i.environment
      resource_group = i.resource_group
      app_service_plan_name = i.app_service_plan_name
      app_service_name = i.app_service_name
      vnet_name = i.vnet_name
      address_space = i.address_space
      subnet_name = i.subnet_name
      subnet_address_prefix = i.subnet_address_prefix
      nsg_name = i.nsg_name
      route_table_name = i.route_table_name
      sku_name = i.sku_name
      os_type = i.os_type
      version_stack = i.version_stack
      application_stack = i.application_stack
    }
  }

  # Generating a map of objects with selected CSV data
  windows_data = {
    for i in local.windows_csv : i.sl_no => {
      app_service_name = i.app_service_name
      environment = i.environment
      resource_group = i.resource_group
      app_service_plan_name = i.app_service_plan_name
      vnet_name = i.vnet_name
      address_space = i.address_space
      subnet_name = i.subnet_name
      subnet_address_prefix = i.subnet_address_prefix
      nsg_name = i.nsg_name
      route_table_name = i.route_table_name
      sku_name = i.sku_name
      os_type = i.os_type
      version_stack = i.version_stack
      application_stack = i.application_stack
    }
  }

  all_data = tomap(
    zipmap(
      concat(
        [for k, _ in local.windows_data : tostring(k)],
        [for i, _ in local.linux_csv : tostring(length(local.windows_data) + i)]
      ),
      concat(
        [for v in values(local.windows_data) : v],
        [for i in local.linux_csv : {
          app_service_name = i.app_service_name
          environment = i.environment
          resource_group = i.resource_group
          app_service_plan_name = i.app_service_plan_name
          vnet_name = i.vnet_name
          address_space = i.address_space
          subnet_name = i.subnet_name
          subnet_address_prefix = i.subnet_address_prefix
          nsg_name = i.nsg_name
          route_table_name = i.route_table_name
          sku_name = i.sku_name
          os_type = i.os_type
          version_stack = i.version_stack
          application_stack = i.application_stack
        }]
      )
    )
  )

# Creating a list with all unique Resource Group Names from CSV file
  all_resource_groups = [for item in local.all_data : item.resource_group]
  rgname_unique       = distinct(local.all_resource_groups)


  linux_app_stack_unique = distinct(local.linux_csv.*.application_stack)
  windows_app_stack_unique = distinct(local.windows_csv.*.application_stack)

# Create a list of objects with Virtual Network Names as Key
  vnet_data_group_by = {
    for i in local.all_data : i.vnet_name => {
      resource_group        = i.resource_group
      address_space         = i.address_space
      subnet_name           = i.subnet_name
      subnet_address_prefix = i.subnet_address_prefix
      nsg_name              = i.nsg_name
    }...
  }

  vnet_data = {
    for k, v in local.vnet_data_group_by : k => distinct(v)
  }

  linux_app_service_plan_group_by = {
    for i in local.linux_csv : i.app_service_plan_name => {
      resource_group_name = i.resource_group
      os_type           = i.os_type
      sku_name          = i.sku_name
    }...
  }
  linux_app_service_plan_data = {
    for k, v in local.linux_app_service_plan_group_by : k => distinct(v)
  }

  windows_app_service_plan_group_by = {
    for i in local.windows_data : i.app_service_plan_name => {
      resource_group_name = i.resource_group
      os_type           = i.os_type
      sku_name          = i.sku_name
    }...
  }
  windows_app_service_plan_data = {
    for k, v in local.windows_app_service_plan_group_by : k => distinct(v)
  }
}

# Resource Deployment Configuration
# Resource Group
resource "azurerm_resource_group" "RGroups" {
  for_each = toset(local.rgname_unique)
  name     = each.value
  location = var.location
}


# Virtual Network
resource "azurerm_virtual_network" "Azure_vnet" {
  for_each            = local.vnet_data
  name                = each.key
  address_space       = [each.value[0].address_space]
  resource_group_name = each.value[0].resource_group
  location            = var.location
  depends_on = [
    azurerm_resource_group.RGroups
  ]
}

# Subnet
resource "azurerm_subnet" "Subnet-main" {
  for_each             = local.all_data
  name                 = each.value.subnet_name
  resource_group_name  = each.value.resource_group
  virtual_network_name = each.value.vnet_name
  address_prefixes     = [each.value.subnet_address_prefix]

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


# App Service Plans
resource "azurerm_service_plan" "linuxserviceplan" {
  for_each            = local.linux_app_service_plan_data
  name                = each.key
  resource_group_name = each.value[0].resource_group_name
  location            = var.location
  os_type             = each.value[0].os_type
  sku_name            = each.value[0].sku_name
  depends_on = [
    azurerm_virtual_network.Azure_vnet
  ]
}

# Windows App Service Plan
resource "azurerm_service_plan" "windowsserviceplan" {
  for_each            = local.windows_app_service_plan_data
  name                = each.key
  resource_group_name = each.value[0].resource_group_name
  location            = var.location
  os_type             = each.value[0].os_type
  sku_name            = each.value[0].sku_name

  depends_on = [
    azurerm_virtual_network.Azure_vnet
  ]
}

# Linux App Service
resource "azurerm_linux_web_app" "linux_app" {
  for_each                  = local.linux_data_all
  name                      = each.value.app_service_name
  resource_group_name       = each.value.resource_group
  location                  = var.location
  service_plan_id           = azurerm_service_plan.linuxserviceplan[each.value.app_service_plan_name].id
  virtual_network_subnet_id = azurerm_subnet.Subnet-main[each.key].id

  site_config {
  dynamic "application_stack"  {
    for_each = toset(local.linux_app_stack_unique) == "dotnet" ? [""] : []
      content {
       dotnet_version = "${each.value.version_stack}"
      }
    }
  }
  depends_on = [
    azurerm_service_plan.linuxserviceplan
  ]
}

# Windows App Service
resource "azurerm_windows_web_app" "windows_app" {
  for_each = local.windows_data_all
  name                = each.value.app_service_name
  resource_group_name = each.value.resource_group
  location            = var.location
  service_plan_id           = azurerm_service_plan.windowsserviceplan[each.value.app_service_plan_name].id
  virtual_network_subnet_id = azurerm_subnet.Subnet-main[each.key].id

    site_config {
  dynamic "application_stack"  {
    for_each = toset(local.linux_app_stack_unique) == "dotnet" ? [""] : []
      content {
       dotnet_version = "${each.value.version_stack}"
      }
    }
  }
  depends_on = [
    azurerm_service_plan.windowsserviceplan
  ]
}


# Azure Network Security Group
resource "azurerm_network_security_group" "nsg" {
  for_each            = local.all_data
  name                = each.value.nsg_name
  location            = var.location
  resource_group_name = each.value.resource_group

  tags = {
    environment = "Production"
  }
  depends_on = [
    azurerm_windows_web_app.windows_app
  ]
}

# Azure Route Tables
resource "azurerm_route_table" "route_table" {
  for_each            = local.all_data
  name                = each.value.route_table_name
  location            = var.location
  resource_group_name = each.value.resource_group

  depends_on = [
    azurerm_network_security_group.nsg
  ]
}