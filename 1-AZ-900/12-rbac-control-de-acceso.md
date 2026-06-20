# RBAC: Control de acceso basado en roles

En Azure no basta con crear recursos: también necesitas decidir **quién** puede hacer **qué** y **dónde**. Para eso existe **RBAC** (*Role-Based Access Control*, control de acceso basado en roles), el sistema de autorización que conecta tres piezas: una **identidad** (un usuario, un grupo o una aplicación), un **rol** (un conjunto de permisos) y un **ámbito** (*scope*, el nivel sobre el que aplican esos permisos). Cuando combinas las tres, creas una **asignación de roles** (*role assignment*).

La idea central de RBAC es el **principio de menor privilegio**: cada identidad debe tener únicamente los permisos que necesita para su tarea, ni más ni menos. Esto reduce la superficie de ataque y limita el daño si una credencial se filtra. En este laboratorio crearás varias identidades de aplicación (**service principals**) con distintos roles y ámbitos, para ver en la práctica cómo cambia lo que cada una puede hacer.

## ¿Qué es un rol en RBAC?

Un **rol** es una colección de permisos (acciones permitidas o denegadas). Azure trae muchos roles integrados; estos son los tres más comunes que verás en el examen AZ-900:

| Rol | Qué permite | Caso de uso típico |
| --- | --- | --- |
| **Reader** (Lector) | Solo leer/ver recursos. No puede crear, modificar ni borrar nada. | Auditorías, monitoreo, soporte de solo lectura. |
| **Contributor** (Colaborador) | Crear, modificar y eliminar recursos. **No** puede gestionar acceso (asignar roles a otros). | Equipos de desarrollo y operaciones que despliegan recursos. |
| **Owner** (Propietario) | Todo lo de Contributor **más** la capacidad de gestionar el acceso de otras identidades. | Administradores responsables de la suscripción o el grupo. |

La diferencia clave entre **Contributor** y **Owner** es la gestión de acceso: un Contributor puede levantar una máquina virtual, pero no puede darle permisos a un compañero; un Owner sí.

## ¿Qué es un ámbito (scope)?

El **ámbito** define hasta dónde llega un rol. En Azure los ámbitos forman una jerarquía, y los permisos se **heredan** hacia abajo:

* **Grupo de administración** (management group) → agrupa varias suscripciones.
* **Suscripción** (subscription) → el contenedor de facturación y recursos.
* **Grupo de recursos** (resource group) → una carpeta lógica de recursos.
* **Recurso** individual → una VM, una base de datos, una cuenta de almacenamiento.

Si asignas **Contributor a nivel de suscripción**, esa identidad puede modificar **todos** los grupos de recursos y recursos dentro de la suscripción. Si la asignas **a nivel de un grupo de recursos**, solo puede tocar ese grupo. Aplicar el menor privilegio casi siempre significa **acotar el ámbito** lo más posible: prefiere el grupo de recursos sobre la suscripción cuando puedas.

## ¿Qué es un service principal?

Un **service principal** es una identidad para aplicaciones, scripts o herramientas automatizadas (CI/CD, Terraform, pipelines). En lugar de iniciar sesión como persona, tu automatización se autentica como ese service principal usando un **App ID** y un **secreto** (o un certificado). Es el equivalente a una "cuenta de servicio" sobre la que también aplicas RBAC.

> Advertencia de seguridad: el secreto de un service principal es tan poderoso como sus permisos. Más adelante verás por qué, siempre que sea posible, conviene preferir **identidades administradas** (*managed identities*) en lugar de secretos manuales.

## Laboratorio paso a paso

> En todos los comandos, reemplaza los placeholders `<ID_SUSCRIPCION>`, `<APP_ID>`, `<SECRETO>` y `<ID_TENANT>` por tus propios valores. **Nunca** escribas valores reales en archivos que vayas a compartir o subir a git.

### 1. Crear un service principal con rol Contributor a nivel de suscripción

Este comando crea una identidad de aplicación llamada `ContribuidoresGlobales` y le asigna el rol **Contributor** sobre **toda la suscripción**. El parámetro `--role` define el rol y `--scopes` define el ámbito (aquí, la suscripción completa).

```bash
# Crear un service principal con rol Contributor a nivel de suscripción
az ad sp create-for-rbac -n ContribuidoresGlobales --role Contributor --scopes /subscriptions/<ID_SUSCRIPCION>
```

La salida incluye `appId`, `password` (el secreto) y `tenant`. **Cópialos en un lugar seguro**: el secreto solo se muestra una vez. Este service principal es muy poderoso porque puede modificar cualquier recurso de la suscripción; úsalo con cuidado.

### 2. Crear dos grupos de recursos

Para demostrar ámbitos acotados, crea dos grupos de recursos en la región `eastus2`. El parámetro `-l` indica la ubicación y `-n` el nombre.

