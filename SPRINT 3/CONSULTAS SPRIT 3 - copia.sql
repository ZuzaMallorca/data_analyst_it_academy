SELECT DISTINCT c.country FROM company c
JOIN transaction t ON c.id=t.company_id;
-- Identifica a la compañía con la mayor media de ventas
USE transactions;
SELECT c.company_name, ROUND(AVG(t.amount) OVER (PARTITION BY c.company_name),2) AS media_ventas 
FROM company c
JOIN transaction t 
ON c.id=t.company_id
ORDER BY media_ventas DESC
LIMIT 1;

-- Muestra todas las transacciones realizadas por empresas de Alemania.
SELECT id FROM transaction 
WHERE company_id IN (
SELECT id FROM company
WHERE country = "Germany");
-- Lista las empresas que han realizado transacciones por un monto superior a la media de todas las transacciones.

SELECT company_name FROM company
WHERE id IN (
	SELECT company_id FROM transaction
		WHERE amount > (SELECT  AVG(amount) FROM transaction )

        )
 ORDER BY company_name DESC;
 
 SELECT  * FROM company c
WHERE c.id NOT IN (
	SELECT company_id
	FROM transaction 
    WHERE company_id IS NOT NULL);
    
SELECT c.company_name FROM company c
LEFT JOIN transaction t
ON c.id=t.company_id
WHERE t.company_id IS NULL;

SELECT u.name, u.surname, COUNT( t.id) AS num_trans FROM users u 
JOIN transactions t 
ON u.id=t.user_id
GROUP BY u.name, u.surname
HAVING COUNT( t.id) > 80
ORDER BY num_trans DESC;

SELECT CONCAT( name,' ',  surname) AS full_name FROM users
ORDER BY name ASC;

SELECT id,card_id,amount, CUME_DIST() OVER (ORDER BY amount) AS CAMBIOS
 FROM transactions;
