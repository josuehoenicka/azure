# Máquina virtual pública con NSG e IIS

En este laboratorio vas a desplegar una **máquina virtual** con Windows Server 2019 accesible desde internet, protegida por un **Network Security Group (NSG)**, y luego instalarás **IIS** (Internet Information Services) para que sirva páginas web. Es un escenario muy común cuando necesitas exponer un servidor web administrado por ti en la nube.

Antes de tocar comandos conviene entender las piezas que vas a crear y cómo se conectan entre sí. Una VM pública no vive sola: necesita una red donde colocarse, una dirección con la que el mundo la encuentre y un filtro que decida qué tráfico puede entrar o salir.

## ¿Qué piezas componen este escenario?

* **Red virtual (VNet)**: es tu red privada dentro de Azure. Le asignas un rango de direcciones (por ejemplo `10.10.0.0/16`) y dentro de ella conviven tus recursos de forma aislada.
* **Subred (subnet)**: una porción de la VNet (por ejemplo `10.10.0.0/24`) donde agrupas recursos con un propósito común. Aquí colocarás la VM web en una subred llamada `WebSubnet`.
* **IP pública**: la dirección con la que tu VM será alcanzable desde internet. Sin ella, la VM solo sería accesible dentro de la red privada.
* **Network Security Group (NSG)**: un firewall a nivel de red. Contiene **reglas** que permiten o niegan tráfico según protocolo, puerto y origen/destino.

## ¿Cómo funcionan las reglas y prioridades de un NSG?

Un NSG evalúa sus reglas en orden de **prioridad**, y aquí va la regla de oro: **menor número = mayor prioridad**. Una regla con prioridad `1000` se evalúa antes que una con `1001`. En cuanto una regla coincide con el tráfico, se aplica y se detiene la evaluación.

Los puertos que abriremos tienen un significado concreto:

| Puerto | Protocolo | Para qué sirve |
| ------ | --------- | -------------- |
| 3389   | RDP       | Escritorio remoto para administrar Windows |
| 80     | HTTP      | Tráfico web sin cifrar |
| 443    | HTTPS     | Tráfico web cifrado (TLS) |

> Advertencia de seguridad: exponer **RDP (3389)** a todo internet es un riesgo serio, ya que es un blanco frecuente de ataques de fuerza bruta. Lo recomendable es restringir el origen a tu IP (con `--source-address-prefixes <tu-ip>`) o, mejor aún, usar **Azure Bastion** en lugar de abrir RDP públicamente.

## Laboratorio paso a paso

### 1. Crear el grupo de recursos

El **grupo de recursos** es el contenedor lógico donde vivirán todos los objetos de este lab. Borrarlo al final eliminará todo de una sola vez.

```bash
az group create --name grupoRecursosPublicos --location "eastus2"
```

### 2. Crear la red virtual con su subred

Creamos la VNet `redVirtual` con el rango `10.10.0.0/16` y, en el mismo comando, una subred `WebSubnet` con el rango `10.10.0.0/24`. El parámetro `--address-prefix` define el espacio de la red y `--subnet-prefix` el de la subred.

```bash
az network vnet create --resource-group grupoRecursosPublicos --name redVirtual --address-prefix 10.10.0.0/16 --subnet-name WebSubnet --subnet-prefix 10.10.0.0/24
```

### 3. Crear la IP pública

Esta dirección permitirá que la VM sea alcanzable desde internet. La asociaremos a la VM más adelante.

```bash
az network public-ip create --resource-group grupoRecursosPublicos --name publicIP
```

### 4. Crear el NSG y sus reglas

Primero creamos el NSG vacío y luego le agregamos tres reglas de entrada: RDP, HTTP y HTTPS. Fíjate en las prioridades `1000`, `1001` y `1002`: cuanto menor el número, antes se evalúa la regla.

