# Zero Trust: almacenamiento seguro

El modelo **Zero Trust** parte de una idea sencilla pero poderosa: ninguna red ni identidad es confiable por defecto. Su lema es "nunca confíes, siempre verifica". En lugar de asumir que todo lo que está dentro de la red corporativa es seguro, Zero Trust verifica cada solicitud de acceso de forma explícita, aplica el menor privilegio posible y asume que una brecha siempre puede ocurrir.

En este laboratorio aplicarás esos principios a un recurso muy común en Azure: una **cuenta de almacenamiento (Storage Account)**. Crearás dos cuentas para comparar: una básica (con la configuración por defecto, más permisiva) y otra endurecida según Zero Trust. Así verás de forma concreta qué banderas de seguridad puedes activar y por qué cada una reduce la superficie de ataque.

## ¿Qué es una cuenta de almacenamiento y por qué endurecerla?

Una cuenta de almacenamiento es el contenedor donde Azure guarda tus blobs, archivos, colas y tablas. Es uno de los servicios más utilizados, y también uno de los blancos más frecuentes de exposición accidental de datos.

Por defecto, una cuenta de almacenamiento permite varias cosas cómodas pero arriesgadas:

* Acceso público a blobs (cualquiera con la URL podría leerlos).
* Autenticación con **claves compartidas (shared keys)**, que son secretos de larga vida difíciles de rotar.
* Acceso desde cualquier red pública de Internet.

Endurecer la cuenta significa desactivar todo lo que no necesitas y obligar a que cada acceso sea verificado, cifrado y acotado a redes de confianza.

## Los tres principios de Zero Trust

Antes del lab, conviene tener claros los principios que vas a aplicar:

| Principio | Qué significa | Cómo lo aplicamos aquí |
| --- | --- | --- |
| **Verificación explícita** | Autentica y autoriza siempre con identidad fuerte | Forzar Azure AD / Entra ID en vez de claves |
| **Privilegio mínimo** | Da solo el acceso estrictamente necesario | Quitar acceso público a blobs |
| **Asumir la brecha** | Diseña como si ya te hubieran comprometido | Cifrado obligatorio (HTTPS/TLS) y red privada |

## Laboratorio paso a paso

### 1. Crear el grupo de recursos

Un **grupo de recursos** es el contenedor lógico donde viven los recursos relacionados. Crearlo primero facilita la limpieza al final, ya que borrar el grupo elimina todo lo que contiene.

```bash
# Crear un grupo de recursos
az group create -l eastus2 -n GrupoRecursosSeguros
```

Parámetros clave:

* `-l eastus2`: la región (location) donde se desplegarán los recursos.
* `-n GrupoRecursosSeguros`: el nombre del grupo.

### 2. Crear una cuenta de almacenamiento básica (insegura)

Esta es la línea base "tal cual sale de fábrica". Sirve como punto de comparación: hereda valores por defecto que son cómodos pero poco seguros.

```bash
# Crear una cuenta de almacenamiento básica (insegura)
az storage account create -n storageiaas004 -g GrupoRecursosSeguros -l eastus2 --sku Standard_LRS
```

Parámetros clave:

* `-n storageiaas004`: nombre de la cuenta (debe ser único a nivel global y en minúsculas).
* `-g GrupoRecursosSeguros`: el grupo donde se crea.
* `--sku Standard_LRS`: nivel de redundancia. **LRS** (Locally Redundant Storage) guarda 3 copias dentro de un mismo centro de datos; es la opción más económica.

> Esta cuenta no aplica restricciones extra: permite TLS antiguo, acceso por clave y exposición a la red pública. Por eso la consideramos insegura.

### 3. Crear una cuenta de almacenamiento endurecida (Zero Trust)

Ahora la versión protegida. Es el mismo comando, pero con un conjunto de banderas que cierran cada puerta innecesaria.

