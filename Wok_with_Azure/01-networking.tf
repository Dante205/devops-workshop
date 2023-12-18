# Resource Groups
resource "azurerm_resource_group" "tf_rg_cicd" {
  name     = "rg_cicd"
  location = local.location
}

# Virtual Network
resource "azurerm_virtual_network" "tf_vnet" {
  name                = "vnet"
  location            = azurerm_resource_group.tf_rg_cicd.location
  resource_group_name = azurerm_resource_group.tf_rg_cicd.name
  address_space       = var.vnet_address
}

# Subnets
resource "azurerm_subnet" "tf_subnets" {
  for_each             = var.services
  name                 = "Subnet-${each.key}"
  resource_group_name  = azurerm_resource_group.tf_rg_cicd.name
  virtual_network_name = azurerm_virtual_network.tf_vnet.name
  address_prefixes     = [each.value.cidr_subnet]
}

# Public IP
resource "azurerm_public_ip" "tf_public_ip" {
  # for_each = { for nombre in var.recursos_para_crear : nombre => nombre if nombre != "recurso2" }  
  for_each            = { for key, value in var.services : key => value if value.public_ip == "yes" }
  name                = "public-ip-${each.key}"
  resource_group_name = azurerm_resource_group.tf_rg_cicd.name
  location            = azurerm_resource_group.tf_rg_cicd.location
  allocation_method   = "Dynamic"

}

# Network Security Group
resource "azurerm_network_security_group" "tf_nsg" {
  for_each            = var.services
  name                = "nsg-${each.key}"
  location            = azurerm_resource_group.tf_rg_cicd.location
  resource_group_name = azurerm_resource_group.tf_rg_cicd.name
  # Iterate each.value.nsg_rules to get each rules for respective nsg
  # Also, validate if nsg_rules is an empty list befor to add rules.
  dynamic "security_rule" {
    for_each = { for key, value in each.value.nsg_rules : key => value if length(value) > 0 }
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}
