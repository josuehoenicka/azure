#!/bin/bash

# Crear un grupo de recursos
az group create -l eastus2 -n GrupoRecursosSeguros

# Crear una cuenta de almacenamiento básica
az storage account create -n storageiaas004 -g GrupoRecursosSeguros -l eastus2 --sku Standard_LRS

# Crear una cuenta de almacenamiento segura
az storage account create -n storageiaas005 -g GrupoRecursosSeguros -l eastus2 --sku Standard_LRS --https-only true --allow-blob-public-access false --allow-shared-key-access false --min-tls-version TLS1_2 --public-network-access disabled