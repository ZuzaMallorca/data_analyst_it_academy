-- SPRINT 3 BIG QUERY
-- EJERCICIO 1 

CREATE SCHEMA IF NOT EXISTS `sprint3-analytics-zuzanna.sprint3_silver`
OPTIONS (location = 'EU');

-- creando 5 tablas en la capa "sprint3_bronze"
DROP TABLE IF EXISTS `sprint3-analytics-zuzanna.sprint3_bronze.transactions_raw`;
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-zuzanna.sprint3_bronze.transactions_raw`
OPTIONS(
  format ="CSV",
  uris =["gs://bootcamp-data-analytics-public/ERP/transactions.csv"],  
  field_delimiter = ";",
  skip_leading_rows = 1
);
-- creamos la tabla companies, creando esquema de forma manual (viene en formato texto)
DROP TABLE IF EXISTS `sprint3-analytics-zuzanna.sprint3_bronze.companies_raw`;
CREATE EXTERNAL TABLE `sprint3-analytics-zuzanna.sprint3_bronze.companies_raw`
(
  company_id STRING,
  company_name STRING,
  phone STRING,
  email STRING,
  country STRING,
  website STRING
)
OPTIONS(
  format="CSV",
  uris=["gs://bootcamp-data-analytics-public/ERP/companies.csv"],
skip_leading_rows=1
);

-- Creamos la tabla american_users_raw
DROP TABLE IF EXISTS  `sprint3-analytics-zuzanna.sprint3_bronze.american_users_raw`;
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-zuzanna.sprint3_bronze.american_users_raw`
OPTIONS(
  format="CSV",
  uris=["gs://bootcamp-data-analytics-public/CRM/american_users.csv"],
  skip_leading_rows = 1
);
-- Creamos la tabla european_users_raw
DROP TABLE IF EXISTS `sprint3-analytics-zuzanna.sprint3_bronze.european_users_raw`;
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-zuzanna.sprint3_bronze.european_users_raw`
OPTIONS(
  format="CSV",
  uris=["gs://bootcamp-data-analytics-public/CRM/european_users.csv"],
  skip_leading_rows = 1
);
-- Creamos la tabla credit_cards_raw
DROP TABLE IF EXISTS  `sprint3-analytics-zuzanna.sprint3_bronze.credit_cards_raw`;
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-zuzanna.sprint3_bronze.credit_cards_raw`
OPTIONS(
  format="CSV",
  uris=["gs://bootcamp-data-analytics-public/CRM/credit_cards.csv"],
  skip_leading_rows = 1
);
-- IMPORTANTE la tabla products.raw se ha creado en el interfaz (Ejercicio 3)

