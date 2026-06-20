# PaaS: Plataforma como Servicio

La **Plataforma como Servicio (PaaS)** es un modelo de cómputo en la nube en el que Azure administra por ti toda la infraestructura subyacente: el hardware, el sistema operativo, los parches de seguridad, el balanceo de carga y los motores que ejecutan tus aplicaciones y bases de datos. Tu responsabilidad se reduce a lo que de verdad aporta valor: tu aplicación y tus datos.

En este laboratorio vas a desplegar varios servicios PaaS representativos con la **Azure CLI**: una base de datos NoSQL con **Cosmos DB**, un servidor de **Azure SQL** y una aplicación web sobre **App Service**. Verás que en ningún momento creas máquinas virtuales ni instalas software: Azure se encarga de eso.

## ¿Qué diferencia hay entre PaaS e IaaS?

En **IaaS (Infraestructura como Servicio)** alquilas recursos crudos (máquinas virtuales, redes, discos) y eres responsable de configurar y mantener el sistema operativo y todo lo que corre encima. En PaaS subes un nivel de abstracción: Azure te entrega un servicio ya listo para usar.

| Aspecto | IaaS | PaaS |
| --- | --- | --- |
| Sistema operativo | Lo gestionas tú | Lo gestiona Azure |
| Parches y actualizaciones | Tu responsabilidad | Automáticos |
| Escalado | Manual o con scripts | Integrado en el servicio |
| Tu foco | Servidores y configuración | Aplicación y datos |
| Ejemplos | Máquinas virtuales, redes | Cosmos DB, Azure SQL, App Service |

La regla práctica: elige **PaaS** cuando quieras desarrollar y publicar rápido sin preocuparte por administrar servidores, y reserva IaaS para cuando necesites control total del entorno.

## Preparar el grupo de recursos

Como siempre, agrupamos todo en un mismo **grupo de recursos** para administrarlo (y borrarlo) en conjunto. Lo creamos en la región `eastus2`.

```bash
# Crear un grupo de recursos
az group create -l eastus2 -n GrupoRecursosPaaS
```

* `-l eastus2` define la ubicación (región) donde vivirán los recursos.
* `-n GrupoRecursosPaaS` es el nombre lógico del grupo.

## Laboratorio paso a paso

### 1. Crear una base de datos Cosmos DB (NoSQL)

**Cosmos DB** es la base de datos NoSQL distribuida globalmente de Azure. Es ideal para datos no estructurados o semiestructurados (JSON, documentos, clave-valor, grafos) que necesitan baja latencia y escalado automático en varias regiones. Como servicio PaaS, no administras servidores de base de datos: solo consumes el endpoint.

```bash
# Crear una base de datos de Cosmos DB
az cosmosdb create --name cosmospaas123 --resource-group GrupoRecursosPaaS
```

* `--name cosmospaas123` es el nombre de la cuenta de Cosmos DB. **Debe ser único globalmente**, porque forma parte de una URL pública (`https://cosmospaas123.documents.azure.com`). Si el nombre ya está tomado, el comando fallará y deberás elegir otro.
* `--resource-group` indica dónde se crea.

> Puedes agregar `--output table` a cualquier comando para ver una salida más legible en forma de tabla.

### 2. Desplegar un servidor de Azure SQL

**Azure SQL** es el motor relacional administrado de Azure, basado en SQL Server. A diferencia de Cosmos DB, está pensado para datos estructurados con esquemas y relaciones. En PaaS, Azure se encarga de las copias de seguridad, los parches y la alta disponibilidad; tú solo gestionas las bases de datos y sus tablas.

```bash
# Desplegar un servidor de SQL
az sql server create -l eastus2 -g GrupoRecursosPaaS -n serverPaas006 -u aminespinoza -p Am0_Apr3nd3r$
```

* `-n serverPaas006` es el nombre del servidor lógico (también único globalmente, ya que genera `serverPaas006.database.windows.net`).
* `-u aminespinoza` define el usuario administrador.
* `-p Am0_Apr3nd3r$` es la contraseña del administrador.

> **Importante sobre seguridad:** la contraseña `Am0_Apr3nd3r$` es solo de demostración. Nunca uses credenciales de ejemplo en entornos reales. Define tu propia contraseña robusta y, mejor aún, almacénala en **Azure Key Vault** en lugar de escribirla en texto plano dentro de tus comandos o scripts.

### 3. Crear un App Service (plan + web app)

**App Service** es la plataforma de Azure para hospedar aplicaciones web y APIs sin administrar servidores. Tiene dos piezas:

* El **plan de App Service** define los recursos de cómputo (CPU, memoria, región y nivel de precio) sobre los que correrán tus aplicaciones.
* La **web app** es la aplicación en sí, que se ejecuta dentro de ese plan.

Primero creamos el plan y luego la web app que lo usa.

```bash
# Crear una web app (junto con un plan de servicio)
az appservice plan create -g GrupoRecursosPaaS -n aminWebPlan
az webapp create -g GrupoRecursosPaaS -p aminWebPlan -n aminespinozaweb
```

* `az appservice plan create` crea el plan `aminWebPlan` dentro del grupo.
* `az webapp create` crea la aplicación `aminespinozaweb` y la asocia al plan con `-p aminWebPlan`.
* `-n aminespinozaweb` también **debe ser único globalmente**, porque será accesible en `https://aminespinozaweb.azurewebsites.net`. Si el nombre está ocupado, elige otro.

## Buenas prácticas, costos y seguridad

* **Nombres únicos:** Cosmos DB, el servidor SQL y la web app exponen URLs públicas, así que sus nombres compiten en un espacio global. Usa prefijos o sufijos propios para evitar colisiones.
* **Costos:** aunque no administres servidores, los servicios PaaS sí generan cargos mientras existen. Cosmos DB cobra por rendimiento (RU/s) y almacenamiento; Azure SQL y App Service cobran según su nivel de precio.
* **Seguridad:** evita contraseñas en texto plano. Apóyate en **Key Vault**, identidades administradas y, donde aplique, **claves SSH** en lugar de contraseñas.
* **Niveles gratuitos/básicos:** para practicar, elige niveles económicos o gratuitos cuando el servicio lo permita.

## Limpieza de recursos

Para no acumular costos, borra todo lo creado en cuanto termines. Al eliminar el grupo de recursos se eliminan en cascada la cuenta de Cosmos DB, el servidor SQL y el App Service.

```bash
# Eliminar todos los recursos creados
az group delete -n GrupoRecursosPaaS
```

* `-n GrupoRecursosPaaS` indica qué grupo borrar. La CLI pedirá confirmación; puedes agregar `--yes` para omitirla y `--no-wait` para no esperar a que termine.

## Conclusión

Con PaaS te enfocas en tu aplicación y tus datos mientras Azure administra la infraestructura. En este laboratorio desplegaste tres servicios administrados (Cosmos DB, Azure SQL y App Service) con unos pocos comandos, sin tocar una sola máquina virtual. Recuerda usar nombres únicos, proteger tus credenciales y eliminar los recursos al finalizar para mantener tus costos bajo control.