-- total sale by product and online
SELECT p.product_name, SUM(t.amount) OVER (PARTITION BY tp.product_id ORDER BY t.card_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_sales FROM products p 
JOIN transactions_products tp ON p.id=tp.product_id
JOIN transactions t ON t.id=tp.transaction_id
WHERE t.channel = "online"
;

SELECT id,user_id, RANK() OVER(PARTITION BY user_id ORDER BY timestamp DESC) AS user_in_time FROM transactions;

SELECT p.product_name, SUM(t.amount) AS total_sales FROM products p 
JOIN transactions_products tp ON p.id=tp.product_id
JOIN transactions t ON t.id=tp.transaction_id
WHERE t.channel = "online" -- (antes de agrupar,filtramos)
GROUP BY p.product_name
ORDER BY total_sales DESC;

-- RANK PRODUCT BASED ON TOTAL AMOUNT
SELECT p.product_name, SUm(t.amount) AS total_sales, RANK() OVER (ORDER BY SUm(t.amount) desc) AS rank_sale  FROM products p 
JOIN transactions_products tp ON p.id=tp.product_id
JOIN transactions t ON t.id=tp.transaction_id
GROUP BY p.product_name;

INSERT INTO employees (employee_id,employee_name, department, salary) VALUES
("6", "Paco Perez", "Sales", "90.000");

UPDATE employees
SET salary ="9000.00"
WHERE employee_id = "6";

ALTER TABLE employees
ADD COLUMN fecha_inicio VARCHAR(50);

UPDATE employees
SET fecha_inicio ="2025-05-15"
WHERE employee_id = 1;

UPDATE employees
SET fecha_inIcio= CASE
		WHEN employee_id = 2 THEN "2024-06-01"
        WHEN employee_id = 3 THEN "2021-06-14"
        WHEN employee_id = 4 THEN "2023-04-01"
        WHEN employee_id = 5 THEN "2020-02-20"
        WHEN employee_id = 6 THEN "2024-10-01"
        END
WHERE employee_id IN (2,3,4,5,6);

-- quien es el empleado que mas tiempo leva
SELECT employee_name, fecha_inicio FROM employees
ORDER BY fecha_inicio ASC
LIMIT 1;

CREATE TABLE departament_changes(
departament_history_id INT AUTO_INCREMENT,
employee_id INT,
departament VARCHAR(150),
PRIMARY KEY(departament_history_id)
);

DELIMITER |

CREATE TRIGGER tg_old_department
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    IF NEW.department <> OLD.department THEN
        INSERT INTO departament_changes (employee_id, department)
        VALUES (OLD.employee_id, OLD.department);
    END IF;
END|
DELIMITER ;


UPDATE employees
SET department = "IT"
WHERE employee_id =1;

 -- Muestra el número total de transacciones rechazadas y el número total de transacciones no rechazadas.
 SELECT count(id) as totales_transacciones,
	CASE
		WHEN declined = 0 THEN "no rechazadas"
	ELSE
		"rechazadas"
	END AS estado_trans
FROM transactions   
GROUP BY estado_trans
;

-- Muestra el identificador de cada empresa y el importe medio de sus transacciones. Incluye únicamente las empresas cuya media sea superior a 100.
SELECT c.company_id, ROUND(AVG(t.amount) OVER (PARTITION BY c.company_id),2) as media 
FROM companies c 
JOIN transactions t
WHERE ROUND(AVG(t.amount),2) > 100;

SELECT c.company_id, ROUND(AVG(t.amount),2) as media
FROM companies c 
JOIN transactions t ON c.company_id=t.business_id
GROUP BY c.company_id
HAVING media > 100
;
-- Obtén el identificador y el nombre de los usuarios que no tienen ninguna transacción registrada.
SELECT u.id, u.name,u.surname FROM users u 
LEFT JOIN transactions t 
ON u.id=t.user_id 
WHERE t.user_id IS NULL;

-- Muestra el identificador de cada tarjeta y el importe total de sus transacciones. Incluye únicamente las tarjetas cuyo importe total supere los 1.000.

SELECT cc.id, ROUND(SUM(t.amount),2) as total_transacciones FROM credit_cards cc
JOIN transactions t ON cc.id=t.card_id
GROUP BY cc.id
HAVING total_transacciones > 1000;

/*Muestra el identificador y el nombre de cada producto, junto con el número de veces que aparece en las transacciones.
 Ordena los resultados del más vendido al menos vendido.*/
 
 SELECT p.id,p.product_name, COUNT(tp.transaction_id) cantidad FROM products p 
 JOIN transactions_products tp 
 ON p.id=tp.product_id
 JOIN transactions t
 ON tp.transaction_id=t.id
 WHERE declined <>1
 GROUP BY  p.id,p.product_name
 ORDER BY cantidad DESC;
 
 -- muestra producto y num de veces que aparace en transaccione no rechazadas y slo mas de 100
  SELECT p.id,p.product_name, COUNT(tp.transaction_id) cantidad FROM products p 
 JOIN transactions_products tp 
 ON p.id=tp.product_id
 JOIN transactions t
 ON tp.transaction_id=t.id
 WHERE declined <>1
 GROUP BY  p.id,p.product_name
 HAVING cantidad >100;
 
 -- Para cada tarjeta, muestra su identificador y la fecha de su transacción más reciente. 
 -- Incluye únicamente las tarjetas que tengan al menos una transacción.
 SELECT card_id, DATE(timestamp) AS date
 FROM ( SELECT card_id,timestamp, row_number() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS rank_fecha FROM transactions ) AS ranked
WHERE rank_fecha =1
 ;
 -- Muestra el identificador, nombre y apellido de cada usuario, junto con el importe total de sus transacciones no rechazadas. 
 -- Incluye únicamente los usuarios cuyo gasto total supere los 500.
 SELECT u.id,u.name, u.surname, ROUND(SUM(t.amount),2) AS total_trans 
 FROM users u 
 JOIN transactions t 
 ON u.id=t.user_id
 WHERE t.declined <>1
 GROUP BY u.id,u.name, u.surname
 HAVING total_trans >500;
 
-- Muestra el identificador y el nombre de las empresas que no tienen ninguna transacción registrada.
SELECT c.company_id, c.company_name 
FROM companies c 
LEFT JOIN transactions t 
ON c.company_id=t.business_id
WHERE t.business_id IS NULL;

-- Para cada mes, muestra el año, el mes y el importe medio de las transacciones no rechazadas. 
-- Ordena los resultados cronológicamente, desde el mes más antiguo al más reciente.
SELECT
    EXTRACT(YEAR FROM timestamp) AS year,
    EXTRACT(MONTH FROM timestamp) AS month,
    ROUND(AVG(amount), 2) AS media
FROM transactions
WHERE declined <> 1
GROUP BY
    EXTRACT(YEAR FROM timestamp),
    EXTRACT(MONTH FROM timestamp)
ORDER BY year, month;

-- Muestra cada canal de venta y el importe total de sus transacciones no rechazadas. 
-- Incluye solo los canales cuyo importe total sea superior a 10.000 y ordénalos de mayor a menor importe.
SELECT channel, SUM(amount) as total_por_canal FROM transactions 
WHERE declined <>1
GROUP BY channel 
HAVING total_por_canal >10000
ORDER BY total_por_canal DESC;

DESCRIBE transactions;
-- Muestra el identificador, nombre y apellido de los usuarios que tienen más de una tarjeta registrada.
--  Ordena el resultado por número de tarjetas, de mayor a menor.
 SELECT u.id,u.name,u.surname, COUNT(cc.id) AS num_tarjetas FROM users u
 JOIN credit_cards cc ON u.id=cc.user_id
 GROUP BY u.id,u.name,u.surname
 HAVING num_tarjetas >1
 ORDER BY num_tarjetas DESC;
 
 -- Muestra, para cada usuario que tenga transacciones, su identificador, el número de transacciones aceptadas 
 -- y el número de transacciones rechazadas.
 SELECT u.id,
 COUNT(CASE WHEN declined = 1 THEN 1 END) AS trans_rechazadas,  COUNT(CASE WHEN declined = 0 THEN 1 END) AS trans_aceptadas
FROM users u 
JOIN transactions t
ON u.id=t.user_id
GROUP BY u.id;
;

-- Muestra el identificador de cada usuario, el canal de venta y el importe total de sus transacciones no rechazadas para ese canal.
-- Ordena los resultados de mayor a menor importe.
SELECT u.id,t.channel, ROUND(SUM(t.amount),2) as total_trans 
FROM users u 
JOIN transactions t
ON u.id=t.user_id 
WHERE declined <>1
GROUP BY u.id,t.channel;
        
-- Obtén el identificador y el nombre de los productos que nunca han aparecido en una transacción aceptada.
SELECT p.id, p.product_name
FROM products p
WHERE not EXISTS (
    SELECT 1
    FROM transactions_products tp
    JOIN transactions t
        ON t.id = tp.transaction_id
    WHERE tp.product_id = p.id
      AND t.declined = 0
); 

-- Muestra el identificador de cada empresa y el importe de su transacción de mayor valor. 
-- Incluye únicamente las empresas cuya transacción máxima supere los 500.  
SELECT business_id,amount
FROM (SELECT business_id, amount,row_number() OVER (PARTITION BY business_id ORDER BY amount DESC) AS cantidad FROM transactions) AS ranking_valor
WHERE cantidad=1 and amount >500
;
SELECT
    c.company_id,
    c.company_name,
    ranking_valor.amount
FROM (
    SELECT
        business_id,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY business_id
            ORDER BY amount DESC
        ) AS ranking
    FROM transactions
) AS ranking_valor
JOIN companies c
    ON c.company_id = ranking_valor.business_id
