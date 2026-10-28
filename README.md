# Escuela Politécnica Nacional

**Facultad de Ingeniería de Sistemas**  
**Asignatura:** Business Intelligence  
**Práctica 4:** Implementación física de una dimensión para un modelo estrella en PostgreSQL

**Integrantes:** [Escribir los nombres de los integrantes]  
**Fecha:** octubre de 2026  
**Herramientas utilizadas:** PostgreSQL 17, pgAdmin 4, SQL, Markdown y GitHub.  
**Diagrama en Power Pivot:** pendiente de incorporación por el integrante encargado.

> **Sobre las evidencias:** este informe se ha elaborado con los **scripts y las cinco capturas reales compartidas por el grupo**. Los valores que se describen en las preguntas son los que aparecen en pgAdmin, incluso cuando se detectó una inconsistencia con el archivo CSV de ventas. No se sustituyeron las respuestas por otras consultas ni se simularon capturas.

## 1. Introducción

En esta práctica trabajamos con PostgreSQL y pgAdmin 4 para organizar datos de productos y ventas en un modelo dimensional. Partimos de tablas de preparación (*staging*), donde recibimos los archivos CSV; luego usamos tablas de dimensiones para describir productos, clientes y fechas, y una tabla de hechos para almacenar las transacciones de ventas. Finalmente, realizamos cinco consultas SQL para analizar los datos desde diferentes puntos de vista.

