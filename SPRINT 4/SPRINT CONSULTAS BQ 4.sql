--nivel 1 Ejercicio 1 Consulta sobre Tabla no Optimizada (Diagnóstico)
SELECT t.transaction_id, c.company_id, c.company_name, c.country, Date(t.timestamp) as fecha
FROM `sprint3-analytics-zuzanna.sprint3_silver.companies_clean` c
JOIN `sprint3-analytics-zuzanna.sprint3_silver.transactions_clean` t
ON t.business_id=c.company_id
WHERE c.country="Germany" AND Date(t.timestamp) ="2022-03-12";

-- Ejercicio 2 Primera parte-- Generación  de  Datos Recientes (Mocking Data)  
CREATE OR REPLACE TABLE `sprint3-analytics-zuzanna.sprint3_silver.transactions_recent` AS
SELECT *EXCEPT(timestamp),
TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL CAST(RAND() *50 as INT64) DAY -- fecha de hoy menos un numero random
) AS timestamp
FROM `sprint3-analytics-zuzanna.sprint3_silver.transactions_clean`;

-- EJERCICIO 2 
CREATE OR REPLACE TABLE `sprint3-analytics-zuzanna.sprint3_gold.fact_transactions_optimized`
PARTITION BY DATE(timestamp) -- son clausulas de definicion de tabla por eso van fuera del AS
CLUSTER BY business_id -- son clausulas de definicion de tabla por eso van fuera del AS
-- aqui aprendi que deberiamos añadir esta medida para controlar los costes y evitar escanear innecesariamente toda la tabla.
--OPTIONS(require_partition_filter=true) no lo aplico en este ejercicio porque lo conoci a posteriori
AS SELECT *
FROM `sprint3-analytics-zuzanna.sprint3_silver.transactions_recent`;
--Ejercicio 3 comparando tabla optimizada y no optimizada
-- primero codigo SQL con tabla sin optimizar.
SELECT *
FROM  `sprint3-analytics-zuzanna.sprint3_silver.transactions_clean`
WHERE timestamp BETWEEN
    TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    AND CURRENT_TIMESTAMP();
-- ahora la misma consulta pero sobre la tabla optimizada
SELECT *
FROM  `sprint3-analytics-zuzanna.sprint3_gold.fact_transactions_optimized`
WHERE timestamp BETWEEN
    TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    AND CURRENT_TIMESTAMP();

-- Ejercicio 4 VISTA MATERIALIZADA DE VENTAS DIARIAS
-- creamos la vista
CREATE OR REPLACE MATERIALIZED VIEW `sprint3-analytics-zuzanna.sprint3_gold.mv_daily_sales`AS
SELECT Date(timestamp) AS transaction_day,SUM(AMOUNT) AS total_day --no me dejaba crear la vista usando el ROUND asi que lo uso en la consulta posterior
FROM `sprint3-analytics-zuzanna.sprint3_gold.fact_transactions_optimized`
WHERE declined=0
GROUP BY transaction_day
;
--Mostramos la vista
SELECT * FROM `sprint3-analytics-zuzanna.sprint3_gold.mv_daily_sales`;

-- NIVEL 2 SQL ANALITICO AVANZADO
--Definimos "VIP" como aquellos con un gasto acumulado superior a 500 €. Necesitan un informe que, para cada VIP, muestre su nombre, contacto y su patrón de compra: cuántas veces ha comprado, cuánto gasta de media y cuál fue su compra récord.
-- Ejercicio 1 Consulta con CTE-s
WITH VIP_Stats AS 
(SELECT user_id, ROUND(SUM(amount),2) AS total_spent, COUNT(transaction_id) AS num_trans,
ROUND(AVG(amount),2) AS avg_ticket,MAX(amount) AS ticket_max 
FROM `sprint3-analytics-zuzanna.sprint3_gold.fact_transactions_optimized`
WHERE declined=0
GROUP BY user_id
HAVING SUM(amount) > 500)--FILTRO

SELECT u.user_id, CONCAT(u.name,' ', u.surname) AS full_name, u.email,v.num_trans,v.avg_ticket, v.ticket_max, v.total_spent
FROM `sprint3-analytics-zuzanna.sprint3_silver.users_combined` u
JOIN Vip_Stats v 
USING(user_id)
ORDER BY v.total_spent DESC
;

-- Ejercicio 2  Análisis de Tendencias (Window Functions sobre Vistas)
SELECT transaction_day AS Fecha,
 total_day AS Ventas_hoy,
