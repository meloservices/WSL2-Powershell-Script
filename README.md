# WSL2-Powershell-Script

#This can be used to deploy WSL2 via Terraform

# Virtual Machine Extension to Install IIS
resource "azurerm_virtual_machine_extension" "software" {
  name                 = "install-software"
  resource_group_name  = azurerm_resource_group.azrg.name
  virtual_machine_id   = azurerm_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<SETTINGS
  {
    "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.tf.rendered)}')) | Out-File -filepath wsl_install.ps1\" && powershell -ExecutionPolicy Unrestricted -File wsl_install.ps1"
  }
  SETTINGS
}

data "template_file" "tf" {
    template = "${file("wsl_install.ps1")}"
} 

# STEP 1: Enable Virtual Machine Platform feature
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# STEP 2: Enable WSL feature
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# STEP 3: To set the WSL default version to 2.
wsl --set-default-version 2

# STEP 4: Install Distro
wsl --install -d kali-linux