Tomamos como referencia de **estructura del informe** la [Práctica 04 del repositorio de Business Intelligence de domdume](https://github.com/domdume/Business-Intelligence/blob/main/Practica%2004/Practica04.md), pero los scripts, nombres de tablas, capturas y resultados que se presentan aquí corresponden a nuestro grupo.

## 2. Objetivos

- Crear tablas para importar datos de productos y ventas.
- Limpiar los nombres y atributos de los productos mediante instrucciones SQL.
- Organizar los datos en dimensiones y una tabla de hechos.
- Relacionar las tablas para responder preguntas sobre productos, clientes, ventas y fechas.
- Ejecutar cinco consultas SQL en pgAdmin y documentar sus resultados con capturas de pantalla.
- Presentar la documentación en Markdown y añadir el diagrama de Power Pivot cuando esté disponible.

## 3. Archivos y datos de entrada

| Archivo | Descripción | Filas del archivo proporcionado |
|---|---|---:|
| [`products.csv`](datos/products.csv) | Catálogo de productos con ID, nombre, categoría y subcategoría. | 699 |
| [`Tabla_Desnormalizada_Ventas.csv`](datos/Tabla_Desnormalizada_Ventas.csv) | Datos de productos, clientes, pedidos, fechas, cantidades, costos y ventas. | 100 |

El archivo `products.csv` contiene **699 productos distintos, 10 categorías y 53 subcategorías**. El archivo de ventas cuenta con **26 columnas** y utiliza el delimitador `;`, por lo que ese separador debe configurarse al importarlo. Al sumar directamente la columna `SalesAmount` de este archivo fuente se obtiene **69.547** y al sumar `Quantity` se obtienen **296 unidades**. Estos totales del archivo fuente se mencionan solamente como punto de comparación, no como sustitución de los resultados de nuestras capturas.

## 4. Desarrollo de la práctica

### 4.1. Creación de tablas (DDL)

En la base de datos `bi_ventas_db` trabajamos desde el **Query Tool** de pgAdmin. El script [`creacion_de_tablas.sql`](sql/creacion_de_tablas.sql) utiliza las instrucciones `DROP TABLE IF EXISTS` y `CREATE TABLE` para definir seis tablas en el esquema `public`.

| Tabla | Función dentro del proyecto |
|---|---|
| `stg_products` | Guarda el archivo de productos durante la preparación de los datos. |
| `stg_ventas` | Guarda las filas originales de ventas antes de repartirlas entre dimensiones y hechos. |
| `dim_product` | Describe el producto, su categoría, subcategoría, color, tamaño y precio de lista. |
| `dim_customer` | Describe al cliente por identificador, género, estado civil y otros atributos. |
| `dim_date` | Relaciona los códigos numéricos de fechas con las fechas completas. |
| `fact_sales` | Contiene los pedidos y los campos cuantitativos (`quantity`, `sales_amount`, etc.). |

En las capturas se observan estas seis tablas bajo **Schemas → public → Tables (6)**, de modo que sabemos que el modelo de trabajo estaba disponible al momento de ejecutar las consultas.

**Claves y relaciones utilizadas:** `fact_sales.product_key` se relaciona con `dim_product.product_key`; `fact_sales.customer_key` con `dim_customer.customer_key`; y las claves `order_date_key` y `ship_date_key` se relacionan con `dim_date.date_key` para representar la fecha de pedido y la fecha de envío.

**Detalle técnico:** en nuestro script, `dim_product.product_key` es `INT PRIMARY KEY` y los valores se cargan desde `stg_ventas`. Esto difiere del ejemplo de la guía, que propone `BIGSERIAL` para la clave sustituta de la dimensión creada desde `products.csv`. Lo dejamos indicado porque así está implementado el trabajo recibido.

### 4.2. Importación a staging

Las tablas de preparación se utilizan para recibir los archivos de origen. En pgAdmin, la importación se realiza desde **clic derecho en la tabla → Import/Export Data → Import**. Los archivos están incluidos en la carpeta [`datos/`](datos/).

| Parámetro | Archivo de productos | Archivo de ventas |
|---|---|---|
| Tabla de destino | `stg_products` | `stg_ventas` |
| Formato | CSV | CSV |
| Codificación | UTF-8 | UTF-8 |
| Encabezado | Sí | Sí |
| Separador | `,` | `;` |

La tabla `stg_products` tiene las columnas `product_id`, `product_name`, `category` y `subcategory`, en el mismo orden en que aparecen los campos del CSV; aunque el encabezado original del archivo puede usar otros nombres, se debe conservar el orden al importar.

> **Evidencia aún no proporcionada:** el grupo compartió las cinco capturas de resultados, pero no una captura de la ventana de configuración de importación. Si la profesora exige documentarla visualmente, hay que incorporarla antes de entregar.

### 4.3. Limpieza y carga (DML)

El archivo [`limpieza_de_tablas.sql`](sql/limpieza_de_tablas.sql) contiene las instrucciones utilizadas para preparar y poblar las tablas. Incluye:

1. **Limpieza de nombres:** aplica `btrim()` y `regexp_replace()` a nombres, categorías y subcategorías de `stg_products`.
2. **Carga de productos:** inserta productos desde `stg_ventas` hacia `dim_product`.
3. **Carga de clientes:** obtiene clientes diferentes desde `stg_ventas` y los inserta en `dim_customer`.
4. **Carga de fechas:** combina fechas de pedido y de envío para poblar `dim_date`.
5. **Carga de hechos:** inserta las líneas de pedidos y las medidas de venta en `fact_sales`.

La limpieza de productos incluida en nuestro archivo es:

```sql
UPDATE stg_products
SET product_name = regexp_replace(btrim(product_name), '\s+', ' ', 'g'),
    category = btrim(category),
    subcategory = btrim(subcategory);
```

El uso de `ON CONFLICT ... DO NOTHING` en las dimensiones permite omitir conflictos de claves durante algunos `INSERT`. La carga de `fact_sales` no incluye una condición equivalente; ejecutar otra vez ese `INSERT` podría duplicar transacciones, por lo que se debe revisar antes de repetirlo.

### 4.4. Estructura dimensional utilizada

```text
                        dim_product
                       product_key (PK)
                              |
                              |
dim_customer ---------- fact_sales ---------- dim_date
customer_key (PK)       sales_id (PK)        date_key (PK)
                              |
                              +-- order_date_key (FK) -> dim_date
                              +-- ship_date_key  (FK) -> dim_date
```

**Tabla de hechos:** `fact_sales` concentra las operaciones, con la cantidad (`quantity`), el monto (`sales_amount`), el precio unitario (`unit_price`) y el costo del producto (`product_cost`). **Dimensiones:** `dim_product` sirve para identificar y agrupar productos, `dim_customer` para analizar características de clientes y `dim_date` para fechas. En el modelo SQL hay tres dimensiones y una tabla de hechos; `stg_products` y `stg_ventas` son tablas de preparación.

### 4.5. Modelo estrella en Power Pivot (pendiente de completar)

> **SECCIÓN RESERVADA PARA EL COMPAÑERO ENCARGADO DE POWER PIVOT.** Todavía no contamos con el diagrama ni con su captura. Esta sección debe completarse antes de la entrega final.

**Diagrama del modelo estrella en Power Pivot:**

> 📷 **[ESPACIO PARA INSERTAR LA CAPTURA DEL DIAGRAMA DE POWER PIVOT]**
>
> Cuando el compañero entregue la imagen, guardarla con el nombre `power_pivot.png` en la carpeta `capturas/` y reemplazar este recuadro por la siguiente línea de Markdown:
>
> `![Diagrama de relaciones del modelo estrella en Power Pivot](capturas/power_pivot.png)`

**Descripción de las relaciones observadas:**

> ✍️ **[PENDIENTE]** Añadir una breve explicación de las tablas que se muestran en el diagrama, sus claves y cómo se relacionan con la tabla de hechos. Verificar que coincida con el modelo realmente construido en Power Pivot; no dar por hecho que será idéntico al de PostgreSQL.

**Responsable:** integrante encargado de Power Pivot. **Estado:** pendiente.

---

## 5. Preguntas de análisis y resultados SQL

Las cinco preguntas de la guía piden **realizar consultas a las tablas, presentar el resultado de pgAdmin y explicar brevemente lo que se observa**. A continuación se incluyen las consultas **sin modificarlas** respecto al archivo [`preguntas.sql`](sql/preguntas.sql) que nos compartieron.

### 5.1. ¿Cuántas ventas se realizaron por categoría de producto y mes?

Esta pregunta busca conocer cuántas transacciones se registraron en cada categoría y en cada mes. Se utilizan `COUNT(f.sales_id)` para contar las ventas y `SUM(f.quantity)` para calcular la cantidad total de unidades. La consulta relaciona la tabla de hechos `fact_sales` con la dimensión `dim_product` mediante `product_key`.

```sql
SELECT 
    p.category,
    SUBSTRING(CAST(f.order_date_key AS VARCHAR), 1, 6) AS anio_mes,
    COUNT(f.sales_id) AS total_ventas_transacciones,
    SUM(f.quantity) AS cantidad_total
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.category, anio_mes
ORDER BY anio_mes, p.category;
```

**Captura 1. Consulta de ventas por categoría y mes**

![Consulta 1: ventas por categoría y mes en pgAdmin](capturas/pregunta_01.jpeg)

**Resultado e interpretación:** pgAdmin muestra **79 filas** agrupadas por categoría y período `YYYYMM`. En las filas visibles se encuentran categorías como *Fruits & Vegetables*, *Snacks & Branded Foods* y *Foodgrains, Oil & Masala*. Las columnas `total_ventas_transacciones` y `cantidad_total` permiten diferenciar el número de operaciones de las unidades vendidas. Por ejemplo, en el período `202202` aparece una fila de *Foodgrains, Oil & Masala* con **2 transacciones y 5 unidades**.

### 5.2. ¿Cuál es el ingreso total (ventas) por cliente y género?

Para responder a esta pregunta agrupamos por el identificador del cliente y su género. La función `SUM(f.sales_amount)` calcula el valor total comprado por cada cliente y permite ordenar desde el ingreso más alto al más bajo.

```sql
SELECT 
    c.customer_key,
    c.gender,
    SUM(f.sales_amount) AS ingreso_total
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.gender
ORDER BY ingreso_total DESC;
```

**Captura 2. Ingreso total por cliente y género**

![Consulta 2: ingreso por cliente y género en pgAdmin](capturas/pregunta_02.jpeg)

**Resultado e interpretación:** la captura contiene **10 clientes**. El cliente **1022**, registrado con género **M**, presenta el mayor ingreso, con **11.656**. Después aparece el cliente **1007**, de género **F**, con **9.928**, seguido del cliente **1043**, también de género **F**, con **9.511**. La consulta ayuda a identificar cuáles clientes registran los mayores montos de compras.

### 5.3. ¿Cuál es la cantidad total vendida por producto?

La tercera consulta suma `quantity` para cada código y nombre de producto. Así podemos ver cuáles productos aparecen con más unidades vendidas en las transacciones registradas.

```sql
SELECT 
    p.product_id,
    p.product_name,
    SUM(f.quantity) AS cantidad_total_vendida
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.product_id, p.product_name
ORDER BY cantidad_total_vendida DESC;
```

**Captura 3. Cantidad total vendida por producto**

![Consulta 3: cantidad total vendida por producto en pgAdmin](capturas/pregunta_03.jpeg)

**Resultado e interpretación:** la captura muestra **9 productos**. El primero es **P0126 — Noodles - Fiery Chilli (Top Ramen)**, con **60 unidades**. Le sigue **P0148 — Sweet Chilli Tortilla Chips (Doritos)** con **41**, y el producto **P0125** con **39** unidades. Esta consulta permite identificar los productos con mayor movimiento en cantidad, sin confundir ese indicador con el dinero ingresado.

### 5.4. ¿Cuál fue la cantidad enviada por mes de envío?

En este caso usamos la clave `ship_date_key` para extraer el año y el mes de envío. Luego agrupamos por ese período y sumamos `quantity`. El objetivo es identificar cuántas unidades se enviaron por mes.

```sql
SELECT 
    SUBSTRING(CAST(f.ship_date_key AS VARCHAR), 1, 6) AS mes_envio,
    SUM(f.quantity) AS cantidad_total_enviada
FROM fact_sales f
GROUP BY mes_envio
ORDER BY mes_envio;
```

**Captura 4. Cantidad enviada por mes**

![Consulta 4: cantidad enviada por mes en pgAdmin](capturas/pregunta_04.jpeg)

**Resultado e interpretación:** pgAdmin presenta **41 filas** correspondientes a períodos de envío. En la captura se observa, por ejemplo, que en `202212` se registran **18 unidades**, mientras que en `202401` se registran **14 unidades**. Ordenar por `mes_envio` facilita comparar las cantidades de un mes a otro sin mezclar años distintos.

### 5.5. ¿Cuánto se vendió por tamaño de producto y por estado civil del cliente?

Esta pregunta combina el tamaño del producto con el estado civil del cliente y calcula `SUM(f.sales_amount)` para cada combinación. En el SQL compartido por el grupo, el tamaño se obtiene de `stg_ventas` y el estado civil de `dim_customer`.

```sql
SELECT 
    v.Size AS tamaño_producto,
    c.marital_status AS estado_civil,
    SUM(f.sales_amount) AS total_vendido
FROM fact_sales f
JOIN stg_ventas v ON f.product_key = v.ProductKey
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY v.Size, c.marital_status
ORDER BY total_vendido DESC;
```

**Captura 5. Total vendido por tamaño y estado civil**

![Consulta 5: ventas por tamaño y estado civil en pgAdmin](capturas/pregunta_05.jpeg)

**Resultado e interpretación:** la consulta devuelve **6 combinaciones**. En las primeras posiciones aparecen **Large / Married** con **279.604**, **Medium / Married** con **254.137** y **Medium / Single** con **115.183**. Los valores mostrados son los obtenidos realmente en la ejecución compartida por el equipo.

**Observación técnica importante:** esta última consulta une `fact_sales` con `stg_ventas` **solo mediante `product_key`**. Como `stg_ventas` tiene varias filas por producto, una fila de ventas puede asociarse con varias filas de staging y multiplicar los importes sumados. Por eso, **los 279.604, 254.137 y demás valores no deben interpretarse como montos reales confirmados de ventas**, aunque sean los valores visibles en pgAdmin. Conservamos la captura y el SQL originales porque documentan lo realizado, y dejamos señalada esta limitación para su revisión.

## 6. Observaciones y validación del trabajo

Los tres scripts y las cinco capturas permiten documentar las tablas creadas, la transformación SQL definida y las respuestas que el equipo ejecutó en pgAdmin. No obstante, al contrastar lo recibido con los dos CSV originales encontramos los siguientes puntos que conviene dejar claros:

- **Catálogo de productos:** `dim_product` se carga desde `stg_ventas` en el script recibido, mientras que la limpieza se aplica a `stg_products`. Por ello, el procedimiento no demuestra una carga de los **699 productos** de `products.csv` a una dimensión independiente como plantea la primera parte de la guía.
- **Preguntas 1 y 3:** las categorías y los nombres de producto que se ven en las capturas no coinciden con los nombres de categorías y productos del archivo `Tabla_Desnormalizada_Ventas.csv` proporcionado. El informe conserva los resultados obtenidos por el grupo sin afirmar que esa correspondencia esté validada.
- **Pregunta 5:** el resultado puede estar inflado por una unión de muchos registros a muchos registros mediante `product_key`. Se conserva como evidencia de ejecución, pero está pendiente de validación antes de presentar conclusiones numéricas.
- **Validaciones de la guía:** no se recibieron capturas de las consultas que comprueban 699 registros, identificadores únicos, categorías, subcategorías y duplicados de `stg_products`.
- **Power Pivot:** el apartado 4.5 queda reservado para incorporar el diagrama y su explicación cuando el compañero lo entregue.

## 7. Conclusiones

La práctica permitió trabajar con una estructura dimensional que separa los datos descriptivos de productos, clientes y fechas de las medidas de venta. También practicamos la creación de tablas en PostgreSQL, la limpieza de datos y el uso de `JOIN`, `GROUP BY`, `COUNT` y `SUM` para realizar análisis de información.

Las consultas muestran cómo una misma tabla de hechos puede analizarse por categoría y mes, por cliente y género, por producto, por fecha de envío o por tamaño y estado civil. Al comparar los resultados también observamos la importancia de revisar las relaciones entre tablas, porque una consulta puede ejecutarse sin errores y aun así sumar importes duplicados.

## 8. Archivos utilizados y evidencias

**Scripts originales del grupo:**

- [Creación de tablas (DDL)](sql/creacion_de_tablas.sql)
- [Limpieza y carga (DML)](sql/limpieza_de_tablas.sql)
- [Las cinco preguntas SQL](sql/preguntas.sql)

**Datos originales:**

- [Catálogo de productos](datos/products.csv)
- [Datos de ventas desnormalizados](datos/Tabla_Desnormalizada_Ventas.csv)

**Capturas originales:**

- [Pregunta 1](capturas/pregunta_01.jpeg)
- [Pregunta 2](capturas/pregunta_02.jpeg)
- [Pregunta 3](capturas/pregunta_03.jpeg)
- [Pregunta 4](capturas/pregunta_04.jpeg)
- [Pregunta 5](capturas/pregunta_05.jpeg)

## 9. Referencias

- Escuela Politécnica Nacional. *Guía Práctica 4: Implementación física de una dimensión para un modelo estrella en PostgreSQL*. Material de clase.
- [Repositorio del año anterior usado como referencia de organización](https://github.com/domdume/Business-Intelligence/blob/main/Practica%2004/Practica04.md).