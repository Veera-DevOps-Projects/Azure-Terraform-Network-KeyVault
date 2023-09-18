locals {
  owners      = var.business_department
  environment = var.environment
  #   deployment_date = var.deployment_date
  resource_name_prefix = "${var.business_department}-${var.environment}"
  common_tags = {
    owners      = local.owners
    environment = local.environment
    deployment  = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
  }
}

# Random String Resource
resource "random_string" "demorandom" {
  length  = 6
  upper   = false
  special = false
  numeric = false
}

# Resource-1: Azure Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${local.resource_name_prefix}-${var.resource_group_name}-${random_string.demorandom.id}"
  location = var.resource_group_location
  tags     = local.common_tags
}

module "virtual-network" {
  source = "./modules/virtual-network"

  vnet_name            = var.vnet_name
  vnet_address_space   = var.vnet_address_space
  resource_name_prefix = local.resource_name_prefix
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  tags                 = local.common_tags
}

module "subnets" {
  source   = "./modules/subnets"
  for_each = { for each in var.subnets : each.name => each }

  vnet_name           = module.virtual-network.vnet_name
  subnet_name         = each.value.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_address      = each.value.address
  inbound_ports_map   = each.value.ports
}

# resource group #

# Create a resource group for better management
data "azurerm_resource_group" "security-rg" {
  name     = "security-${var.environment}-rg"
  # location = var.location
}

# key vault #

module "keyvault" {
  source              = "./modules/keyvault"
  name                = "${var.environment}-keyvault-26052022"
  location            = data.azurerm_resource_group.security-rg.location
  resource_group_name = data.azurerm_resource_group.security-rg.name
  
  enabled_for_deployment          = var.kv-vm-deployment
  enabled_for_disk_encryption     = var.kv-disk-encryption
  enabled_for_template_deployment = var.kv-template-deployment
  
  tags = {
    environment = "${var.environment}"
  }

  policies = {
    full = {
      tenant_id               = var.azure-tenant-id
      object_id               = var.kv-full-object-id
      key_permissions         = var.full-key-permissions
      secret_permissions      = var.full-secret-permissions
      certificate_permissions = var.full-certificate-permissions
      storage_permissions     = var.full-storage-permissions
    }
    read = {
      tenant_id               = var.azure-tenant-id
      object_id               = var.kv-read-object-id
      key_permissions         = var.readonly-key-permissions
      secret_permissions      = var.readonly-secret-permissions
      certificate_permissions = var.readonly-certificate-permissions
      storage_permissions     = var.readonly-storage-permissions
    }
  }

  secrets = var.kv-secrets
}