```bash
# Crear dos grupos de recursos
az group create -l eastus2 -n GrupoRecursosContribuidores
az group create -l eastus2 -n GrupoRecursosLectores
```

Puedes añadir `--output table` a estos comandos para ver el resultado en una tabla más legible.

### 3. Asignar rol Contributor acotado a un grupo de recursos

Ahora crea un service principal cuyo poder esté **limitado a un solo grupo de recursos**. Fíjate en que `--scopes` ya no apunta a la suscripción, sino a `/resourceGroups/GrupoRecursosContribuidores`. Esto es menor privilegio en acción.

```bash
# Asignar rol Contributor acotado a un grupo de recursos
az ad sp create-for-rbac -n ContribuidoresGrupales --role Contributor --scopes /subscriptions/<ID_SUSCRIPCION>/resourceGroups/GrupoRecursosContribuidores
```

Esta identidad puede crear y borrar recursos **solo** dentro de `GrupoRecursosContribuidores`; si intenta tocar el otro grupo, recibirá un error de autorización.

### 4. Asignar rol Reader acotado a un grupo de recursos

De forma similar, crea una identidad que solo pueda **leer** el segundo grupo de recursos. El rol cambia a **Reader** y el ámbito apunta a `GrupoRecursosLectores`.

```bash
# Asignar rol Reader acotado a un grupo de recursos
az ad sp create-for-rbac -n LectoresGrupales --role Reader --scopes /subscriptions/<ID_SUSCRIPCION>/resourceGroups/GrupoRecursosLectores
```

`LectoresGrupales` podrá listar y ver los recursos de ese grupo, pero cualquier intento de crear, modificar o eliminar fallará.

### 5. Iniciar sesión usando el service principal

Para probar una de estas identidades, inicia sesión como service principal. Usa el `appId` como `--username`, el secreto generado como `--password` y el identificador del directorio como `--tenant`.

```bash
# Iniciar sesión usando el service principal
az login --service-principal --username <APP_ID> --password <SECRETO> --tenant <ID_TENANT>
```

Tras iniciar sesión, intenta crear un recurso en cada grupo: comprobarás que el contexto activo solo puede hacer aquello que su rol y ámbito permiten. Para volver a tu cuenta personal, vuelve a ejecutar `az login` sin parámetros.

## Buenas prácticas, costos y seguridad

* **No commitees secretos a git.** Nunca pegues el `appId`, el `password` ni el `tenant` en el código fuente, en archivos `.env` versionados ni en notas públicas. Si un secreto se filtra, rótalo de inmediato y añádelo a `.gitignore`. Para almacenarlo de forma segura, usa **Azure Key Vault**.
* **Prefiere identidades administradas (managed identities).** Cuando tu aplicación corre dentro de Azure (una VM, App Service, Function, etc.), usa una **managed identity** en lugar de un service principal con secreto: Azure gestiona y rota las credenciales por ti, así que no hay secretos que guardar ni filtrar.
* **Aplica el menor privilegio.** Asigna siempre el rol más restrictivo que cumpla la tarea (Reader antes que Contributor, Contributor antes que Owner) y el ámbito más pequeño posible (recurso o grupo de recursos antes que suscripción).
* **Las credenciales de ejemplo son de demostración.** Cualquier contraseña de muestra que veas en cursos o documentación (por ejemplo `Am0_Apr3nd3r$`) sirve solo para ilustrar; en tus entornos usa **credenciales propias** y, mejor aún, **claves SSH** o **Key Vault** para gestionarlas.
* **Costo:** RBAC en sí no genera cargos; los grupos de recursos tampoco cuestan mientras estén vacíos. El gasto aparece cuando despliegas recursos dentro de ellos, así que recuerda limpiar al terminar.

## Limpieza de recursos

Al finalizar, elimina las identidades y los grupos de recursos para no dejar credenciales activas ni recursos colgando.

```bash
# Eliminar un service principal (repite con cada appId creado)
az ad sp delete --id <APP_ID>

# Eliminar los grupos de recursos
az group delete -n GrupoRecursosContribuidores
az group delete -n GrupoRecursosLectores
```

Si quieres borrar todo un grupo de una sola vez de forma genérica, recuerda que el patrón es `az group delete -n <grupo>`. Borrar el grupo elimina también todos los recursos que contenga, así que asegúrate de no perder nada importante.

## Conclusión

RBAC es el corazón de la autorización en Azure: combina identidad, rol y ámbito para decidir quién puede hacer qué y dónde. Al acotar el ámbito y elegir el rol mínimo necesario aplicas el principio de menor privilegio, y al preferir identidades administradas sobre secretos de service principal reduces drásticamente el riesgo de filtraciones. Practicar con Contributor, Reader y distintos ámbitos te da la intuición que necesitas para diseñar accesos seguros en proyectos reales.
