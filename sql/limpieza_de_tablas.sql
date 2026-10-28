-- 1. Limpieza básica de la tabla Staging de Productos
UPDATE stg_products
SET product_name = regexp_replace(btrim(product_name), '\s+', ' ', 'g'),
    category = btrim(category),
    subcategory = btrim(subcategory);

-- 2. Carga de la Dimensión de Productos (dim_product) desde Staging Ventas y Staging Productos
INSERT INTO dim_product (product_key, product_id, product_name, category, subcategory, color, size, list_price)
SELECT DISTINCT 
    ProductKey, 
    Product_Code, 
    Product_Name, 
    Category, 
    Subcategory, 
    Color, 
    Size, 
    List_Price
FROM stg_ventas
ON CONFLICT (product_key) DO NOTHING;

-- 3. Carga de la Dimensión de Clientes (dim_customer)
INSERT INTO dim_customer (customer_key, birth_date, marital_status, gender, income, children, home_owner, cars)
SELECT DISTINCT 
    CustomerKey, 
    Birth_Date, 
    Marital_Status, 
    Gender, 
    Income, 
    Children, 
    Home_Owner, 
    Cars
FROM stg_ventas
ON CONFLICT (customer_key) DO NOTHING;

-- 4. Carga de la Dimensión de Fechas (dim_date)
INSERT INTO dim_date (date_key, full_date)
SELECT DISTINCT OrderDateKey, Order_Date FROM stg_ventas
UNION
SELECT DISTINCT ShipDateKey, Ship_Date FROM stg_ventas
ON CONFLICT (date_key) DO NOTHING;

-- 5. Carga de la Tabla de Hechos de Ventas (fact_sales)
INSERT INTO fact_sales (
    order_number, 
    order_line_number, 
    product_key, 
    customer_key, 
    order_date_key, 
    ship_date_key, 
    quantity, 
    unit_price, 
    product_cost, 
    sales_amount
)
SELECT 
    OrderNumber,
    OrderLineNumber,
    ProductKey,
    CustomerKey,
    OrderDateKey,
    ShipDateKey,
    Quantity,
    UnitPrice,
    ProductCost,
    SalesAmount
FROM stg_ventas;