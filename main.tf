terraform {
  backend "azurerm" {
    resource_group_name   = "terraform-iac-test"
    storage_account_name  = "terraformiacstatesa"
    container_name        = "tstate"
    key                   = "ThcvT/yKp6BU9oHQ0S/ZbFBYs9EOcl6p8agyS67P55Lknf5rw0u6OsuAPn6mcdzOVk8sq7yme2jeduGQ9T2QWQ=="
}

  required_providers {
    azurerm = {
      # Specify what version of the provider we are going to utilise
      source = "hashicorp/azurerm"
      version = ">= 2.4.1"
    }
  }
}
provider "azurerm" {
  features {
      key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
data "azurerm_client_config" "current" {}
# Create our Resource Group - Jonnychipz-RG
resource "azurerm_resource_group" "rg" {
  name     = "terraform-iac-app01"
  location = "southeastasia"
}
# Create our Virtual Network - Jonnychipz-VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "terraform-iac-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Create our Subnet to hold our VM - Virtual Machines
resource "azurerm_subnet" "sn" {
  name                 = "terraform-iac-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = ["10.0.1.0/24"]
}
# Create our Azure Storage Account - jonnychipzsa
resource "azurerm_storage_account" "terraformiacvmsa" {
  name                     = "terraformiacvmsa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "terraform-iac-env1"
  }
}
# Create our vNIC for our VM and assign it to our Virtual Machines Subnet
resource "azurerm_network_interface" "vmnic" {
  name                = "terraformiacvmnic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
 
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create our Virtual Machine - Jonnychipz-VM01
resource "azurerm_virtual_machine" "terraform-iac-vm01" {
  name                  = "terraform-iac-vm01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vmnic.id]
  vm_size               = "Standard_B2s"
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }
  storage_os_disk {
    name              = "terraform-iac-vm01-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name      = "terraform-iac-vm01"
    admin_username     = "demoadmin"
    admin_password     = "Password123$"
  }
  os_profile_windows_config {
  }
}
