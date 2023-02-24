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

resource "azurerm_public_ip" "windows_pip" {
  name                = "windows-pip"
  location            = azurerm_resource_group.azure-wsl-vnet-rg.location
  resource_group_name = azurerm_resource_group.azure-wsl-vnet-rg.name
  allocation_method   = "Static"
}

resource "azurerm_subnet" "win-wsl-subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.azure-wsl-vnet-rg.name
  virtual_network_name = azurerm_virtual_network.azure-wsl-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "win-wsl-nic" {
  name                = "win_wsl_nic"
  location            = azurerm_resource_group.azure-wsl-vnet-rg.location
  resource_group_name = azurerm_resource_group.azure-wsl-vnet-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.win-wsl-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.windows_pip.id
  }
}


resource "azurerm_network_security_group" "windows-nsg" {
  name                = "windows-vm-nsg"
  location            = azurerm_resource_group.azure-wsl-vnet-rg.location
  resource_group_name = azurerm_resource_group.azure-wsl-vnet-rg.name
  security_rule {
    name                       = "allow-rdp"
    description                = "allow-rdp"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-http"
    description                = "allow-http"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
 security_rule {
    name                       = "WinRM"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    application = "wsl"
    environment = "wsl"
  }
}

resource "azurerm_subnet_network_security_group_association" "windows-nsg" {  
  subnet_id                 = azurerm_subnet.win-wsl-subnet.id
  network_security_group_id = azurerm_network_security_group.windows-nsg.id
}

# Create Windows 10 Virtual Machine
resource "azurerm_windows_virtual_machine" "windows-vm" {
  name                  = "windows-vm"
  location              = azurerm_resource_group.azure-wsl-vnet-rg.location
  resource_group_name   = azurerm_resource_group.azure-wsl-vnet-rg.name
  size                  = "Standard_DS3_v2"
  network_interface_ids = [azurerm_network_interface.win-wsl-nic.id]

  #variables
   custom_data = "${filebase64("C:/Users/dufre/Desktop/windows-vm/script.ps1")}"
   winrm_listener {
	protocol = "Http"
	}

  computer_name  = "windows-vm"
  admin_username = var.username
  admin_password = var.password
  os_disk {
    name                 = "windows-vm-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }



  additional_unattend_content {
      setting      = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${var.password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.username}</Username></AutoLogon>"
  }
  additional_unattend_content {
      setting      = "FirstLogonCommands"
      content      = "${file("C:/Users/dufre/Desktop/windows-vm/firstlogincommand.xml")}"
  }

  enable_automatic_updates = true
  provision_vm_agent       = true
  tags = {
    application = "wsl"
    environment = "wsl"
  }

   provisioner "remote-exec" {
   connection {
        host = azurerm_public_ip.windows_pip.ip_address
        type = "winrm"
        port = 5985
        https = false
        timeout = "4m"
	agent = false
	insecure = true
        user    = var.username
        password = var.password
    }
        inline = ["powershell.exe -ExecutionPolicy Unrestricted -Command {Install-WindowsFeature -name Web-Server - IncludeManagementTools}",]
    }
}
