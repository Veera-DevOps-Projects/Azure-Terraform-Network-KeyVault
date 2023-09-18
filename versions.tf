terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.34.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-dev"
    storage_account_name = "storagedev19112022"
    container_name       = "tfstate-bc"
    key                  = "infra/terraform.tfstate"
  }
}

# configure the azure provider
provider "azurerm" { 
#   environment     = "public"
  subscription_id = var.azure-subscription-id
  client_id       = var.azure-client-id
  client_secret   = var.azure-client-secret
  tenant_id       = var.azure-tenant-id
  skip_provider_registration = true
  features {}
}