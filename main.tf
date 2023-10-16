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

# 1. Create resource -group
resource "azurerm_resource_group" "escterraform-rg" {
  name     = "escolaris-rg"
  location = "eastus"
  tags = {
    environment = "dev"
  }
}

# 2. Create VN
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway

resource "azurerm_virtual_network" "escterraform-vn" {
  name                = "escolaris-vn"
  location            = azurerm_resource_group.escterraform-rg.location
  resource_group_name = azurerm_resource_group.escterraform-rg.name
  address_space       = ["10.0.0.0/16"]


  tags = {
    environment = "dev"
  }
}

# 3. Create subnet
resource "azurerm_subnet" "escterraform-snet" {
  name                 = "escolaris-snet"
  resource_group_name  = azurerm_resource_group.escterraform-rg.name
  virtual_network_name = azurerm_virtual_network.escterraform-vn.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 4. Create security-group 
resource "azurerm_network_security_group" "escterraform-sg" {
  name                = "escolaris-sg"
  location            = azurerm_resource_group.escterraform-rg.location
  resource_group_name = azurerm_resource_group.escterraform-rg.name

  tags = {
    environment = "dev"
  }
}

# 5. Create network security rule
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

#6.  We´re going to associate sn with sg 
# azurerm_subnet_network_security_group_association
resource "azurerm_subnet_network_security_group_association" "escterraform-asoc-sn-se" {
  subnet_id                 = azurerm_subnet.escterraform-snet.id
  network_security_group_id = azurerm_network_security_group.escterraform-sg.id
}

#7.  We´re going to give to my future VM away to the internet by creating a public IP: 
#  azurerm_public_ip
resource "azurerm_public_ip" "escterrafor-ip" {
  name                = "escolaris-pu-ip"
  resource_group_name = azurerm_resource_group.escterraform-rg.name
  location            = azurerm_resource_group.escterraform-rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

# 8. Creating a network interface (NIC) enables an Azure virtual machine (VM) to communicate with 
#internet, Azure, and on-premises resources. Using azurerm_network_interface

resource "azurerm_network_interface" "escterrafor-nic" {
  name                = "escolaris-nic"
  location            = azurerm_resource_group.escterraform-rg.location
  resource_group_name = azurerm_resource_group.escterraform-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.escterraform-snet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.escterrafor-ip.id
  }

  tags = {
    environment = "dev"
  }
}

# 9. Create admin SSH key pair for the Linux VM to be created next
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine_scale_set
# desde terminal ejecutar:
# ssh-keygen -t rsa


# 10, Create Linux VM
resource "azurerm_linux_virtual_machine" "escterrafor-vm" {
  name                  = "escolaris-vmss"
  resource_group_name   = azurerm_resource_group.escterraform-rg.name
  location              = azurerm_resource_group.escterraform-rg.location
  size                   = "Standard_B1s"
  admin_username        = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.escterrafor-nic.id,
  ]

  admin_ssh_key {
    username = "adminuser"
    // se usa una function terraform par aleer el archivo
    public_key = file("~/.ssh/escterraformkey.pub")
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = {
    environment = "dev"
  }

}