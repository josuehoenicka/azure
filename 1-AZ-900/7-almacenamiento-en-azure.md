# Almacenamiento en Azure: Storage Accounts y Blobs

El almacenamiento es uno de los pilares de cualquier solución en la nube. En Azure, casi todo lo que guardas (archivos, imágenes, copias de seguridad, logs, datos de aplicaciones) vive dentro de una **cuenta de almacenamiento** o *Storage Account*. Esta cuenta funciona como un contenedor lógico de nivel superior que agrupa varios servicios de datos bajo un mismo espacio de nombres y una misma configuración de seguridad y redundancia.

Una cuenta de almacenamiento de Azure ofrece cuatro servicios principales: **Blobs** (objetos no estructurados como archivos, imágenes o vídeos), **Files** (recursos compartidos accesibles por SMB/NFS), **Queues** (colas de mensajes para comunicación entre componentes) y **Tables** (almacenamiento NoSQL clave-valor). En este laboratorio nos enfocamos en **Blob Storage**, que es el servicio ideal para guardar archivos y objetos a gran escala. Crearemos una cuenta, definiremos contenedores y subiremos un archivo usando la CLI de Azure.

## ¿Qué es un Blob y qué es un contenedor?

Conviene tener claros estos dos conceptos antes de empezar, porque es fácil confundirlos:

* Un **blob** (*Binary Large Object*) es el archivo u objeto en sí: una imagen, un PDF, un script, un vídeo, etc. Es la unidad mínima de datos que subes.
* Un **contenedor** es una agrupación lógica de blobs dentro de la cuenta de almacenamiento. Funciona de forma parecida a una carpeta o "cubeta": organiza los blobs y define un nivel de acceso común.

La jerarquía queda así: una **cuenta de almacenamiento** contiene uno o varios **contenedores**, y cada contenedor contiene uno o varios **blobs**. No puedes subir un blob "suelto" a la cuenta; siempre debe ir dentro de un contenedor.

| Concepto | Qué es | Analogía |
| --- | --- | --- |
| Storage Account | Espacio de nombres global y configuración de datos | La unidad de disco |
| Contenedor | Agrupación lógica de blobs | Una carpeta |
| Blob | El archivo u objeto individual | El archivo |

## SKU de redundancia: LRS, ZRS y GRS

Al crear la cuenta debes elegir un **SKU** que define cuántas copias de tus datos mantiene Azure y dónde las guarda. Esto impacta directamente en la durabilidad, la disponibilidad y el costo. Las opciones más comunes son:

| SKU | Significado | Cómo replica | Cuándo usarlo |
| --- | --- | --- | --- |
| **LRS** | *Locally Redundant Storage* | 3 copias dentro de un mismo centro de datos | Datos que puedes recrear fácilmente; la opción más económica |
| **ZRS** | *Zone Redundant Storage* | 3 copias en zonas de disponibilidad distintas de la misma región | Alta disponibilidad ante la caída de un centro de datos |
| **GRS** | *Geo Redundant Storage* | LRS en la región primaria + copia asíncrona en una región secundaria | Recuperación ante desastres a nivel regional |

En este laboratorio usamos `Standard_LRS` porque es suficiente para pruebas y es el más barato. Como buena práctica, en producción elige ZRS o GRS para datos críticos, y reserva LRS para entornos de desarrollo o datos que no sean costosos de regenerar.

## Laboratorio paso a paso

### 1. Crear el grupo de recursos

Todo recurso en Azure debe vivir dentro de un **grupo de recursos**, que actúa como un contenedor administrativo para gestionar, organizar y borrar recursos en conjunto. Aquí lo creamos en la región `eastus2`.

```bash
# Crear un grupo de recursos
az group create --name grupoAlmacenamiento --location "eastus2"
```

Parámetros clave: `--name` define el nombre del grupo y `--location` la región donde se administrará. Elegir una región cercana a tus usuarios reduce latencia y, en ocasiones, costos.

### 2. Crear la cuenta de almacenamiento

Ahora creamos la Storage Account dentro del grupo anterior. El nombre debe ser **único a nivel global** (forma parte de la URL pública del servicio) y estar en minúsculas, sin espacios ni caracteres especiales.

```bash
# Crear una cuenta de almacenamiento
az storage account create --name almacenamientoap --resource-group grupoAlmacenamiento --location eastus2 --sku Standard_LRS
```

Parámetros clave: `--name` es el nombre global de la cuenta, `--resource-group` la asocia al grupo creado, `--location` define la región y `--sku Standard_LRS` establece la redundancia local explicada arriba. Si el nombre ya está tomado por otra persona en Azure, el comando fallará; en ese caso prueba con otro.

