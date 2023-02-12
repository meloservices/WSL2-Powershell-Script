

locals {
    wsl-location       = "eastus"
    wsl-resource-group = "azure-wsl-vnet-rg"
    prefix-wsl         = "azure-wsl"
}

resource "azurerm_resource_group" "azure-wsl-vnet-rg" {
  name     = local.wsl-resource-group
  location = local.wsl-location
}

resource "azurerm_virtual_network" "azure-wsl-vnet" {
  name                = "azure_wsl_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.azure-wsl-vnet-rg.location
  resource_group_name = azurerm_resource_group.azure-wsl-vnet-rg.name
}

resource "azurerm_subnet" "win10-wsl-subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.azure-wsl-vnet-rg.name
  virtual_network_name = azurerm_virtual_network.azure-wsl-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "win10-wsl-nic" {
  name                = "win10_wsl_nic"
  location            = azurerm_resource_group.azure-wsl-vnet-rg.location
  resource_group_name = azurerm_resource_group.azure-wsl-vnet-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.win10-wsl-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create Windows 10 Virtual Machine
resource "azurerm_windows_virtual_machine" "windows-10-vm" {
  name                  = "windows-10-vm"
  location              = azurerm_resource_group.azure-wsl-vnet-rg.location
  resource_group_name   = azurerm_resource_group.azure-wsl-vnet-rg.name
  size                  = "Standard_DS3_v2"
  network_interface_ids = [azurerm_network_interface.win10-wsl-nic.id]
  
  computer_name         ="windows-10-vm"
  admin_username        = "useradmin"
  admin_password        = "S3c43T!p@3"
  os_disk {
    name                 = "windows-10-vm-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-10"
    sku       = "19h2-pro-g2"
    version   = "latest"
  }
  enable_automatic_updates = true
  provision_vm_agent       = true
  tags = {
    application = "wsl"
    environment = "wsl"
  }
}

resource "azurerm_virtual_machine_extension" "software" { 
	name = "install-software" 
	resource_group_name = azurerm_resource_group.azure-wsl-vnet-rg.name 
	virtual_machine_id = azurerm_virtual_machine.windows-10-vm.id 
	publisher = "Microsoft.Compute" 
	type = "CustomScriptExtension" 
	type_handler_version = "1.10"

settings = <<SETTINGS {
	"fileUris": [
	"https://raw.githubusercontent.com/meloservices/WSL2-Powershell-Script/main/wsl_install.ps1"
	], 
	"commandToExecute": "powershell -ExecutionPolicy Unrestricted -File wsl_install.ps1" 
		} 
	SETTINGS
	}


	
# Create Network Security Group to Access web VM from Internet
resource "azurerm_network_security_group" "windows-vm-nsg" {
  name = "windows-vm-nsg"
  location            = azurerm_resource_group.azure-wsl-vnet-rg.location
  resource_group_name = azurerm_resource_group.azure-wsl-vnet-rg.name
  security_rule {
    name                       = "allow-rdp"
    description                = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*" 
  }
  security_rule {
    name                       = "allow-http"
    description                = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  tags = {
    application = "wsl"
    environment = "wsl"
  }
}
