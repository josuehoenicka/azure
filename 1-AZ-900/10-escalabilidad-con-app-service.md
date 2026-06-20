# Escalabilidad con App Service

**Azure App Service** es un servicio administrado (PaaS) para alojar aplicaciones web, APIs y backends móviles sin tener que gestionar el sistema operativo ni la infraestructura subyacente. Una de sus mayores ventajas es la **escalabilidad**: la capacidad de ajustar los recursos que tu aplicación consume según la demanda, sin reescribir tu código.

En App Service la capacidad la define el **plan de App Service** (App Service Plan). Ese plan determina la región, el número de instancias (servidores) y el **SKU** (la "talla" o nivel de precio/recursos: CPU, memoria y características disponibles). Entender cómo crecer ese plan te permite responder a picos de tráfico y pagar solo por lo que necesitas. En este laboratorio crearás la base (grupo de recursos, plan y aplicación web) y verás cómo se escalaría.

## Scale up vs Scale out

Existen dos formas de escalar y conviene no confundirlas:

* **Scale up (escalado vertical)**: aumentas la potencia de cada instancia cambiando el **SKU** del plan. Pasas, por ejemplo, de un nivel gratuito a uno con más CPU y RAM. Es como cambiar un servidor pequeño por uno más grande.
* **Scale out (escalado horizontal)**: aumentas el **número de instancias** que ejecutan tu aplicación en paralelo. En lugar de un servidor más grande, tienes varios servidores iguales repartiéndose la carga detrás de un balanceador.

| Característica        | Scale up (vertical)            | Scale out (horizontal)              |
|----------------------|--------------------------------|-------------------------------------|
| Qué cambia           | El **SKU** (tamaño de la VM)   | El **número de instancias**         |
| Parámetro en CLI     | `--sku`                        | `--number-of-workers`               |
| Analogía             | Un servidor más potente        | Más servidores trabajando juntos    |
| Límite               | Tope del nivel más alto        | Hasta el máximo de instancias del plan |
| Disponibilidad       | No mejora por sí sola          | Mejora (redundancia entre instancias) |

## ¿Qué es el autoescalado (autoscaling)?

El **autoescalado** es el scale out automático basado en reglas. En lugar de cambiar el número de instancias a mano, defines condiciones como "si el uso de CPU supera el 70% durante 10 minutos, agrega una instancia" y "si baja del 30%, quita una". Azure ajusta las instancias dentro de un rango mínimo y máximo que tú estableces.

Beneficios del autoescalado:

* Respondes a picos de tráfico sin intervención manual.
* Reduces costos en horas valle al disminuir instancias.
* Mantienes el rendimiento estable de la aplicación.

> Nota: el autoescalado requiere niveles **Standard (S1)** o superiores. Los niveles **Free** y **Shared** no permiten escalar.

## Laboratorio paso a paso

En este laboratorio usamos la CLI de Azure (`az`). Asegúrate de haber iniciado sesión con `az login` antes de empezar.

### 1. Crear un grupo de recursos

El **grupo de recursos** es el contenedor lógico donde vivirán todos los recursos del laboratorio. Definimos su ubicación con `-l` (región `eastus2`) y su nombre con `-n`.

```bash
# Crear un grupo de recursos
az group create -l eastus2 -n GrupoRecursosEscalables
```

Tener todo en un mismo grupo facilita la administración y, sobre todo, la limpieza al final.

### 2. Crear un plan de App Service

El **plan de servicio** define la capacidad (SKU e instancias) que compartirán las aplicaciones que coloques en él. Lo asociamos al grupo con `-g` y le damos nombre con `-n`.

```bash
# Crear un plan de servicio
az appservice plan create -g GrupoRecursosEscalables -n aminWebEscalable
```

Por defecto se crea con un SKU básico. Puedes añadir `--sku` para elegir el nivel desde el inicio (por ejemplo `--sku S1`) y `--number-of-workers` para fijar las instancias iniciales.

### 3. Crear la aplicación web

Ahora creamos la **aplicación web** y la asociamos al plan con `-p`. El parámetro `-n` define el nombre, que forma parte de la URL pública (`aminespinozaweb.azurewebsites.net`), por lo que debe ser único en todo Azure.

```bash
# Crear una aplicación web
az webapp create -g GrupoRecursosEscalables -p aminWebEscalable -n aminespinozaweb
```

Con esto ya tienes una web funcionando sobre un plan escalable. Puedes agregar `--output table` a cualquiera de estos comandos para ver la respuesta como tabla en lugar de JSON.

## Cómo escalarías esta aplicación

Los comandos anteriores crean la base. El escalado real se hace sobre el plan o la app ya existentes (no necesitas ejecutarlos en este laboratorio, pero conviene conocerlos como prosa):

* **Scale up** (cambiar el SKU del plan):

  ```bash
  az appservice plan update -g GrupoRecursosEscalables -n aminWebEscalable --sku S1
  ```

  Esto mueve el plan a un nivel con más CPU y memoria, y habilita características como el autoescalado.

* **Scale out** (cambiar el número de instancias):

  ```bash
  az appservice plan update -g GrupoRecursosEscalables -n aminWebEscalable --number-of-workers 3
  ```

  Esto pone tres instancias idénticas a repartirse la carga.

El **autoescalado por reglas** se configura con monitor de autoescalado (`az monitor autoscale`) o desde el portal, definiendo métricas como CPU o memoria y un rango de instancias mínimo/máximo.

## Buenas prácticas, costos y seguridad

* **Costos**: el cobro depende del SKU y del número de instancias, no del tráfico. Un plan S1 con 3 instancias cuesta tres veces una. Usa autoescalado para no pagar instancias inactivas.
* **Empieza pequeño**: prueba con SKU bajos y escala cuando las métricas lo justifiquen.
* **Disponibilidad**: para producción usa al menos 2 instancias (scale out) para tolerar fallos de una.
* **Seguridad**: las contraseñas o credenciales que veas en ejemplos (como `Am0_Apr3nd3r$`) son solo de demostración. Nunca las uses en entornos reales; emplea credenciales propias y, mejor aún, **claves SSH** o secretos almacenados en **Azure Key Vault**.

## Limpieza de recursos

Para evitar costos al terminar, elimina todo el grupo de recursos. Al borrar el grupo se borran en cascada el plan y la aplicación web que creaste.

```bash
# Eliminar todos los recursos creados
az group delete -n GrupoRecursosEscalables
```

Azure pedirá confirmación; puedes añadir `--yes` para omitirla y `--no-wait` para no esperar a que termine.

## Conclusión

Azure App Service te permite escalar de dos formas: **scale up** (un plan más potente con `--sku`) y **scale out** (más instancias con `--number-of-workers`), además del **autoescalado** que ajusta instancias por reglas de forma automática. La capacidad la define siempre el plan de App Service, así que diseñar bien ese plan es clave para equilibrar rendimiento y costo. Y recuerda siempre limpiar los recursos que no uses.
