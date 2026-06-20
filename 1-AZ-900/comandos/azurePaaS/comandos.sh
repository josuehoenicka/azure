#!/bin/bash

# Crear un grupo de recursos
az group create -l eastus2 -n GrupoRecursosPaaS

# Crear una base de datos de Cosmos DB
az cosmosdb create --name cosmospaas123 --resource-group GrupoRecursosPaaS

# Desplegar un servidor de SQL
az sql server create -l eastus2 -g GrupoRecursosPaaS -n serverPaas006 -u aminespinoza -p Am0_Apr3nd3r$

# Crear una web app (junto con un plan de servicio)
az appservice plan create -g GrupoRecursosPaaS -n aminWebPlan

az webapp create -g GrupoRecursosPaaS -p aminWebPlan -n aminespinozaweb

#Eliminar todos los recursos creados
az group delete -n GrupoRecursosPaaS