Terraform script to get WSL on Windows Server 2019 Datacenter

Terraform will create an Azure resource group, virtual network, subnet, network interface, and a Windows virtual machine. The script uses the azurerm provider to interact with Azure, and the virtual machine is deployed using the latest version of Windows Server 2019 Datacenter.

Notable Items
WinRM (Windows Remote Management) is a Windows feature that allows remote management of computers and servers over HTTP(S) protocols. It is designed for administrators who need to manage multiple Windows-based systems remotely.
"remote-exec" is a provisioner in infrastructure-as-code tools such as Terraform or Packer that allows you to execute commands or scripts on a remote resource after it has been created. This provisioner is typically used for tasks such as initializing the resource, installing software, configuring services, or deploying applications.
"additional_unattend_content" is a section in the firstlogincommand.xml file that allows you to specify additional settings and configurations to be applied during the Windows installation process. The "setting = AutoLogon" line in the "additional_unattend_content" block indicates that the firstlogincommand.xml file is being configured to enable automatic logon for the Windows operating system. This means that after the installation process is complete, the system will automatically log on to a specified user account without requiring a username or password.

To run this script, you'll need to have Terraform installed, and you'll need to authenticate to Azure using a service principal or managed identity. You can execute this script using the terraform apply command after initializing the Terraform working directory using terraform init.

#Instructions for remote client
#Authenticate Azure via az cli
https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli

#if az cli is not installed, this can be done via powershell
#windows
winget install -e --id Microsoft.AzureCLI
#linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#install terraform
https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli




