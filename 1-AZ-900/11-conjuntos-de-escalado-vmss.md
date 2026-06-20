# Conjuntos de escalado de máquinas virtuales (VMSS) y Application Gateway

Cuando una aplicación recibe más tráfico del que una sola máquina virtual puede soportar, necesitas una forma de crecer (y decrecer) automáticamente sin intervención manual. Un **Virtual Machine Scale Set (VMSS)** resuelve justo eso: crea y administra un grupo de VMs idénticas que comparten configuración, de modo que puedes tratarlas como una sola unidad lógica y escalarlas en bloque.

En este laboratorio crearás un VMSS con dos instancias de Ubuntu, instalarás **nginx** en ellas mediante una extensión personalizada y colocarás un **Application Gateway** al frente para repartir el tráfico HTTP. Además, configurarás **autoescalado por CPU** para que el conjunto agregue o quite instancias según la carga. Todo se hace con la CLI de Azure (`az`), aprovechando variables de entorno para que el lab sea repetible.

## ¿Qué es un Virtual Machine Scale Set (VMSS)?

Un VMSS es un servicio de cómputo que te permite implementar y gestionar un conjunto de VMs idénticas con balanceo de carga. Sus ventajas principales son:

* **Escalabilidad**: puedes aumentar o reducir el número de instancias según la demanda, ya sea de forma manual o automática.
* **Alta disponibilidad**: al distribuir las instancias entre varias **zonas de disponibilidad** (1, 2 y 3), tu aplicación sobrevive a la caída de un centro de datos completo.
* **Administración simplificada**: actualizas una imagen o configuración una sola vez y se aplica a todas las instancias.
* **Costo eficiente**: solo pagas por las instancias que realmente necesitas en cada momento.

## ¿Qué es un Application Gateway?

Un **Application Gateway** es un balanceador de carga de capa 7 (aplicación, HTTP/HTTPS). A diferencia de un balanceador de capa 4, entiende el contenido de las peticiones HTTP, por lo que puede enrutar por ruta de URL, terminar TLS y aplicar reglas de firewall de aplicaciones web (WAF). En este lab actúa como punto de entrada público: recibe las peticiones en el puerto 80 y las reparte entre las instancias del VMSS (el *backend pool*).

## Variables de entorno y nombres únicos

Antes de crear nada, defines variables de entorno. Esto hace que el laboratorio sea legible y fácil de repetir: cambias un valor en un solo sitio y se propaga a todos los comandos.

```bash
# Variables del entorno
export RANDOM_ID="$(openssl rand -hex 3)"
export MY_RESOURCE_GROUP_NAME="myVMSSResourceGroup$RANDOM_ID"
export REGION=EastUS
export MY_VMSS_NAME="myVMSS$RANDOM_ID"
export MY_USERNAME=azureuser
export MY_VM_IMAGE="Ubuntu2204"
export MY_VNET_NAME="myVNet$RANDOM_ID"
export NETWORK_PREFIX="$(($RANDOM % 254 + 1))"
export MY_VNET_PREFIX="10.$NETWORK_PREFIX.0.0/16"
export MY_VM_SN_NAME="myVMSN$RANDOM_ID"
export MY_VM_SN_PREFIX="10.$NETWORK_PREFIX.0.0/24"
export MY_APPGW_SN_NAME="myAPPGWSN$RANDOM_ID"
export MY_APPGW_SN_PREFIX="10.$NETWORK_PREFIX.1.0/24"
export MY_APPGW_NAME="myAPPGW$RANDOM_ID"
export MY_APPGW_PUBLIC_IP_NAME="myAPPGWPublicIP$RANDOM_ID"
```

Aquí hay dos detalles clave:

* `openssl rand -hex 3` genera 3 bytes aleatorios en hexadecimal (6 caracteres). Se usa como **sufijo único** (`RANDOM_ID`) en todos los nombres de recursos. Muchos nombres en Azure deben ser únicos, así que esto evita colisiones si repites el lab o trabajas en una suscripción compartida.
* `NETWORK_PREFIX` calcula un número aleatorio entre 1 y 254 para el segundo octeto de la red, de modo que el rango de IPs privadas tampoco choque con otras redes.

## Laboratorio paso a paso

### 1. Crear el grupo de recursos

El **grupo de recursos** es el contenedor lógico donde vivirán todos los recursos. Borrarlo elimina todo de una vez, lo que es ideal para limpiar después.

