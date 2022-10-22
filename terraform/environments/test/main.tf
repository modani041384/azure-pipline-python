terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
	    version = "3.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "test" {
  name     = "resources-tf-2022"
  location = "eastus"
}

resource "azurerm_virtual_network" "test" {
  name                 = "${var.application_type}"
  address_space       = ["10.0.0.0/16"]
  location             = "eastus"
  resource_group_name  = "resources-tf-2022"
}

resource "azurerm_subnet" "test" {
  name                 = "${var.application_type}-sub"
  resource_group_name  = "resources-tf-2022"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.application_type}"
  location             = "eastus"
  resource_group_name  = "resources-tf-2022"

  security_rule {
    name                       = "${var.application_type}-5000"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_subnet_network_security_group_association" "test" {
    subnet_id                 = azurerm_subnet.test.id
    network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_service_plan" "test" {
  name                = "${var.application_type}"
  location             = "eastus"
  resource_group_name  = "resources-tf-2022"
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "test" {
  name                = "${var.application_type}"
  location             = "eastus"
  resource_group_name  = "resources-tf-2022"
  service_plan_id     = azurerm_service_plan.test.id

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = 0
  }
  site_config {
    always_on = false
  }
}

resource "azurerm_public_ip" "test" {
  name                = "${var.application_type}-pubip"
  location            = "eastus"
  resource_group_name = "resources-tf-2022"
  allocation_method   = "Dynamic"
}

# create vm
resource "azurerm_network_interface" "test" {
  name                = "network-net"
  location            = "eastus"
  resource_group_name = "resources-tf-2022"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 2046
}

resource "azurerm_linux_virtual_machine" "test" {
  name                = "myApplicationVM2022"
  location            = "eastus"
  resource_group_name = "resources-tf-2022"
  size                = "Standard_DS2_v2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!$"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.test.id,
  ]
  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }
  os_disk {
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
