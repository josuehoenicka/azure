# Cómputo en Azure: VMs, Containers y Functions

El **cómputo** es uno de los pilares de cualquier nube: se refiere a la capacidad de procesamiento que ejecuta tus aplicaciones, scripts y servicios. Azure ofrece varias opciones de cómputo que cubren un espectro completo, desde el control total de una máquina virtual (**IaaS**) hasta modelos **serverless** donde solo pagas por cada ejecución. Elegir bien entre ellas impacta directamente en tu costo, tu velocidad de desarrollo y la cantidad de mantenimiento que tendrás que asumir.

En este laboratorio práctico crearás los tres servicios de cómputo más representativos: una **Máquina Virtual**, una **Container App** y una **Function App**. Al final entenderás cuándo conviene cada uno y cómo desplegarlos con la CLI de Azure.

## ¿Qué opciones de cómputo ofrece Azure?

Aunque Azure tiene muchos servicios, estos tres representan los tres grandes modelos de responsabilidad:

* **Máquinas Virtuales (VM):** infraestructura como servicio (IaaS). Tienes control total sobre el sistema operativo, los paquetes instalados y la configuración. A cambio, tú administras parches, seguridad y escalado.
* **Container Apps:** contenedores administrados. Empaquetas tu aplicación en una imagen de contenedor y Azure se encarga de ejecutarla, escalarla y mantenerla, sin que gestiones servidores directamente.
* **Function Apps:** cómputo serverless. Subes pequeñas piezas de código (funciones) que se ejecutan en respuesta a eventos. No piensas en servidores y pagas únicamente por el tiempo de ejecución.

## ¿Cuándo conviene cada uno?

| Servicio | Modelo | Control | Escalado | Pago | Ideal para |
|---|---|---|---|---|---|
| **Máquina Virtual** | IaaS | Total (SO completo) | Manual o por reglas | Por tiempo encendida | Software heredado, control total, configuraciones especiales |
| **Container App** | Contenedores administrados | Medio (la imagen) | Automático | Por uso/recursos | Microservicios, apps portables, despliegues con Docker |
| **Function App** | Serverless | Bajo (solo el código) | Automático | Por ejecución | Tareas event-driven, APIs ligeras, procesos esporádicos |

Una regla práctica: cuanto más a la derecha de la tabla, menos te preocupas por la infraestructura, pero menos control tienes sobre el entorno.

## Laboratorio paso a paso

> **Nota de seguridad:** las contraseñas de ejemplo como `Am0_Apr3nd3r$` son solo de demostración. En entornos reales usa credenciales propias y robustas, y de ser posible **claves SSH** o secretos almacenados en **Azure Key Vault** en lugar de contraseñas en texto plano.

### 1. Crear el grupo de recursos

Todo en Azure vive dentro de un **grupo de recursos**, que actúa como contenedor lógico para organizar y, sobre todo, borrar recursos en conjunto. Aquí defines el nombre y la región (`eastus2`).

```bash
# Crear un grupo de recursos
az group create --name grupoRecursosComputo --location eastus2
```

### 2. Crear una Máquina Virtual (IaaS)

Con `az vm create` levantas una VM completa. Los parámetros clave son:

* `-n` (nombre de la VM) y `-g` (grupo de recursos).
* `--image` define el sistema operativo; aquí usamos `Ubuntu2204`.
* `--admin-username` y `--admin-password` configuran el usuario administrador.

```bash
# Crear una máquina virtual
az vm create -n compute-vm-amin -g grupoRecursosComputo --image Ubuntu2204 --admin-username aminespinoza --admin-password Am0_Apr3nd3r$
```

Tienes control total sobre esta VM: puedes conectarte por SSH, instalar lo que quieras y configurar el sistema a tu gusto. La contraparte es que eres responsable de mantenerla y de su costo mientras esté encendida.

### 3. Crear una Container App (contenedores administrados)

Las Container Apps necesitan primero un **entorno** (environment), que es la frontera de red y observabilidad donde se ejecutarán tus contenedores. Luego creas la aplicación a partir de una imagen.

```bash
# Crear el entorno de Container Apps
az containerapp env create -n ComputoEnvironment -g grupoRecursosComputo --location eastus2

# Crear la container app
az containerapp create -n computocontainerapp -g grupoRecursosComputo --image docker.io/aminespinoza/linktree:latest --environment ComputoEnvironment --ingress external --target-port 80
```

Parámetros clave del segundo comando:

* `--image` apunta a la imagen de contenedor (en este caso desde Docker Hub).
* `--environment` la asocia al entorno que creaste antes.
* `--ingress external` la expone públicamente a internet.
* `--target-port 80` indica el puerto donde escucha la aplicación dentro del contenedor.

Aquí ya no administras el servidor: solo entregas la imagen y Azure la ejecuta y escala por ti.

### 4. Crear una Function App (serverless)

Una Function App requiere una **cuenta de almacenamiento** para guardar su estado, logs y artefactos. Primero la creas y luego la Function App que la utiliza.

```bash
# Crear la cuenta de almacenamiento
az storage account create --name almacenamientofuncion52 --location eastus2 --resource-group grupoRecursosComputo --sku Standard_LRS

# Crear la Function App
az functionapp create --resource-group grupoRecursosComputo --consumption-plan-location eastus2 --name function-app-amin --storage-account almacenamientofuncion52 --runtime dotnet
```

Parámetros clave:

* `--sku Standard_LRS` define almacenamiento redundante local, la opción más económica.
* `--consumption-plan-location` activa el **plan de consumo**: el modelo serverless donde pagas solo por ejecución.
* `--runtime dotnet` indica el lenguaje/runtime de las funciones.

Con esto tienes cómputo que se activa por eventos y se cobra por uso, sin servidores que mantener.

> Tip: agrega `--output table` a los comandos de consulta (por ejemplo al listar recursos) para ver una salida más legible en formato de tabla.

## Buenas prácticas, costos y seguridad

* **Costos:** la VM genera costo mientras esté encendida aunque no la uses; las Container Apps y Functions tienden a ser más eficientes porque escalan según la demanda (incluso a cero).
* **Seguridad:** evita contraseñas en línea de comandos. Prefiere claves SSH para VMs y guarda secretos en **Azure Key Vault**. Restringe el `--ingress` a `internal` si la app no necesita ser pública.
* **Organización:** mantén todo dentro de un mismo grupo de recursos para poder auditarlo y eliminarlo fácilmente.
* **Región:** ubica los recursos cerca de tus usuarios y en la misma región para reducir latencia y costos de transferencia.

## Limpieza de recursos

Para no generar costos innecesarios, elimina todo lo creado en cuanto termines el laboratorio. Al borrar el grupo de recursos se eliminan en cascada la VM, la Container App, el entorno, la cuenta de almacenamiento y la Function App.

```bash
# Borrar el grupo de recursos y todo su contenido
az group delete --name grupoRecursosComputo
```

Puedes agregar `--yes --no-wait` para confirmar automáticamente y no esperar a que termine el borrado.

## Conclusión

Azure cubre todo el espectro de cómputo: las **Máquinas Virtuales** te dan control total con responsabilidad de IaaS, las **Container Apps** equilibran portabilidad y administración gestionada, y las **Function Apps** llevan al extremo el modelo serverless pagando solo por ejecución. La clave está en elegir según cuánto control necesitas y cuánta infraestructura quieres administrar. Y recuerda siempre limpiar los recursos para mantener tu factura bajo control.
