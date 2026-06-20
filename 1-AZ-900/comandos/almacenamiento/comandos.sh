#!/bin/bash

# Crear un grupo de recursos
az group create --name grupoAlmacenamiento --location "eastus2"

# Crea una cuenta de almacenamiento
az storage account create --name almacenamientoap --resource-group grupoAlmacenamiento --location eastus2 --sku Standard_LRS

AZURE_STORAGE_KEY=$(az storage account keys list --account-name almacenamientoap --resource-group grupoAlmacenamiento --query "[0].value" --output tsv)

# Crea un contenedor en la cuenta de almacenamiento
az storage container create --name amin --account-name almacenamientoap --account-key $AZURE_STORAGE_KEY
az storage container create --name oscar --account-name almacenamientoap --account-key $AZURE_STORAGE_KEY
az storage container create --name felipe --account-name almacenamientoap --account-key $AZURE_STORAGE_KEY

# Sube un archivo al contenedor
az storage blob upload --container-name amin --file ./comandos.sh --name comandos.sh --account-name almacenamientoap