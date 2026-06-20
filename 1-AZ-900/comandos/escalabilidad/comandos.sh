#!/bin/bash

# Crear un grupo de recursos
az group create -l eastus2 -n GrupoRecursosEscalables

# Crear un plan de servicio
az appservice plan create -g GrupoRecursosEscalables -n aminWebEscalable

# Crear una aplicación web
az webapp create -g GrupoRecursosEscalables -p aminWebEscalable -n aminespinozaweb

# Eliminar todos los recursos creados
az group delete -n GrupoRecursosEscalables