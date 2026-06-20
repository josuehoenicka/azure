# Redes en Azure: Zonas y registros DNS

Cuando publicas un servicio en internet, las personas no quieren memorizar direcciones IP como `10.10.10.10`; prefieren escribir un nombre como `www.platzi.xyz`. El **DNS** (Domain Name System) es el sistema que traduce esos nombres legibles a direcciones IP, y al revés. En Azure, el servicio **Azure DNS** te permite hospedar tus dominios y administrar esa resolución de nombres con la misma confiabilidad y escala de la infraestructura global de Microsoft.

En este laboratorio práctico crearás una **zona DNS**, agregarás registros y consultarás la configuración usando la **CLI de Azure** (`az`). El objetivo es que entiendas qué es una zona, qué tipos de registro existen y cómo administrarlos desde la línea de comandos.

## ¿Qué es una zona DNS?

Una **zona DNS** es el contenedor donde guardas todos los registros de un dominio concreto, por ejemplo `platzi.xyz`. Piensa en ella como una "agenda" para ese dominio: dentro viven las reglas que dicen a qué dirección IP responde cada nombre, qué servidores son la autoridad del dominio, dónde está el correo, etc.

Puntos clave de una zona DNS en Azure:

* Representa un dominio único dentro de tu suscripción.
* Se crea dentro de un **grupo de recursos**, igual que el resto de servicios de Azure.
* Para que el dominio funcione realmente en internet, debes apuntar tu **registrador de dominios** (donde compraste `platzi.xyz`) a los servidores de nombres que Azure te asigna.

## Tipos de registro DNS

Dentro de una zona puedes crear distintos **tipos de registro**, cada uno con un propósito. Estos son los que verás en el laboratorio:

| Tipo | Para qué sirve | Ejemplo |
| --- | --- | --- |
| **A** | Asocia un nombre a una dirección IPv4 | `www` -> `10.10.10.10` |
| **NS** | Indica los **servidores de nombres** (Name Servers) que tienen autoridad sobre la zona | servidores de Azure DNS |
| AAAA | Igual que A, pero para direcciones IPv6 | `www` -> IPv6 |
| CNAME | Crea un alias de un nombre hacia otro nombre | `blog` -> `www.platzi.xyz` |
| MX | Define los servidores de correo del dominio | correo |

* El **registro A** es el más común: traduce un nombre (`www`) a una IP. Cuando alguien escribe `www.platzi.xyz`, su navegador consulta este registro para saber a qué servidor conectarse.
* El **registro NS** lo crea Azure automáticamente al generar la zona. Lista los servidores de nombres autoritativos; son los valores que debes copiar a tu registrador para "delegar" el dominio a Azure.

## El nombre "@": el apex o raíz del dominio

Al crear registros notarás que se usa el símbolo **`@`** como nombre. El `@` representa el **apex** (también llamado raíz o root) del dominio, es decir, el dominio "pelado" sin subdominio: `platzi.xyz` en lugar de `www.platzi.xyz`.

* `www` -> registro para `www.platzi.xyz`
* `@` -> registro para `platzi.xyz` (la raíz)

Por eso, para consultar los servidores de nombres de toda la zona, se pide el registro NS del nombre `@`.

## Laboratorio paso a paso

### 1. Crear un grupo de recursos

Todo servicio en Azure vive dentro de un grupo de recursos, que actúa como una carpeta lógica. Aquí creamos uno llamado `grupoRecursosRedes` en la región `East US`.

```bash
# Crear un grupo de recursos
az group create --name grupoRecursosRedes --location "East US"
```

Parámetros clave: `--name` (nombre del grupo) y `--location` (región donde se administra). Las zonas DNS son un servicio global, pero su metadato sí pertenece a una región/grupo.

### 2. Crear una zona DNS

Ahora creamos la zona para el dominio `platzi.xyz` dentro de ese grupo.

```bash
# Crear una zona DNS
az network dns zone create -g grupoRecursosRedes -n platzi.xyz
```

Parámetros clave: `-g` (grupo de recursos) y `-n` (nombre del dominio). Al ejecutarlo, Azure crea automáticamente los registros **NS** y **SOA** de la zona. Puedes agregar `--output table` para ver el resultado en formato de tabla más legible.

### 3. Crear un registro A

Asociamos el subdominio `www` a la dirección IP `10.10.10.10`.

```bash
# Crear un registro A en la zona DNS
az network dns record-set a add-record -g grupoRecursosRedes -z platzi.xyz -n www -a 10.10.10.10
```

Parámetros clave: `-z` (nombre de la zona), `-n` (el nombre del registro, aquí `www`) y `-a` (la dirección IPv4 destino). Tras esto, `www.platzi.xyz` resolverá a `10.10.10.10`.

### 4. Listar los registros de la zona

Para revisar todo lo que contiene la zona (incluidos los registros que Azure creó solo):

```bash
# Listar los registros de la zona DNS
az network dns record-set list -g grupoRecursosRedes -z platzi.xyz
```

Verás el registro A que acabas de crear, junto con los registros NS y SOA por defecto. De nuevo, `--output table` ayuda a leer la salida.

### 5. Mostrar el registro NS de la zona

Por último, consultamos los servidores de nombres autoritativos de la zona usando el apex `@`.

```bash
# Mostrar el registro NS de la zona DNS
az network dns record-set ns show --resource-group grupoRecursosRedes --zone-name platzi.xyz --name @
```

Parámetros clave: `--zone-name` (la zona) y `--name @` (el apex/raíz). La salida muestra los nombres de los servidores DNS de Azure. **Estos son los valores que debes copiar en tu registrador de dominios** para que el dominio empiece a usar Azure DNS de verdad.

## Buenas prácticas, costos y seguridad

* **Costos:** Azure DNS cobra por zona hospedada y por número de consultas DNS. Una zona de prueba cuesta muy poco, pero acumula gasto si la dejas activa; por eso conviene borrarla al terminar.
* **Credenciales de ejemplo:** si en otros laboratorios ves contraseñas como `Am0_Apr3nd3r$`, recuerda que son solo de demostración. Usa siempre credenciales propias y, mejor aún, **claves SSH** o **Azure Key Vault** para gestionar secretos de forma segura.
* **Nomenclatura:** usa nombres de grupo y zona consistentes para identificar fácilmente lo que es de prueba y lo que es producción.
* **Delegación real:** la zona en Azure no afecta tu dominio hasta que actualizas los NS en tu registrador. Mientras tanto, todos los cambios son seguros y aislados.

## Limpieza de recursos

Para no generar costos innecesarios, elimina el grupo de recursos al terminar. Borrar el grupo elimina la zona DNS y todos sus registros de una sola vez.

```bash
az group delete -n grupoRecursosRedes
```

Azure pedirá confirmación; puedes agregar `--yes` para omitirla y `--no-wait` si no quieres esperar a que termine el borrado.

## Conclusión

Azure DNS te permite hospedar dominios y administrar la resolución de nombres con registros como **A** (nombre a IP) y **NS** (servidores de nombres autoritativos). Aprendiste que una **zona DNS** agrupa los registros de un dominio y que el nombre **`@`** representa la raíz o apex. Con unos pocos comandos de la CLI creaste, consultaste y limpiaste toda la configuración, sentando las bases para administrar redes y nombres en la nube.
