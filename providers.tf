terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.62.1"
    }
  }
}

provider "azurerm" {
    features {
      resource_group{
    prevent_deletion_if_contains_resources = false
      }
    }
  # Configuration options

}