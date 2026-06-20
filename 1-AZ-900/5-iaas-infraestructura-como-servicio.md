# IaaS: Infraestructura como Servicio

La **Infraestructura como Servicio (IaaS)** es el modelo de nube más cercano a la infraestructura tradicional. En él, el proveedor (Azure) te entrega cómputo, almacenamiento y red bajo demanda, mientras que tú conservas el control del sistema operativo, los parches, el middleware y las aplicaciones. Es como alquilar el hardware y la conectividad: enciendes una máquina virtual en minutos y, a partir de ahí, la administras como si fuera tu propio servidor.

Este modelo es ideal cuando necesitas máximo control y flexibilidad, cuando migras cargas de trabajo existentes ("lift and shift") o cuando tienes requisitos muy específicos de configuración. A cambio de esa libertad, asumes más responsabilidad operativa que en PaaS o SaaS. En esta nota verás los tres componentes típicos de IaaS y un laboratorio práctico con la CLI de Azure.

## ¿Qué administras tú y qué administra Azure?

IaaS se rige por el **modelo de responsabilidad compartida**: la seguridad y la operación no recaen por completo en una sola parte, sino que se reparten según el modelo de servicio. Cuanto más bajo es el nivel (IaaS), más responsabilidad tienes tú.

| Responsabilidad | IaaS | PaaS | SaaS |
| --- | --- | --- | --- |
| Datos y acceso | Tú | Tú | Tú |
| Aplicaciones | Tú | Compartido | Azure |
| Sistema operativo | **Tú** | Azure | Azure |
| Red virtual y firewall | Compartido | Azure | Azure |
| Servidores físicos | Azure | Azure | Azure |
| Centro de datos físico | Azure | Azure | Azure |

En IaaS, Azure se encarga del hardware físico, la virtualización y el centro de datos. Tú te encargas del sistema operativo (incluidas sus actualizaciones), de las aplicaciones, de los datos y de la configuración de seguridad como reglas de red, identidades y credenciales.

## Los tres componentes típicos de IaaS

* **Máquina virtual (VM):** es el componente de cómputo. Equivale a un servidor con CPU, memoria y un sistema operativo que tú eliges (Linux o Windows). Aquí instalas y ejecutas tus aplicaciones.
* **Cuenta de almacenamiento:** provee espacio persistente para discos, archivos, blobs y colas. Es donde guardas datos que deben sobrevivir más allá del ciclo de vida de una VM.
* **Red virtual (VNet):** es la red privada y aislada donde viven tus recursos. Define rangos de direcciones IP, subredes y reglas de conectividad para que tus VMs se comuniquen entre sí y, de forma controlada, con Internet.

## Laboratorio paso a paso

En este laboratorio crearás los tres componentes de IaaS dentro de un mismo **grupo de recursos**, usando la CLI de Azure. Agrupar todo facilita administrarlo y, sobre todo, eliminarlo después.

### 1. Crear el grupo de recursos

El grupo de recursos es un contenedor lógico que agrupa recursos relacionados. El parámetro `-l` define la región (aquí `eastus2`) y `-n` el nombre.

```bash
# Crear un grupo de recursos
az group create -l eastus2 -n GrupoRecursosIaaS
```

### 2. Crear la máquina virtual

Aquí se aprovisiona el cómputo. `-n` nombra la VM, `-g` indica el grupo de recursos, `--image Ubuntu2204` define el sistema operativo y `--admin-username`/`--admin-password` crean el usuario administrador. Al terminar, Azure devuelve la IP pública con la que podrás conectarte por SSH.

```bash
# Crear una máquina virtual
az vm create -n iaas-vm-amin -g GrupoRecursosIaaS --image Ubuntu2204 --admin-username aminespinoza --admin-password Am0_Apr3nd3r$
```

> **Importante sobre las credenciales:** la contraseña `Am0_Apr3nd3r$` es solo de demostración. Nunca uses contraseñas de ejemplo en entornos reales: define las tuyas propias y, mejor aún, usa **claves SSH** (`--generate-ssh-keys`) o guarda los secretos en **Azure Key Vault** en lugar de pasarlos en texto plano por la línea de comandos.

### 3. Crear la cuenta de almacenamiento

`-n` es el nombre (debe ser único globalmente y en minúsculas), `-l` la región y `--sku Standard_LRS` define la redundancia: *Locally Redundant Storage* mantiene tres copias dentro de un mismo centro de datos, que es la opción más económica.

```bash
# Crear una cuenta de almacenamiento básica
az storage account create -n storageiaas004 -g GrupoRecursosIaaS -l eastus2 --sku Standard_LRS
```

### 4. Crear la red virtual

Esta VNet define el espacio de direcciones con `--address-prefix 10.0.0.0/16` (unas 65 000 direcciones) y, dentro de él, una subred con `--subnet-name` y `--subnet-prefixes 10.0.0.0/24` (256 direcciones). Las subredes te permiten segmentar y aplicar reglas de seguridad por grupos de recursos.

```bash
# Crear una red virtual
az network vnet create -g GrupoRecursosIaaS -n IaaSVnet004 --address-prefix 10.0.0.0/16 --subnet-name aminesSubnet --subnet-prefixes 10.0.0.0/24
```

> Consejo: agrega `--output table` a cualquiera de estos comandos para ver la respuesta en una tabla legible en lugar del JSON completo.

## Buenas prácticas, costos y seguridad

* **Costos:** una VM encendida genera cargos por hora aunque no la uses. Apágala (desasignándola) cuando no la necesites y elige el tamaño adecuado para tu carga.
* **Redundancia vs. precio:** `Standard_LRS` es lo más barato; si necesitas mayor resiliencia, valora ZRS o GRS, que cuestan más pero replican entre zonas o regiones.
* **Seguridad:** prefiere claves SSH sobre contraseñas, restringe el puerto SSH con **grupos de seguridad de red (NSG)** y aplica el principio de menor privilegio en los accesos.
* **Organización:** mantén todo en un solo grupo de recursos por proyecto o entorno; así controlas costos y limpieza fácilmente.

## Limpieza de recursos

Para no generar costos, elimina todos los recursos cuando termines. Borrar el grupo de recursos elimina de una sola vez la VM, el almacenamiento y la red.

```bash
# Eliminar todos los recursos creados
az group delete -n GrupoRecursosIaaS --force-deletion-types Microsoft.Compute/virtualMachines
```

El parámetro `--force-deletion-types Microsoft.Compute/virtualMachines` indica a Azure que fuerce el borrado de las máquinas virtuales sin esperar a un apagado ordenado. Esto acelera la eliminación, ya que las VMs suelen ser el recurso que más tarda en liberarse, y evita que el proceso se quede bloqueado. Si no se provee un comando específico, la forma general de borrar un grupo es:

```bash
az group delete -n <grupo>
```

## Conclusión

IaaS te entrega cómputo, almacenamiento y red bajo demanda dándote el control del sistema operativo y las aplicaciones, dentro de un modelo de responsabilidad compartida donde Azure cuida el hardware y tú la capa superior. En este laboratorio creaste una VM, una cuenta de almacenamiento y una red virtual, y aprendiste a eliminarlos de forma forzada para no incurrir en costos. Recuerda siempre usar credenciales propias y limpiar los recursos que dejes de utilizar.