WHERE ranking_valor.ranking = 1
  AND ranking_valor.amount > 500;
  
  -- Muestra cada año de registro y el número de usuarios que se registraron durante ese año.
  -- Ordena los resultados desde el año más antiguo al más reciente.
  SELECT EXTRACT(year FROM signup_date) AS year_signup, COUNT(id) AS num_users
  FROM users
  GROUP BY year_signup
  ORDER BY year_signup ASC;
  
  -- Muestra el identificador de la tarjeta, el identificador de la transacción, la fecha y el importe de sus tres transacciones más recientes.
  -- Si una tarjeta tiene menos de tres transacciones, muestra las que tenga.y ademas solo de transacciones aceptadas
  
  SELECT cc.id,tabla_rango.id, tabla_rango.timestamp, tabla_rango.amount
  FROM (SELECT id, card_id, timestamp, amount, rank() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS rango_tiempo FROM transactions WHERE declined=0) as tabla_rango
  JOIN credit_cards cc 
  ON cc.id=tabla_rango.card_id
  WHERE rango_tiempo <=3;
  
 
SELECT u.id, u.name, u.surname, COUNT(CASE WHEN t.declined=0 THEN 1 END) as total_transacciones_aceptadas
FROM users u 
JOIN transactions t ON u.id=t.user_id
GROUP BY u.id, u.name, u.surname;

-- Encuentra las tres empresas con mayor importe total en transacciones aceptadas. Muestra el identificador de la empresa, su nombre y el importe total. Ordena de mayor a menor y
--  utiliza los nombres de tablas y columnas que venimos usando.

