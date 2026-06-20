# Fundamentos de Azure (AZ-900)

Notas de estudio y laboratorios prácticos del curso **Fundamentos de Azure** de Platzi, preparatorio para la certificación **AZ-900: Microsoft Azure Fundamentals**.

Los temas prácticos toman como referencia el repositorio [platzi/AZ-900](https://github.com/platzi/AZ-900): cada laboratorio del repo está documentado aquí como una nota de estudio en español, y los scripts ejecutables originales se conservan en la carpeta [comandos/](comandos/).

## Contenido

### Conceptos

| # | Nota | Resumen |
| - | ---- | ------- |
| 1 | [Nube privada, pública e híbrida](1-nube-privada-publica-hibrida.md) | Los tres modelos de nube, sus ventajas, desventajas y cómo elegir el adecuado según control, velocidad y cumplimiento. |
| 2 | [Costos y beneficios de soluciones en la nube](2-costos-beneficios-soluciones-nube-azure.md) | Cuándo conviene la nube, cómo evitar el sobredimensionamiento y cómo estimar costos con la calculadora de precios de Azure. |

### Laboratorios prácticos (Azure CLI)

| # | Nota | Resumen | Script |
| - | ---- | ------- | ------ |
| 3 | [Fundamentos de Azure CLI](3-fundamentos-azure-cli.md) | Instalación, `az login`/`az account show` y creación de un grupo de recursos y una cuenta de almacenamiento. | [azureCLI](comandos/azureCLI/comandos.sh) |
| 4 | [Cómputo en Azure: VMs, Containers y Functions](4-computo-en-azure.md) | Servicios de cómputo (VM, Container App y Function App) comparando IaaS, contenedores administrados y serverless. | [computo](comandos/computo/comandos.sh) |
| 5 | [IaaS: Infraestructura como Servicio](5-iaas-infraestructura-como-servicio.md) | Modelo de responsabilidad compartida y creación de VM, almacenamiento y red virtual. | [azureIaaS](comandos/azureIaaS/comandos.sh) |
| 6 | [PaaS: Plataforma como Servicio](6-paas-plataforma-como-servicio.md) | Despliegue de Cosmos DB, Azure SQL y App Service, comparando PaaS vs IaaS. | [azurePaaS](comandos/azurePaaS/comandos.sh) |
| 7 | [Almacenamiento: Storage Accounts y Blobs](7-almacenamiento-en-azure.md) | Storage Account, contenedores y subida de blobs; redundancia LRS/ZRS/GRS y manejo de claves. | [almacenamiento](comandos/almacenamiento/comandos.sh) |
| 8 | [Redes en Azure: Zonas y registros DNS](8-redes-y-dns.md) | Zona DNS, registros A y NS, y el significado del apex `@`. | [redes](comandos/redes/comandos.sh) |
| 9 | [Máquina virtual pública con NSG e IIS](9-maquina-virtual-publica.md) | VM Windows pública con VNet, subred, IP pública, NSG (RDP/HTTP/HTTPS) e IIS vía customScriptExtension. | [vmPublica](comandos/vmPublica/comandos.sh) |
| 10 | [Escalabilidad con App Service](10-escalabilidad-con-app-service.md) | Plan y web app; diferencia entre scale up (`--sku`) y scale out (`--number-of-workers`) y autoescalado. | [escalabilidad](comandos/escalabilidad/comandos.sh) |
| 11 | [Conjuntos de escalado (VMSS) y Application Gateway](11-conjuntos-de-escalado-vmss.md) | VMSS con Application Gateway y autoescalado por CPU. | [vms](comandos/vms/comandos.sh) |
| 12 | [RBAC: Control de acceso basado en roles](12-rbac-control-de-acceso.md) | Roles (Reader, Contributor, Owner), ámbitos y service principals; principio de menor privilegio. | [rbac](comandos/rbac/comandos.sh) |
| 13 | [Zero Trust: almacenamiento seguro](13-zero-trust-seguridad.md) | Comparación de una cuenta de almacenamiento básica vs una endurecida según Zero Trust. | [zeroTrust](comandos/zeroTrust/comandos.sh) |

## Cómo usar los laboratorios

Necesitas la [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) instalada y una suscripción de Azure.

```bash
# Iniciar sesión
az login

# (Opcional) elegir la suscripción activa
az account set --subscription "<NOMBRE_O_ID>"

# Ejecutar un laboratorio
bash comandos/azureCLI/comandos.sh
```

> **Limpieza:** casi todos los recursos cuestan dinero mientras existen. Cada nota incluye una sección de **Limpieza de recursos**; ejecútala al terminar (normalmente `az group delete -n <grupo>`) para evitar cargos.

## Nota de seguridad

- Las contraseñas de ejemplo en los scripts (p. ej. `Am0_Apr3nd3r$`) son **de demostración**. Usa credenciales propias y, mejor aún, claves SSH o **Azure Key Vault**.
- El script [comandos/rbac/comandos.sh](comandos/rbac/comandos.sh) fue **sanitizado**: los identificadores y el secreto que el repo de referencia exponía se reemplazaron por placeholders (`<ID_SUSCRIPCION>`, `<APP_ID>`, `<SECRETO>`, `<ID_TENANT>`). **Nunca** subas secretos reales a git.
