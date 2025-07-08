#Hello Mansoor
#Hello World2

resource "azurerm_resource_group" "rg1" {
  name     = var.rg_name
  location = var.rg_location
}

data "azurerm_resource_group" "rg" {
  name = var.rg_name

}

resource "azurerm_virtual_network" "vnetmq" {
  name                = var.vnetmq_name
  location            = var.vnetmq_location
  resource_group_name = var.rg_name
  address_space       = var.address_space
}

resource "azurerm_subnet" "frontend_subnet" {
  name                 = "frontend_subnet"
  resource_group_name  = var.rg_name
  virtual_network_name = var.vnetmq_name
  address_prefixes     = var.address_prefixes

}

# Data sources to get the existing vnet
# This assumes the VNET is already created in the specified resource group.
# If the VNET does not exist, you will need to create it first.

data "azurerm_virtual_network" "vnet" {
  name                = var.vnetmq_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Data source to get the existing subnet
# This assumes the subnet is already created in the specified VNET
# If the subnet does not exist, you will need to create it first.


data "azurerm_subnet" "subnet" {
  name                 = "frontend_subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}


#Create a new NIC using exiting VNET & Subnet
# This NIC will be used to attach to the VM
# Ensure that the subnet and VNET names match those in your existing setup.
# If the VNET or subnet does not exist, you will need to create them first.

resource "azurerm_network_interface" "nic" {
  name                = "nic_mq"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "frontend_pip" {
  name                = "pip_mq"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  allocation_method   = "Static"

}

data "azurerm_public_ip" "public_ip" {
depends_on          = [azurerm_public_ip.frontend_pip]
  name                = "pip_mq"
  resource_group_name = data.azurerm_resource_group.rg.name
}

#Deploy a sample Linux VM
resource "azurerm_linux_virtual_machine" "vm" {
  depends_on                      = [azurerm_network_interface.nic, azurerm_public_ip.frontend_pip]
  name                            = "vm_mq"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  size                            = "Standard_B1s"
  admin_username                  = "adminuser"
  admin_password                  = "S@nDb0x*2205"
  disable_password_authentication = false
  computer_name                   = "vm-mq"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
  
 
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}


