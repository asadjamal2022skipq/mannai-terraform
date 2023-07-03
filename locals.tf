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