```bash
# Crear un grupo de recursos
az group create --name $MY_RESOURCE_GROUP_NAME --location $REGION -o JSON
```

### 2. Crear la red virtual y la subred de las VMs

La **red virtual (VNet)** es la red privada donde se comunican tus recursos. Aquí defines el rango global (`/16`) y, dentro, una subred (`/24`) para las VMs del VMSS.

```bash
# Crear una red virtual con la subred de las VMs
az network vnet create --name $MY_VNET_NAME --resource-group $MY_RESOURCE_GROUP_NAME --location $REGION --address-prefix $MY_VNET_PREFIX --subnet-name $MY_VM_SN_NAME --subnet-prefix $MY_VM_SN_PREFIX -o JSON
```

### 3. Crear una subred dedicada para el Application Gateway

El Application Gateway requiere su **propia subred**, separada de las VMs. Por eso añades una segunda subred (`10.x.1.0/24`) en la misma VNet.

```bash
# Crear una subred para el Application Gateway
az network vnet subnet create --name $MY_APPGW_SN_NAME --resource-group $MY_RESOURCE_GROUP_NAME --vnet-name $MY_VNET_NAME --address-prefix $MY_APPGW_SN_PREFIX -o JSON
```

### 4. Crear la IP pública del Application Gateway

Esta IP pública será la dirección desde la que accederás a la aplicación. Usa la SKU `Standard`, asignación `static` (no cambia) y se distribuye en las zonas `1 2 3` para alta disponibilidad.

```bash
# Crear una IP pública para el Application Gateway
az network public-ip create --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_APPGW_PUBLIC_IP_NAME --sku Standard --location $REGION --allocation-method static --version IPv4 --zone 1 2 3 -o JSON
```

### 5. Crear el Application Gateway

Aquí montas el balanceador de capa 7. Parámetros importantes:

* `--capacity 2`: dos instancias del gateway para tolerancia a fallos.
* `--zones 1 2 3` y `--sku Standard_v2`: distribución por zonas y la SKU de segunda generación (mejor rendimiento y autoescalado).
* `--frontend-port 80` y `--http-settings-port 80`: escucha y reenvía por HTTP en el puerto 80.
* `--priority 1001`: prioridad de la regla de enrutamiento.

```bash
# Crear el Application Gateway
az network application-gateway create --name $MY_APPGW_NAME --location $REGION --resource-group $MY_RESOURCE_GROUP_NAME --vnet-name $MY_VNET_NAME --subnet $MY_APPGW_SN_NAME --capacity 2 --zones 1 2 3 --sku Standard_v2 --http-settings-cookie-based-affinity Disabled --frontend-port 80 --http-settings-port 80 --http-settings-protocol Http --public-ip-address $MY_APPGW_PUBLIC_IP_NAME --priority 1001 -o JSON
```

### 6. Crear el conjunto de escalado (VMSS)

Ahora creas el VMSS y lo conectas al Application Gateway mediante `--app-gateway` y `--backend-pool-name`. Detalles a destacar:

* `--generate-ssh-keys`: genera un par de **claves SSH** automáticamente. Es mucho más seguro que usar contraseñas. Si alguna vez ves contraseñas de ejemplo como `Am0_Apr3nd3r$` en otros labs, recuerda que son solo de demostración: usa siempre tus propias credenciales y, mejor aún, claves SSH o **Azure Key Vault**.
* `--instance-count 2`: arranca con dos VMs.
* `--zones 1 2 3`: reparte las instancias entre las tres zonas de disponibilidad.
* `--orchestration-mode Uniform`: todas las instancias son idénticas.
* `--upgrade-policy-mode Automatic`: las actualizaciones se aplican automáticamente a todas las instancias.

```bash
# Crear el conjunto de escalado (VMSS)
az vmss create --name $MY_VMSS_NAME --resource-group $MY_RESOURCE_GROUP_NAME --image $MY_VM_IMAGE --admin-username $MY_USERNAME --generate-ssh-keys --public-ip-per-vm --orchestration-mode Uniform --instance-count 2 --zones 1 2 3 --vnet-name $MY_VNET_NAME --subnet $MY_VM_SN_NAME --vm-sku Standard_DS2_v2 --upgrade-policy-mode Automatic --app-gateway $MY_APPGW_NAME --backend-pool-name appGatewayBackendPool -o JSON
```