-- Ejercicio 4
-- 4a Materialización de Datos (Asistido por IA) Crea una tabla nueva llamada sprint3_bronze.transactions_raw_native que sea una copia exacta de tu tabla externa transactions_raw.
-- En mi opinion, la propuesta de IA es correcta, solo la forma es con Los backticks (`).
DROP TABLE IF EXISTS `sprint3-analytics-zuzanna.sprint3_bronze.transactions_raw.native`;
CREATE OR REPLACE TABLE
  `sprint3-analytics-zuzanna`.`sprint3_bronze`.`transactions_raw_native` AS
SELECT
  *
FROM
  `sprint3-analytics-zuzanna`.`sprint3_bronze`.`transactions_raw`;
 
 --4b  consulta para comparar costes entre tabla externa y nativa
 SELECT id
FROM  `sprint3-analytics-zuzanna.sprint3_bronze.transactions_raw`;

 SELECT id
FROM  `sprint3-analytics-zuzanna.sprint3_bronze.transactions_raw.native`;

-- 4c El peligro del LIMIT ¿LIMITE ahorra datos procesados ​​en BIGQUERY?
 SELECT *
FROM  `sprint3-analytics-zuzanna.sprint3_bronze.transactions_raw.native`;
 SELECT *
FROM  `sprint3-analytics-zuzanna.sprint3_bronze.transactions_raw`;

 SELECT id
FROM  `sprint3-analytics-zuzanna.sprint3_bronze.transactions_raw.native`;

-- Ejercicio 5
-- elegimos 5 dias de 2021 con mayores ventas
SELECT CAST(timestamp AS DATE) as fecha,ROUND(SUM(amount),2) AS totales -- tenemos que convertir string a fecha para poder agrupar por dia.
FROM  sprint3-analytics-zuzanna.sprint3_bronze.transactions_raw_native
WHERE declined =0 AND EXTRACT(YEAR FROM timestamp) = 2021 -- filtramos por año y elegimos solo trans aceptadas
GROUP BY fecha
ORDER BY totales DESC LIMIT 5;

-- Ejercicio 6 Lista el nombre, país y fecha de las transacciones realizadas por empresas que realizaron operaciones entre 100 y 200 euros en alguna de estas fechas: 29-04-2015, 20-07-2018 o 13-03-2024.

SELECT c.company_id, c.company_name, c.country, DATE(t.timestamp) AS transaction_date FROM
`sprint3-analytics-zuzanna.sprint3_bronze.transactions_raw` t
JOIN `sprint3-analytics-zuzanna.sprint3_bronze.companies_raw` c 
ON c.company_id=t.business_id 
WHERE t.amount BETWEEN 100 AND 200 AND CAST(timestamp AS date) IN ("2015-04-29", "2018-07-20", "2024-03-13")
ORDER BY c.company_name;

-- NIVEL 2
-- Ejercicio 1
-- Limpieza de Productos (Data Quality) Crearemos la capa limpia ("Silver") para los productos. Tienes la mesa sprint3_bronze.products_raw cargada desde el CSV. El equipo de Data Governance te pide crear una mesa de productos limpia a sprint3_silver.products_clean.
DROP TABLE IF EXISTS  `sprint3-analytics-zuzanna.sprint3_silver.products_clean`;
CREATE OR REPLACE TABLE `sprint3-analytics-zuzanna.sprint3_silver.products_clean` AS
SELECT
id AS product_id,
product_name AS name,
SAFE_CAST(price AS FLOAT64) AS price,-- cabiamos al num entero
colour,
weight,
SAFE_CAST(REPLACE(warehouse_id, "WH-", '')AS INT64) AS warehouse_id 
FROM
`sprint3-analytics-zuzanna.sprint3_bronze.products_raw`
;
-- Ejercicio 2
-- Creación de Transacciones Limpias (Capa Silver) La tabla transactions_raw (Bronze) es insegura: el importe (amount) podría tener letras, las coordenadas podrían fallar y la fecha es un texto difícil de filtrar. Crearemos la mesa definitiva sprint3_silver.transactions_clean que garantice lo siguiente.

DROP TABLE IF EXISTS `sprint3-analytics-zuzanna.sprint3_silver.transactions_clean`;
CREATE OR REPLACE TABLE `sprint3-analytics-zuzanna.sprint3_silver.transactions_clean` AS
SELECT
id AS transaction_id,
card_id,
business_id,
timestamp,-- ya es de tipo TIMESTAMP así que no cambio nada
IFNULL(SAFE_CAST(amount AS FLOAT64),0) AS amount,
declined,
ARRAY(SELECT CAST(id AS INT64)
    FROM UNNEST(SPLIT(product_ids, ',')) AS id
) AS product_ids, --tenems que separar la cadena de string y despues  convertir al num entero.
user_id,
SAFE_CAST(lat AS FLOAT64) AS lat,
SAFE_CAST(longitude AS FLOAT64) as longitude
FROM
`sprint3-analytics-zuzanna.sprint3_bronze.transactions_raw`;

-- Ejercicio 3 Unificación de Usuarios (UNION) Tenemos a los usuarios fragmentados por región.
-- Crea la mesa sprint3_silver.users_combined. Utiliza UNION ALLpara unificar a los usuarios de EE.UU. y Europa en una única lista maestra. Añade una columna calculada origin para saber de dónde vienen.

CREATE OR REPLACE TABLE `sprint3-analytics-zuzanna.sprint3_silver.users_combined` AS
SELECT
id AS user_id,
 name, surname,phone, email,birth_date,country,city, postal_code,address, "EU"AS region
 FROM
`sprint3-analytics-zuzanna.sprint3_bronze.european_users_raw`
UNION ALL
SELECT
id AS user_id,
 name, surname,phone, email,birth_date,country,city, postal_code,address, "US"AS region
FROM
`sprint3-analytics-zuzanna.sprint3_bronze.american_users_raw`
;
-- EJERCICIO 4  Materialización de Compañías y Tarjetas de Crédito
-- Para completar el modelo de datos en la capa Silver, nos faltan dos dimensiones clave: Compañías y Tarjetas de Crédito. Ahora mismo sólo existen como tablas externas en la capa Bronce (companies_raw y credit_cards_raw), que leen los CSV del Data Lake cada vez que se consultan. Para el análisis final necesitamos tablas nativas en Silver, construidas a partir de Bronce.
DROP TABLE IF EXISTS `sprint3-analytics-zuzanna.sprint3_silver.companies_clean`;
CREATE OR REPLACE TABLE `sprint3-analytics-zuzanna.sprint3_silver.companies_clean` AS
SELECT *
FROM
`sprint3-analytics-zuzanna.sprint3_bronze.companies_raw`
;
DROP TABLE IF EXISTS `sprint3-analytics-zuzanna.sprint3_silver.credit_cards_clean`;
CREATE OR REPLACE TABLE `sprint3-analytics-zuzanna.sprint3_silver.credit_cards_clean` AS
SELECT
id as card_id,
user_id,
iban,
pan,
pin,
cvv,
track1,
track2,
expiring_date
FROM `sprint3-analytics-zuzanna.sprint3_bronze.credit_cards_raw`;

-- NIVEL 3
-- Ejercicio 1 VISTA
--Marketing necesita segmentar a los clientes corporativos, pero no saben hacer JOINs. Su tarea es dejarles la información preparada
--Crea una vista llamada sprint3_gold.v_marketing_kpis que muestre la siguiente información para cada compañía:
CREATE OR REPLACE VIEW `sprint3-analytics-zuzanna.sprint3_gold.v_marketing_kpis`AS 
SELECT c.company_id,c.company_name, c.phone, c.country, ROUND(AVG(t.amount),2) AS media_compra, 
CASE 
	WHEN ROUND(AVG(t.amount),2) > 260 THEN "Premium"
    ELSE "Standard"
END AS client_tier
 FROM `sprint3-analytics-zuzanna.sprint3_silver.companies_clean`c 
 JOIN `sprint3-analytics-zuzanna.sprint3_silver.transactions_clean` t
 ON c.company_id=t.business_id
 WHERE t.declined=0
 GROUP BY c.company_i,c.company_name, c.phone, c.country
;

-- Consulta en la vista
SELECT * FROM `sprint3-analytics-zuzanna.sprint3_gold.v_marketing_kpis`
ORDER BY client_tier, media_compra DESC;

-- EJERCICIO 2 ARRAY/UNNEST Ranking de Productos (La Potencia de los Arrays)
-- El equipo de ventas desea optimizar el catálogo. Necesitan un informe en la capa Gold que muestre el rendimiento real de cada producto. Gracias a tu buena ingeniería en la capa Silver, la mesa transactions_clean ya tiene los IDs de producto perfectamente organizados en una lista (Array). Ahora toca explotar esa estructura. Crea la tabla sprint3_gold.product_sales_ranking que contenga el inventario completo de productos y cuántas veces se ha vendido cada uno.
CREATE OR REPLACE table `sprint3-analytics-zuzanna.sprint3_gold.product_sales_ranking` AS
WITH  transact_unnested AS (
SELECT product_ids_separados
FROM `sprint3-analytics-zuzanna.sprint3_silver.transactions_clean`, 
UNNEST(product_ids) AS product_ids_separados
)

SELECT p.product_id AS id, p.name, p.price, p.colour,IFNULL(COUNT(t.product_ids_separados),0) AS total_sold
FROM `sprint3-analytics-zuzanna.sprint3_silver.products_clean` p
LEFT JOIN transact_unnested t
ON p.product_id=t.product_ids_separados
GROUP BY 1,2,3,4
ORDER BY total_sold DESC;


-- consulta para sacar resultados
SELECT * FROM `sprint3-analytics-zuzanna.sprint3_gold.product_sales_ranking`;