```bash
az network nsg create --resource-group grupoRecursosPublicos --name nsg
az network nsg rule create --resource-group grupoRecursosPublicos --nsg-name nsg --name allowRDP --protocol tcp --priority 1000 --destination-port-range 3389
az network nsg rule create --resource-group grupoRecursosPublicos --nsg-name nsg --name allowHTTP --protocol tcp --priority 1001 --destination-port-range 80
az network nsg rule create --resource-group grupoRecursosPublicos --nsg-name nsg --name allowHTTPS --protocol tcp --priority 1002 --destination-port-range 443
```

Cada regla especifica el protocolo (`--protocol tcp`), la prioridad (`--priority`) y el puerto de destino (`--destination-port-range`). Por defecto permiten cualquier origen; en producción acota el origen, sobre todo en la regla de RDP.

### 5. Asociar el NSG a la subred

Aplicamos el NSG a `WebSubnet` para que todas las reglas protejan los recursos de esa subred (en este caso, nuestra VM).

```bash
az network vnet subnet update --vnet-name redVirtual --name WebSubnet --resource-group grupoRecursosPublicos --network-security-group nsg
```

### 6. Crear la máquina virtual con Windows Server 2019

Aquí juntamos todo: la imagen de Windows Server 2019 (`Win2019Datacenter`), la VNet, la subred, la IP pública y el NSG. Define un usuario y contraseña de administrador.

```bash
az vm create --resource-group grupoRecursosPublicos --name webServerVirt --image Win2019Datacenter --admin-username aminespinoza --admin-password Am0_Apr3nd3r$ --vnet-name redVirtual --subnet WebSubnet --public-ip-address publicIP --nsg nsg
```

> La contraseña `Am0_Apr3nd3r$` es solo de demostración. Usa siempre tus propias credenciales y, si es posible, **claves SSH** o secretos guardados en **Azure Key Vault** en lugar de contraseñas en texto plano.

### 7. Abrir puertos en la VM

Este comando agrega reglas que permiten el tráfico en los puertos 80, 443 y 3389 directamente sobre la VM. El `--priority 100` le da alta prioridad a estas reglas.

```bash
az vm open-port -g grupoRecursosPublicos -n webServerVirt --port 80,443,3389 --priority 100
```

### 8. Instalar IIS en la máquina virtual

Para instalar el servidor web usamos **customScriptExtension**, una extensión de VM que ejecuta scripts dentro del sistema operativo después del aprovisionamiento. Aquí ejecuta un comando de PowerShell que instala la característica `Web-Server` (IIS) con todas sus subcaracterísticas y herramientas de administración.

```bash
az vm extension set --resource-group grupoRecursosPublicos --vm-name webServerVirt --name customScriptExtension --publisher Microsoft.Compute --settings '{"commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"}'
```

Una vez instalado, si copias la IP pública de la VM en un navegador deberías ver la página de bienvenida de IIS. Puedes agregar `--output table` a los comandos de consulta para leer los resultados en formato tabla.

## Buenas prácticas, costos y seguridad

* **Restringe RDP**: nunca dejes el puerto 3389 abierto a `0.0.0.0/0` en producción. Limita el origen a tu IP o usa Azure Bastion.
* **Credenciales fuertes**: evita contraseñas de ejemplo; gestiona secretos con Key Vault.
* **Prioridades claras**: deja huecos entre prioridades (1000, 1001, 1002) para poder insertar reglas en el futuro sin reordenar todo.
* **Costos**: una VM Windows encendida genera cargos por cómputo, disco e IP pública aunque no la uses. Apágala o bórrala cuando termines.

## Limpieza de recursos

Al terminar el laboratorio, elimina todo el grupo de recursos para no seguir generando costos. Este comando borra la VM, la red, la IP y el NSG de una sola vez:

```bash
az group delete -n grupoRecursosPublicos
```

## Conclusión

Aprendiste a montar una VM Windows pública en Azure conectando VNet, subred, IP pública y un NSG con reglas para RDP, HTTP y HTTPS, recordando que menor número de prioridad significa mayor preferencia. Finalmente instalaste IIS con customScriptExtension. Lleva contigo dos ideas clave: exponer RDP a internet es peligroso y conviene restringirlo, y siempre debes limpiar los recursos para controlar los costos.