### 3. Obtener la clave de acceso

Para operar sobre la cuenta (crear contenedores, subir blobs) necesitas autenticarte. Una forma es usar una de las **claves de acceso** de la cuenta. Guardamos esa clave en una variable de entorno para reutilizarla en los siguientes comandos.

```bash
# Obtener la clave de acceso de la cuenta
AZURE_STORAGE_KEY=$(az storage account keys list --account-name almacenamientoap --resource-group grupoAlmacenamiento --query "[0].value" --output tsv)
```

¿Por qué se usa `--query "[0].value"`? El comando `keys list` devuelve un arreglo con varias claves (key1, key2). La expresión **JMESPath** `[0].value` selecciona el valor de la primera clave del arreglo, en lugar de imprimir todo el JSON. Y `--output tsv` devuelve solo el texto plano, sin comillas ni formato, perfecto para asignarlo a una variable. Así, `$AZURE_STORAGE_KEY` queda lista para usarse. Si quieres ver la salida completa de forma legible, puedes ejecutar el `keys list` sin `--query` y agregar `--output table`.

### 4. Crear contenedores

Con la clave en mano, creamos tres contenedores dentro de la cuenta. Recuerda que un contenedor es la "carpeta" donde luego viven los blobs.

```bash
# Crear contenedores en la cuenta de almacenamiento
az storage container create --name amin --account-name almacenamientoap --account-key $AZURE_STORAGE_KEY
az storage container create --name oscar --account-name almacenamientoap --account-key $AZURE_STORAGE_KEY
az storage container create --name felipe --account-name almacenamientoap --account-key $AZURE_STORAGE_KEY
```

Parámetros clave: `--name` es el nombre del contenedor (en minúsculas), `--account-name` indica a qué cuenta pertenece y `--account-key` autentica la operación usando la variable que guardamos antes. Por defecto, los contenedores se crean como **privados**, lo cual es lo recomendable por seguridad.

### 5. Subir un archivo a un contenedor

Finalmente subimos un archivo local como blob al contenedor `amin`. En este ejemplo subimos un script llamado `comandos.sh` que debe existir en tu directorio actual.

```bash
# Subir un archivo a un contenedor
az storage blob upload --container-name amin --file ./comandos.sh --name comandos.sh --account-name almacenamientoap
```

Parámetros clave: `--container-name` indica el contenedor destino, `--file` es la ruta del archivo local que quieres subir, `--name` es el nombre con el que se guardará el blob en Azure y `--account-name` la cuenta. Si el archivo no existe, el comando fallará; crea uno de prueba antes de ejecutarlo. Para listar lo que ya subiste puedes usar `az storage blob list` agregando `--output table` para verlo en forma de tabla.

## Buenas prácticas de seguridad y costos

* Las **claves de acceso** otorgan control total sobre la cuenta. No las pegues en código fuente ni las subas a un repositorio. Guárdalas en **Azure Key Vault** y, cuando sea posible, prefiere autenticación con **Azure AD (Microsoft Entra ID)** o **tokens SAS** con permisos acotados.
* Cualquier contraseña de ejemplo que veas en estos laboratorios (por ejemplo `Am0_Apr3nd3r$`) es solo de demostración. En entornos reales usa siempre tus propias credenciales fuertes y, mejor aún, claves SSH o secretos gestionados por Key Vault.
* Mantén los contenedores como privados salvo que tengas una razón clara para exponerlos públicamente.
* Para optimizar costos, aprovecha los **niveles de acceso** de los blobs (Hot, Cool, Archive) según la frecuencia con la que consultes los datos: Archive es muy barato para datos que casi nunca se leen.
* Etiqueta tus recursos y revisa periódicamente el consumo para evitar gastos olvidados.

## Limpieza de recursos

Para no generar costos innecesarios, borra todo lo creado en este laboratorio. Eliminar el grupo de recursos borra en cascada la cuenta de almacenamiento, sus contenedores y todos los blobs que contenga.

```bash
az group delete -n grupoAlmacenamiento
```

Este comando pedirá confirmación; puedes agregar `--yes` para omitirla y `--no-wait` si no quieres esperar a que termine. Verifica después con `az group list --output table` que el grupo ya no aparezca.

## Conclusión

Las cuentas de almacenamiento son la base para guardar datos en Azure, y Blob Storage es la opción ideal para archivos y objetos no estructurados. En este laboratorio creaste una cuenta con redundancia LRS, organizaste tus datos en contenedores y subiste tu primer blob desde la CLI. Recuerda elegir el SKU de redundancia según la criticidad de tus datos, proteger tus claves de acceso y limpiar siempre los recursos al terminar para mantener tus costos bajo control.
