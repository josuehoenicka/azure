#!/bin/bash

# Crear un grupo de recursos
az group create -l eastus2 -n GrupoRecursosIaaS

# Crear una máquina virtual
az vm create -n iaas-vm-amin -g GrupoRecursosIaaS --image Ubuntu2204 --admin-username aminespinoza --admin-password Am0_Apr3nd3r$

# Crear una cuenta de almacenamiento básica
az storage account create -n storageiaas004 -g GrupoRecursosIaaS -l eastus2 --sku Standard_LRS

# Crear una red virtual
az network vnet create -g GrupoRecursosIaaS -n IaaSVnet004 --address-prefix 10.0.0.0/16 --subnet-name aminesSubnet --subnet-prefixes 10.0.0.0/24

#Eliminar todos los recursos creados
az group delete -n GrupoRecursosIaaS --force-deletion-types Microsoft.Compute/virtualMachines

