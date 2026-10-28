-- 1. Tabla de Staging para Productos
DROP TABLE IF EXISTS stg_products CASCADE;
CREATE TABLE stg_products (
    product_id      VARCHAR(5),
    product_name    VARCHAR(150),
    category        VARCHAR(80),
    subcategory     VARCHAR(80)
);

-- 2. Tabla de Staging para Ventas Desnormalizadas
DROP TABLE IF EXISTS stg_ventas CASCADE;
CREATE TABLE stg_ventas (
    ProductKey       INT,
    Product_Code     VARCHAR(20),
    Product_Name     VARCHAR(100),
    List_Price       NUMERIC,
    Color            VARCHAR(30),
    Size             VARCHAR(30),
    Category         VARCHAR(50),
    Subcategory      VARCHAR(50),
    CustomerKey      INT,
    Birth_Date       DATE,
    Marital_Status   VARCHAR(20),
    Gender           CHAR(1),
    Income           NUMERIC,
    Children         INT,
    Home_Owner       VARCHAR(5),
    Cars             INT,
    OrderDateKey     INT,
    Order_Date       DATE,
    ShipDateKey      INT,
    Ship_Date        DATE,
    OrderNumber      VARCHAR(20),
    OrderLineNumber  INT,
    Quantity         INT,
    UnitPrice        NUMERIC,
    ProductCost      NUMERIC,
    SalesAmount      NUMERIC
);

-- 3. Dimensión de Producto (dim_product)
DROP TABLE IF EXISTS dim_product CASCADE;
CREATE TABLE dim_product (
    product_key  INT PRIMARY KEY,
    product_id   VARCHAR(20),
    product_name VARCHAR(150) NOT NULL,
    category     VARCHAR(80) NOT NULL,
    subcategory  VARCHAR(80) NOT NULL,
    color        VARCHAR(30),
    size         VARCHAR(30),
    list_price   NUMERIC
);

-- 4. Dimensión de Cliente (dim_customer)
DROP TABLE IF EXISTS dim_customer CASCADE;
CREATE TABLE dim_customer (
    customer_key   INT PRIMARY KEY,
    birth_date     DATE,
    marital_status VARCHAR(20),
    gender         CHAR(1),
    income         NUMERIC,
    children       INT,
    home_owner     VARCHAR(5),
    cars           INT
);

-- 5. Dimensión de Tiempo / Fechas (dim_date)
DROP TABLE IF EXISTS dim_date CASCADE;
CREATE TABLE dim_date (
    date_key   INT PRIMARY KEY,
    full_date  DATE
);

-- 6. Tabla de Hechos (fact_sales)
DROP TABLE IF EXISTS fact_sales CASCADE;
CREATE TABLE fact_sales (
    sales_id          BIGSERIAL PRIMARY KEY,
    order_number      VARCHAR(20),
    order_line_number INT,
    product_key       INT REFERENCES dim_product(product_key),
    customer_key      INT REFERENCES dim_customer(customer_key),
    order_date_key    INT REFERENCES dim_date(date_key),
    ship_date_key     INT REFERENCES dim_date(date_key),
    quantity          INT,
    unit_price        NUMERIC,
    product_cost      NUMERIC,
    sales_amount      NUMERIC
);