```bash
# Crear una cuenta de almacenamiento endurecida (Zero Trust)
az storage account create -n storageiaas005 -g GrupoRecursosSeguros -l eastus2 --sku Standard_LRS \
  --https-only true \
  --allow-blob-public-access false \
  --allow-shared-key-access false \
  --min-tls-version TLS1_2 \
  --public-network-access disabled
```

Cada bandera se relaciona con un principio Zero Trust:

* **`--https-only true`** — Obliga a que todo el tráfico viaje cifrado por HTTPS y rechaza HTTP en texto plano. Aplica *asumir la brecha*: si alguien intercepta la red, no podrá leer los datos en tránsito.
* **`--allow-blob-public-access false`** — Desactiva la posibilidad de marcar contenedores o blobs como públicos. Aplica *privilegio mínimo*: nadie accede a los datos solo por conocer la URL.
* **`--allow-shared-key-access false`** — Deshabilita la autenticación por clave compartida y **fuerza el uso de Azure AD / Entra ID**. Aplica *verificación explícita*: cada acceso se autentica con una identidad gestionada, con MFA y permisos por rol (RBAC), en vez de un secreto estático.
* **`--min-tls-version TLS1_2`** — Exige al menos TLS 1.2 y rechaza versiones antiguas y vulnerables (TLS 1.0/1.1). Refuerza la *verificación explícita* y el cifrado moderno.
* **`--public-network-access disabled`** — Cierra el acceso desde la Internet pública. La cuenta solo será alcanzable a través de **redes privadas o un private endpoint**. Aplica *asumir la brecha*: reduce drásticamente la superficie expuesta.

> Truco: agrega `--output table` a cualquier comando `az` para ver la respuesta en formato de tabla, más legible que el JSON por defecto.

## Comparación rápida

| Característica | Cuenta básica (004) | Cuenta Zero Trust (005) |
| --- | --- | --- |
| Tráfico HTTP en claro | Permitido | Bloqueado (solo HTTPS) |
| Blobs públicos | Permitidos | Bloqueados |
| Autenticación por clave | Permitida | Bloqueada (solo Entra ID) |
| Versión mínima de TLS | Por defecto | TLS 1.2 |
| Acceso desde Internet | Permitido | Deshabilitado (red privada) |

## Buenas prácticas, costos y seguridad

* **Credenciales de ejemplo:** si en otros labs ves contraseñas como `Am0_Apr3nd3r$`, son solo de demostración. Nunca las uses en entornos reales; emplea credenciales propias y, mejor aún, **claves SSH** o secretos guardados en **Azure Key Vault**.
* **Identidad antes que secretos:** preferir Entra ID sobre claves compartidas evita rotaciones manuales y reduce el riesgo de fugas de secretos.
* **Private endpoints:** al deshabilitar la red pública, planifica cómo se conectarán tus aplicaciones (VNet + private endpoint), o no podrán llegar a la cuenta.
* **Costos:** una cuenta `Standard_LRS` es de bajo costo, pero el almacenamiento, las transacciones y la salida de datos sí generan cargos. Endurecer la seguridad no añade costo extra por las banderas, pero los private endpoints sí tienen un cargo asociado.

## Limpieza de recursos

Para no generar cargos, borra todo lo creado en cuanto termines. Eliminar el grupo de recursos elimina ambas cuentas de almacenamiento de una sola vez.

```bash
az group delete -n GrupoRecursosSeguros
```

Azure pedirá confirmación; puedes añadir `--yes` para omitirla y `--no-wait` para no esperar a que termine.

## Conclusión

Zero Trust no es un producto, sino una forma de diseñar: verificar siempre, dar el mínimo acceso y asumir que la brecha es posible. En este lab tradujiste esos principios en banderas concretas de una cuenta de almacenamiento, comparando una configuración por defecto contra una endurecida. Aplicar estos ajustes desde el primer día es la manera más sencilla y económica de proteger tus datos en Azure.