ROUND(LAG(total_day) OVER(ORDER BY transaction_day),2) AS Ventas_ayer,
ROUND(SAFE_DIVIDE(total_day-LAG(total_day) OVER(ORDER BY transaction_day),LAG(total_day) OVER(ORDER BY transaction_day))*100,2) AS  Diff_Percentual -- SAFE_DIVIDE() es una función de BigQuery que realiza una división de forma segura, evitando errores cuando el denominador es 0.
FROM `sprint3-analytics-zuzanna.sprint3_gold.mv_daily_sales`
ORDER BY Fecha;
-- LAG() devuelve NULL para el primer día porque no existe un día anterior.
-- SAFE_DIVIDE() devuelve NULL si el denominador es cero, evitando errores.

-- Ejercicio 3 Sobre la misma VENTANA MATERIALIZADA Calculamos totales_acumulados (YEAR TO DATE YTD)
SELECT transaction_day as Fecha,ROUND(total_day,2) AS Ventas_diarias,
 ROUND(SUM(total_day) OVER (PARTITION BY EXTRACT(YEAR from transaction_day)
ORDER BY transaction_day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),2) AS Ventas_acumuladas
FROM `sprint3-analytics-zuzanna.sprint3_gold.mv_daily_sales`
ORDER BY Fecha;


--Ejercicio 4 Fidelización y Valor del Cliente Calculando tres primeras compras y la media

SELECT u.user_id,CONCAT(u.name, ' ', u.surname) AS full_name,u.email, t.timestamp AS fecha,t.amount AS tercera_compra, 
-- Calculamos la media de tres primeras compras
ROUND(AVG(t.amount) OVER (PARTITION BY t.user_id ORDER BY t.timestamp ASC, t.transaction_id ASC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),2) AS media -- como current row, en este caso,es 3a fila, limitamos la ventana a 3 filas.
FROM `sprint3-analytics-zuzanna.sprint3_silver.users_combined` u
JOIN `sprint3-analytics-zuzanna.sprint3_gold.fact_transactions_optimized`  t
ON u.user_id=t.user_id
WHERE t.declined=0
QUALIFY ROW_NUMBER() OVER (PARTITION BY t.user_id ORDER BY t.timestamp ASC) =3 --conserva exclusivamente la tercera compra de cada usuario.
ORDER BY user_id;

--Nivel 3 Ejercicio 1: Desanimiento y Allanamiento de Datos (Unnesting)
--Crea la tabla dim_transactions_flat desnormalizando la información. Tienes que "explotar" el array de productos y cruzarlo con el catálogo maestro para obtener los nombres y precios individuales.

CREATE OR REPLACE TABLE `sprint3-analytics-zuzanna.sprint3_gold.dim_transactions_flat` AS( 
SELECT t.transaction_id,t.timestamp,ROUND(t.amount,2) AS global_ticket,p.product_id, p.name,p.price  
FROM `sprint3-analytics-zuzanna.sprint3_gold.fact_transactions_optimized` t
CROSS JOIN UNNEST(t.product_ids) AS unnest_product_ids --CROSS JOIN pudimos reemplazar con coma
JOIN `sprint3-analytics-zuzanna.sprint3_silver.products_clean` p
ON p.product_id=CAST(unnest_product_ids AS INT64)
WHERE declined=0
);
--Comprobamos el resultado
SELECT * FROM `sprint3-analytics-zuzanna.sprint3_gold.dim_transactions_flat`
LIMIT 10;

--NIVEL 3- Ejercicio 2 TOP 5 productos mas vendidos en la historia de la empresa
SELECT name, COUNT(*) AS num_ventas
FROM `sprint3-analytics-zuzanna.sprint3_gold.dim_transactions_flat`
GROUP BY name
ORDER BY num_ventas DESC
LIMIT 5;

--NIVEL 3-Ejercicio 3 Anadimos funcion para calcular IVA y creamos Scheduled Query para actualizar en informe todos los días, 7AM
--primero creamos funcion  
CREATE OR REPLACE FUNCTION `sprint3-analytics-zuzanna.sprint3_gold.calculate_tax` (amount FLOAT64)
 returns FLOAT64 AS (
  ROUND(amount*1.21,2)
  );

--ahora actualizamos la tabla dim_transactions_flat, aplicando la funcion y creando nueva columna


CREATE OR REPLACE TABLE `sprint3-analytics-zuzanna.sprint3_gold.dim_transactions_flat` AS( 
SELECT t.transaction_id,t.timestamp,ROUND(t.amount,2) AS global_ticket,p.product_id, p.name,p.price, 
`sprint3-analytics-zuzanna.sprint3_gold.calculate_tax`(p.price) AS price_with_vat  
FROM `sprint3-analytics-zuzanna.sprint3_gold.fact_transactions_optimized` t
CROSS JOIN UNNEST(t.product_ids) AS unnest_product_ids
JOIN `sprint3-analytics-zuzanna.sprint3_silver.products_clean` p
ON p.product_id=CAST(unnest_product_ids AS INT64)
WHERE declined=0
);

SELECT * FROM `sprint3-analytics-zuzanna.sprint3_gold.dim_transactions_flat`
ORDER BY transaction_id
LIMIT 30;