SELECT c.company_id, c.company_name, SUM(t.amount) totales FROM companies c
JOIN transactions t ON c.company_id=t.business_id
WHERE t.declined <>1
GROUP BY c.company_id, c.company_name
ORDER BY totales DESC LIMIT 3
;
-- Encuentra los productos que han aparecido en más transacciones aceptadas que rechazadas.
-- Identificador y nombre del producto.
-- Número de apariciones en transacciones aceptadas.
-- Número de apariciones en transacciones rechazadas.
-- apariciones aceptadas, de mayor a menor.

SELECT p.id,p.product_name,
	COUNT(CASE WHEN t.declined =0 THEN 1 END) accepted,COUNT(CASE WHEN t.declined=1 THEN 1 END) rejected
FROM products p
JOIN transactions_products tp
ON p.id=tp.product_id
JOIN transactions t 
ON t.id=tp.transaction_id
GROUP BY p.id,p.product_name
HAVING accepted > rejected
ORDER BY accepted DESC;

-- el número de transacciones por canal,
SELECT u.id, u.name,u.surname,
COUNT(CASE WHEN channel_table.channel='store'THEN 1 END) store,
COUNT(CASE WHEN channel_table.channel='marketplace'THEN 1 END) marketplace,
COUNT(CASE WHEN channel_table.channel='online'THEN 1 END) online
FROM (SELECT user_id, channel FROM transactions WHERE channel IN ('online', 'store','marketplace')
) as channel_table
JOIN users u ON u.id=channel_table.user_id
GROUP BY u.id, u.name,u.surname
;
SELECT
    u.id,
    u.name,
    u.surname,
    COUNT(CASE WHEN t.channel = 'store' THEN 1 END) AS store,
    COUNT(CASE WHEN t.channel = 'marketplace' THEN 1 END) AS marketplace,
    COUNT(CASE WHEN t.channel = 'online' THEN 1 END) AS online
FROM users u
JOIN transactions t
    ON u.id = t.user_id
GROUP BY u.id, u.name, u.surname;
-- Necesitas contar los canales diferentes y quedarte con los usuarios que hayan utilizado al menos tres:
SELECT
    u.id,
    u.name,
    u.surname,
    COUNT(DISTINCT t.channel) AS num_canales
FROM users u
JOIN transactions t
    ON u.id = t.user_id
GROUP BY u.id, u.name, u.surname
HAVING COUNT(DISTINCT t.channel) >= 3
ORDER BY num_canales DESC;

-- encuentra las tarjetas cuyo importe medio por transacción aceptada sea superior a 200. 
-- Muestra el identificador de la tarjeta y el importe medio redondeado a dos decimales, ordenando de mayor a menor.
SELECT cc.id, ROUND(AVG(t.amount),2) as media_transacciones_acc
FROM credit_cards cc
JOIN transactions t 
ON cc.id=t.card_id
WHERE t.declined <>1
GROUP BY cc.id
HAVING media_transacciones_acc >200
ORDER BY media_transacciones_acc DESC;

-- Encuentra la segunda transacción de mayor importe de cada tarjeta, teniendo en cuenta únicamente las transacciones aceptadas.
-- Muestra el identificador de la tarjeta, el identificador de la transacción y el importe.
SELECT cc.id,rango_trans.id, rango_trans.amount
 FROM
(SELECT id, amount,card_id, ROW_NUMBER() OVER (Partition by card_id ORDER BY amount DESC) as cantidad_mayor FROM transactions
WHERE declined <>1) rango_trans
JOIN credit_cards cc
ON cc.id=rango_trans.card_id
WHERE cantidad_mayor ='2'; 

-- Para cada usuario, encuentra la fecha de su primera transacción aceptada.
--  Muestra el identificador del usuario, su nombre, su apellido y la fecha. Ordena por fecha de más antigua a más reciente.
SELECT u.id,u.name,u.surname, rango_fecha.timestamp
FROM (
SELECT id, user_id, timestamp, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY timestamp ASC) AS rank_fechas FROM transactions
WHERE  declined <>1) rango_fecha
JOIN users u
ON u.id=rango_fecha.user_id
WHERE rank_fechas =1
ORDER BY rango_fecha.timestamp ASC;
-- Encuentra las empresas cuyo importe total de transacciones aceptadas sea superior al importe total de transacciones rechazadas.
-- Muestra el identificador de la empresa, su nombre, el importe total aceptado y el importe total rechazado.
-- Ordena por importe total aceptado, de mayor a menor.
SELECT c.company_id,c.company_name,
ROUND(SUM(CASE WHEN t.declined=0 THEN t.amount ELSE 0 END ),2) trans_aceptadas,
ROUND(SUM(CASE WHEN t.declined=1 THEN t.amount ELSE 0 END ),2) trans_rechazadas
FROM companies c 
JOIN transactions t 
ON c.company_id=t.business_id
GROUP BY  c.company_id,c.company_name
HAVING trans_aceptadas>trans_rechazadas
ORDER BY  trans_aceptadas DESC;

