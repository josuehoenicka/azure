#!/bin/bash

# Crear un grupo de recursos
az group create --name grupoRecursosPublicos --location "eastus2"

# Crea una red virtual
az network vnet create --resource-group grupoRecursosPublicos --name redVirtual --address-prefix 10.10.0.0/16 --subnet-name WebSubnet --subnet-prefix 10.10.0.0/24

# Crea una ip pública
az network public-ip create --resource-group grupoRecursosPublicos --name publicIP

#Crea un NSG
az network nsg create --resource-group grupoRecursosPublicos --name nsg

az network nsg rule create --resource-group grupoRecursosPublicos --nsg-name nsg --name allowRDP --protocol tcp --priority 1000 --destination-port-range 3389
az network nsg rule create --resource-group grupoRecursosPublicos --nsg-name nsg --name allowHTTP --protocol tcp --priority 1001 --destination-port-range 80
az network nsg rule create --resource-group grupoRecursosPublicos --nsg-name nsg --name allowHTTPS --protocol tcp --priority 1002 --destination-port-range 443

# Crea una asociación de red
az network vnet subnet update --vnet-name redVirtual --name WebSubnet --resource-group grupoRecursosPublicos --network-security-group nsg

# Crea una máquina virtual con Windows Server 2019
az vm create --resource-group grupoRecursosPublicos --name webServerVirt --image Win2019Datacenter --admin-username aminespinoza --admin-password Am0_Apr3nd3r$ --vnet-name redVirtual --subnet WebSubnet --public-ip-address publicIP --nsg nsg

az vm open-port -g grupoRecursosPublicos -n webServerVirt --port 80,443,3389 --priority 100
# Instala IIS en la máquina virtual
az vm extension set --resource-group grupoRecursosPublicos --vm-name webServerVirt --name customScriptExtension --publisher Microsoft.Compute --settings '{"commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"}'

