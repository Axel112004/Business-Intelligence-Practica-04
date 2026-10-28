-- 1. ¿Cuántas ventas se realizaron por categoría de producto y mes?
SELECT 
    p.category,
    SUBSTRING(CAST(f.order_date_key AS VARCHAR), 1, 6) AS anio_mes,
    COUNT(f.sales_id) AS total_ventas_transacciones,
    SUM(f.quantity) AS cantidad_total
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.category, anio_mes
ORDER BY anio_mes, p.category;


-- 2. ¿Cuál es el ingreso total (ventas) por cliente y género?
SELECT 
    c.customer_key,
    c.gender,
    SUM(f.sales_amount) AS ingreso_total
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.gender
ORDER BY ingreso_total DESC;


-- 3. ¿Cuál es la cantidad total vendida por producto?
SELECT 
    p.product_id,
    p.product_name,
    SUM(f.quantity) AS cantidad_total_vendida
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.product_id, p.product_name
ORDER BY cantidad_total_vendida DESC;


-- 4. ¿Cuál fue la cantidad enviada por mes de envío?
SELECT 
    SUBSTRING(CAST(f.ship_date_key AS VARCHAR), 1, 6) AS mes_envio,
    SUM(f.quantity) AS cantidad_total_enviada
FROM fact_sales f
GROUP BY mes_envio
ORDER BY mes_envio;


-- 5. ¿Cuánto se vendió por tamaño de producto y por estado civil del cliente?
SELECT 
    v.Size AS tamaño_producto,
    c.marital_status AS estado_civil,
    SUM(f.sales_amount) AS total_vendido
FROM fact_sales f
JOIN stg_ventas v ON f.product_key = v.ProductKey
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY v.Size, c.marital_status
ORDER BY total_vendido DESC;