-- Encuentra los usuarios cuyo importe medio por transacción aceptada sea superior a la media global de todas las transacciones aceptadas.
-- Muestra el identificador, nombre, apellido y media de cada usuario. Ordena de mayor a menor media.
SELECT u.id, u.name, u.surname, ROUND(AVG(t.amount),2) as MEDIA
FROM users u
 JOIN transactions t 
 ON u.id=t.user_id
 WHERE t.declined<>1
 GROUP BY u.id, u.name, u.surname
 HAVING  media> (SELECT AVG(amount) FROM transactions WHERE declined <>1)
 ORDER BY media DESC;
 
-- Encuentra las tarjetas (credit_cards) que han tenido al menos 3 transacciones aceptadas y cuyo importe total acumulado supera los 10.000.
WITH cc_acc AS (
	SELECT card_id, COUNT(id) AS num_trans, SUM(amount) AS suma_trans FROM transactions
	WHERE declined <>1
	GROUP BY card_id
	HAVING num_trans >=3)
SELECT card_id,num_trans,suma_trans
 FROM cc_acc
 WHERE suma_trans >10000
 ORDER BY suma_trans DESC;

SELECT card_id, COUNT(id) AS num_trans, SUM(amount) AS suma_trans 
FROM transactions
WHERE declined <>1
GROUP BY card_id
HAVING num_trans >=3 AND suma_trans  >10000
ORDER BY suma_trans DESC;

-- Seguimos practicando CTE.Encuentra los usuarios que hayan realizado transacciones en al menos 3 canales diferentes (online, store, marketplace).
-- Muestra:- user_id,  Número de canales diferentes, Ordena de mayor a menor número de canales.
WITH canal AS(
SELECT user_id, COUNT(distinct channel) AS tipo_canal
FROM transactions
GROUP BY user_id
HAVING tipo_canal >=3)
SELECT user_id, tipo_canal FROM canal
ORDER BY tipo_canal DESC;
;

SELECT id,amount,timestamp, ROW_NUMBER() OVER (PARTITION BY CAST(timestamp AS DATE)ORDER BY amount) AS rank_trans_fecha
FROM  transactions
WHERE declined =0 AND EXTRACT(YEAR FROM timestamp) = 2021
ORDER BY amount DESC LIMIT 5;
SELECT CAST(timestamp AS DATE) as fecha,SUM(amount) AS totales
FROM  transactions
WHERE declined =0 AND EXTRACT(YEAR FROM timestamp) = 2021
GROUP BY fecha
ORDER BY totales DESC LIMIT 5;

SELECT timestamp as Fecha, SUm(amount) AS totales from transactions
WHERE declined =0 AND EXTRACT(YEAR FROM timestamp) = 2021
GROUP BY fecha
ORDER BY totales DESC LIMIT 5;

DROP view marketing_kpis;
CREATE OR REPLACE VIEW marketing_kpis AS 
SELECT c.company_name, c.phone, c.country, ROUND(AVG(t.amount),2) AS media_compra, 
CASE 
	WHEN ROUND(AVG(t.amount),2) > 260 THEN "Premium"
    ELSE "Standard"
END AS client_tier
 FROM companies c 
 JOIN transactions t
 ON c.company_id=t.business_id
 GROUP BY c.company_name, c.phone, c.country
 
 
;
ALTER TABLE users
CHANGE COLUMN phone phone2 VARCHAR(30);

ALTER TABLE users
RENAME COLUMN phone2 TO phone;

SELECT * FROM marketing_kpis
ORDER BY client_tier ASC, media_compra DESC
;

-- asi sacamos datos del array y las ubicamos en columnas
SELECT * FROM orders,
JSON_TABLE(products,'$[*]' COLUMNS (product_id INT PATH "$.product_id",quantity INT PATH "$.quantity")) AS new_columns;
