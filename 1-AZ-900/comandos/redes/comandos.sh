#!/bin/bash

# Crear un grupo de recursos
az group create --name grupoRecursosRedes --location "East US"

# Crea una zona DNS
az network dns zone create -g grupoRecursosRedes -n platzi.xyz

# Crea un registro A en la zona DNS
az network dns record-set a add-record -g grupoRecursosRedes -z platzi.xyz -n www -a 10.10.10.10

# Crea un lista de registros en la zona DNS
az network dns record-set list -g grupoRecursosRedes -z platzi.xyz

# Crea un registro NS en la zona DNS
az network dns record-set ns show --resource-group grupoRecursosRedes --zone-name platzi.xyz --name @




