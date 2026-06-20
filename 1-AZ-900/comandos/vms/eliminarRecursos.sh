#!/bin/bash

# Nota: el lab de VMSS (comandos.sh) crea el grupo con un nombre dinámico
# guardado en $MY_RESOURCE_GROUP_NAME (p.ej. myVMSSResourceGroup<hex>).
# Reemplaza el nombre por el que imprimió el script al final, o reutiliza la variable
# en la misma sesión de terminal.

# Eliminar el grupo de recursos del VMSS
az group delete --name $MY_RESOURCE_GROUP_NAME

# Alternativa: lista los grupos para identificar el correcto
# az group list --query "[?starts_with(name, 'myVMSSResourceGroup')].name" -o tsv
