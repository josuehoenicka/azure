#!/bin/bash

# IMPORTANTE (SEGURIDAD): este script usa PLACEHOLDERS.
# Reemplaza <ID_SUSCRIPCION>, <APP_ID>, <SECRETO> y <ID_TENANT> por tus valores.
# NUNCA subas secretos reales a git. Prefiere identidades administradas (managed identities).

# Agrega un rol de contribuidor a nivel de toda la suscripción
az ad sp create-for-rbac -n ContribuidoresGlobales --role Contributor --scopes /subscriptions/<ID_SUSCRIPCION>

# Crea dos grupos de recursos
az group create -l eastus2 -n GrupoRecursosContribuidores
az group create -l eastus2 -n GrupoRecursosLectores

# Asigna un rol de contribuidor acotado a un grupo de recursos
az ad sp create-for-rbac -n ContribuidoresGrupales --role Contributor --scopes /subscriptions/<ID_SUSCRIPCION>/resourceGroups/GrupoRecursosContribuidores

# Asigna un rol de lectura acotado a un grupo de recursos
az ad sp create-for-rbac -n LectoresGrupales --role Reader --scopes /subscriptions/<ID_SUSCRIPCION>/resourceGroups/GrupoRecursosLectores

# Inicia sesión en Azure CLI usando el service principal (RBAC)
az login --service-principal \
  --username <APP_ID> \
  --password <SECRETO> \
  --tenant <ID_TENANT>

# Elimina un service principal
az ad sp delete --id <APP_ID>

# Elimina los grupos de recursos
az group delete -n GrupoRecursosContribuidores
az group delete -n GrupoRecursosLectores
