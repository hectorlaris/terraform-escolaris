terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}

}

resource "azurerm_resource_group" "escterraform-rg" {
  name     = "escolaris-rg"
  location = "eastus"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "escterraform-vn" {
  name                = "escolaris-vn"
  location            = azurerm_resource_group.escterraform-rg.location
  resource_group_name = azurerm_resource_group.escterraform-rg.name
  address_space       = ["10.0.0.0/16"]


  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "escterraform-snet" {
  name                 = "escolaris-snet"
  resource_group_name  = azurerm_resource_group.escterraform-rg.name
  virtual_network_name = azurerm_virtual_network.escterraform-vn.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "escterraform-sg" {
  name                = "escolaris-sg"
  location            = azurerm_resource_group.escterraform-rg.location
  resource_group_name = azurerm_resource_group.escterraform-rg.name

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "escterraform-dev-sr" {
  name                        = "escolaris-dev-sr"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.escterraform-rg.name
  network_security_group_name = azurerm_network_security_group.escterraform-sg.name
}