#!/bin/bash

# Crear un grupo de recursos
az group create -l eastus2 -n GrupoRecursosCLI

# Crear una cuenta de almacenamiento básica
az storage account create -n cuentacliamin001 -g GrupoRecursosCLI -l eastus2 --sku Standard_LRS