### 7. Instalar nginx con una extensión personalizada

Una **extensión de script personalizado (CustomScript)** ejecuta un script en cada instancia tras su creación. Aquí descarga `automate_nginx.sh` desde GitHub y lo ejecuta para instalar y configurar nginx en todas las VMs del conjunto.

```bash
# Instalar nginx con una extensión personalizada
az vmss extension set --publisher Microsoft.Azure.Extensions --version 2.0 --name CustomScript --resource-group $MY_RESOURCE_GROUP_NAME --vmss-name $MY_VMSS_NAME --settings '{ "fileUris": ["https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/automate_nginx.sh"], "commandToExecute": "./automate_nginx.sh" }' -o JSON
```

### 8. Crear reglas de autoescalado por CPU

El **autoescalado** ajusta el número de instancias según métricas en tiempo real. Primero defines el perfil (mínimo, máximo y conteo inicial) y luego dos reglas:

* **Scale out**: si la CPU promedio supera el 70% durante 5 minutos, agrega 3 instancias.
* **Scale in**: si la CPU promedio baja del 30% durante 5 minutos, quita 1 instancia.

```bash
# Crear reglas de autoescalado por CPU
az monitor autoscale create --resource-group $MY_RESOURCE_GROUP_NAME --resource $MY_VMSS_NAME --resource-type Microsoft.Compute/virtualMachineScaleSets --name autoscale --min-count 2 --max-count 10 --count 2
az monitor autoscale rule create --resource-group $MY_RESOURCE_GROUP_NAME --autoscale-name autoscale --condition "Percentage CPU > 70 avg 5m" --scale out 3
az monitor autoscale rule create --resource-group $MY_RESOURCE_GROUP_NAME --autoscale-name autoscale --condition "Percentage CPU < 30 avg 5m" --scale in 1
```

El siguiente cuadro resume la política de escalado:

| Parámetro | Valor | Significado |
|-----------|-------|-------------|
| `--min-count` | 2 | Nunca menos de 2 instancias |
| `--max-count` | 10 | Tope máximo de instancias |
| `--count` | 2 | Conteo inicial por defecto |
| Scale out | CPU > 70% (5m) → +3 | Crece ante alta demanda |
| Scale in | CPU < 30% (5m) → -1 | Decrece para ahorrar costos |

Fíjate en que el scale out añade más instancias de las que quita el scale in: así reaccionas rápido a los picos pero reduces con prudencia para no entrar en oscilaciones.

### 9. Obtener la IP pública y probar

Finalmente, recuperas la IP pública del Application Gateway. Pégala en tu navegador y deberías ver la página de bienvenida de nginx servida por las instancias del VMSS.

```bash
# Obtener la IP pública del Application Gateway
az network public-ip show --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_APPGW_PUBLIC_IP_NAME --query [ipAddress] --output tsv

echo $MY_RESOURCE_GROUP_NAME
```

El `echo` final imprime el nombre del grupo de recursos para que lo tengas a mano al limpiar.

## Buenas prácticas, costos y seguridad

* **Seguridad**: prefiere siempre `--generate-ssh-keys` sobre contraseñas. Para secretos de producción usa Azure Key Vault. Las contraseñas de ejemplo de los labs son solo demostrativas.
* **Costos**: un VMSS con varias VMs `Standard_DS2_v2`, un Application Gateway `Standard_v2` y una IP pública generan cargos por hora. Borra todo en cuanto termines.
* **Alta disponibilidad**: usar zonas `1 2 3` te protege ante fallos de zona, pero confirma que tu región las soporte.
* **Visualización**: agrega `--output table` (en vez de `-o JSON`) a cualquier comando para ver una salida tabular más legible.

## Limpieza de recursos

Para no acumular costos, elimina el grupo de recursos completo cuando termines. Esto borra el VMSS, el Application Gateway, la VNet y la IP pública de una sola vez.

```bash
az group delete --name $MY_RESOURCE_GROUP_NAME
```

## Conclusión

Un VMSS te permite operar un grupo de VMs idénticas como una unidad escalable y de alta disponibilidad, y combinado con un Application Gateway obtienes un punto de entrada inteligente que reparte el tráfico HTTP. Con reglas de autoescalado por CPU, tu aplicación crece ante los picos y se contrae cuando baja la demanda, optimizando rendimiento y costo. Recuerda usar nombres únicos, claves SSH y borrar los recursos al finalizar.
