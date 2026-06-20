# Fundamentos de Azure CLI

**Azure CLI** (el comando `az`) es la herramienta de línea de comandos oficial para crear y administrar recursos de Azure desde una terminal. A diferencia del portal web, donde haces clic manualmente, la CLI te permite escribir comandos que puedes guardar, repetir y automatizar. Esto es clave cuando necesitas crear la misma infraestructura muchas veces o quieres documentar exactamente qué recursos existen y cómo se construyeron.

En este laboratorio aprenderás a instalar la CLI, autenticarte en tu cuenta y crear tus primeros recursos: un **grupo de recursos** y una **cuenta de almacenamiento**. Todo el proceso es reproducible, así que cualquier persona con los mismos comandos obtendrá el mismo resultado.

## ¿Por qué usar Azure CLI en lugar del portal?

El portal de Azure es excelente para explorar y aprender, pero la línea de comandos tiene ventajas importantes:

* **Reproducibilidad:** un mismo conjunto de comandos crea siempre la misma infraestructura.
* **Automatización:** puedes incluir los comandos en scripts o pipelines de CI/CD.
* **Velocidad:** crear un recurso suele ser más rápido escribiendo un comando que navegando varios menús.
* **Documentación viva:** los comandos sirven como registro de qué se creó y con qué parámetros.

## Instalación de Azure CLI

Antes de usar `az` necesitas instalarlo en tu equipo. Microsoft ofrece instaladores para Windows, macOS y Linux:

* **Windows:** descarga el instalador MSI desde la documentación oficial, o usa `winget install Microsoft.AzureCLI`.
* **macOS:** con Homebrew, ejecuta `brew install azure-cli`.
* **Linux:** usa el script oficial o el gestor de paquetes de tu distribución (apt, dnf, etc.).

Una vez instalado, puedes confirmar que funciona y ver la versión instalada:

```bash
az version
```

Si el comando responde con un bloque JSON que muestra la versión, ya estás listo para continuar.

## Iniciar sesión con az login

Para que la CLI pueda crear recursos en tu nombre, primero debes autenticarte. El comando `az login` abre tu navegador para que ingreses tus credenciales de Azure:

```bash
az login
```

Tras iniciar sesión, la terminal muestra las suscripciones asociadas a tu cuenta. Si tienes varias, puedes elegir cuál usar por defecto con `az account set --subscription <id>`.

Para confirmar con qué cuenta y suscripción estás trabajando, usa:

```bash
az account show
```

Este comando devuelve el nombre de la suscripción, su ID y el inquilino (tenant). Es una buena costumbre verificarlo antes de crear recursos, para no construir nada en la suscripción equivocada. Puedes agregar `--output table` para ver la información en formato de tabla en lugar de JSON.

## ¿Qué es un grupo de recursos?

Un **grupo de recursos** (resource group) es un contenedor lógico donde agrupas recursos relacionados: máquinas virtuales, bases de datos, cuentas de almacenamiento, redes, etc. No es un recurso que cueste dinero por sí mismo; es una forma de organización.

¿Por qué importa agrupar recursos?

* **Ciclo de vida común:** los recursos de una misma aplicación suelen crearse y eliminarse juntos. Si borras el grupo, se borra todo lo que contiene de una sola vez.
* **Permisos y control:** puedes asignar roles y políticas a nivel de grupo.
* **Organización y costos:** facilita identificar qué recursos pertenecen a qué proyecto y rastrear su gasto.

Cada recurso de Azure debe pertenecer a exactamente un grupo de recursos y a una **región** (ubicación geográfica del centro de datos).

## Laboratorio paso a paso

### 1. Crear un grupo de recursos

El primer paso es crear el contenedor donde vivirán los demás recursos. Usaremos la región `eastus2` y le daremos el nombre `GrupoRecursosCLI`:

```bash
# Crear un grupo de recursos
az group create -l eastus2 -n GrupoRecursosCLI
```

Los parámetros clave son:

* `-l` (o `--location`): la región donde se ubicará el grupo, en este caso `eastus2`.
* `-n` (o `--name`): el nombre del grupo, `GrupoRecursosCLI`.

Al terminar, la CLI devuelve un JSON con el estado `"provisioningState": "Succeeded"`, lo que confirma que el grupo se creó correctamente. Puedes listar todos tus grupos con `az group list --output table`.

### 2. Crear una cuenta de almacenamiento básica

Una **cuenta de almacenamiento** (storage account) es el recurso que te permite guardar blobs, archivos, colas y tablas en Azure. Ahora crearemos una dentro del grupo que acabamos de crear:

```bash
# Crear una cuenta de almacenamiento básica
az storage account create -n cuentacliamin001 -g GrupoRecursosCLI -l eastus2 --sku Standard_LRS
```

Los parámetros clave son:

* `-n` (o `--name`): el nombre de la cuenta, `cuentacliamin001`. Debe ser **único a nivel global** en todo Azure, usar solo minúsculas y números, y tener entre 3 y 24 caracteres.
* `-g` (o `--resource-group`): el grupo de recursos donde se creará, `GrupoRecursosCLI`.
* `-l` (o `--location`): la región, `eastus2`.
* `--sku`: el nivel de redundancia y rendimiento. `Standard_LRS` (Locally Redundant Storage) es la opción más económica y replica los datos dentro de un mismo centro de datos.

Si el nombre ya está en uso por otra persona en Azure, recibirás un error; en ese caso, cambia el nombre por uno distinto.

## Buenas prácticas, costos y seguridad

* **Credenciales de ejemplo:** si en otros laboratorios ves contraseñas como `Am0_Apr3nd3r$`, recuerda que son solo de demostración. Nunca las uses en entornos reales: define credenciales propias y robustas, y siempre que sea posible prefiere **claves SSH** para máquinas virtuales o guarda los secretos en **Azure Key Vault**.
* **Nombres y convenciones:** adopta una convención de nombres clara (proyecto, entorno, tipo de recurso) para identificar fácilmente cada recurso.
* **Redundancia según el caso:** `Standard_LRS` es barato pero solo protege contra fallos locales. Para datos críticos considera opciones como `Standard_GRS` (replicación geográfica), aunque cuesten más.
* **Etiquetas (tags):** puedes agregar `--tags proyecto=lab az900` para clasificar recursos y rastrear costos.
* **Verifica antes de crear:** confirma siempre tu suscripción con `az account show` para no generar gastos en la cuenta equivocada.

## Limpieza de recursos

Los recursos en la nube pueden generar costos mientras existen, así que es fundamental eliminar lo que ya no necesites. Gracias a que todo está dentro de un mismo grupo de recursos, basta con borrar el grupo para eliminar la cuenta de almacenamiento y cualquier otro recurso que contenga:

```bash
az group delete -n GrupoRecursosCLI
```

La CLI pedirá confirmación antes de borrar. Si quieres omitir la pregunta en un script, puedes agregar `--yes`, y `--no-wait` para que el comando no se quede esperando a que termine el borrado.

## Conclusión

Azure CLI te permite crear y administrar recursos de forma rápida, reproducible y automatizable. En este laboratorio iniciaste sesión, verificaste tu cuenta y creaste un grupo de recursos junto con una cuenta de almacenamiento. Recuerda que el grupo de recursos agrupa todo lo relacionado y te permite eliminarlo en un solo paso, lo cual es la mejor forma de mantener tus costos bajo control.
