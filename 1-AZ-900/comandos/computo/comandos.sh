#!/bin/bash

# Crear un grupo de recursos
az group create --name grupoRecursosComputo --location eastus2

# Crear una máquina virtual
az vm create -n compute-vm-amin -g grupoRecursosComputo --image Ubuntu2204 --admin-username aminespinoza --admin-password Am0_Apr3nd3r$

# Crear una container app
az containerapp env create -n ComputoEnvironment -g grupoRecursosComputo --location eastus2
az containerapp create -n computocontainerapp -g grupoRecursosComputo --image docker.io/aminespinoza/linktree:latest --environment ComputoEnvironment --ingress external --target-port 80

# Crear una Function App
az storage account create --name almacenamientofuncion52 --location eastus2 --resource-group grupoRecursosComputo --sku Standard_LRS
az functionapp create --resource-group grupoRecursosComputo --consumption-plan-location eastus2 --name function-app-amin --storage-account almacenamientofuncion52 --runtime dotnet

