/*Nivel 1
Ejercicio 1
A partir de los documentos adjuntos (estructura_datos y datos_introducir), importa las dos tablas. 
Muestra las principales características del esquema creado y explica las diferentes tablas y variables que existen.
 Asegúrate de incluir un diagrama que ilustre la relación entre las distintas tablas y variables.*/
-- A continuación, pongo las instrucciones para crear la BBSS transactions desde el docuemnto ESTRUCTURA DE DATOS y las ejecuto uno por uno
-- Creamos la base de datos
-- Pongo DROP en cada instruccion de CREAR base de datos y tablas por si el profesor quiereo hacer EXECUTE del todo
DROP DATABASE IF EXISTS transactions;
CREATE DATABASE IF NOT EXISTS transactions;
USE transactions;

-- Creamos la tabla company
DROP TABLE IF EXISTS company;
CREATE TABLE IF NOT EXISTS company (
	id VARCHAR(15) PRIMARY KEY,
	company_name VARCHAR(255),
	phone VARCHAR(15),
	email VARCHAR(100),
	country VARCHAR(100),
	website VARCHAR(255)
    );


-- Creamos la tabla transaction
DROP TABLE IF EXISTS transactions;
CREATE TABLE IF NOT EXISTS transaction (
        id VARCHAR(255) PRIMARY KEY,
        credit_card_id VARCHAR(15) REFERENCES credit_card(id),
        company_id VARCHAR(20), 
        user_id INT REFERENCES user(id),
        lat FLOAT,
        longitude FLOAT,
        timestamp TIMESTAMP,
        amount DECIMAL(10, 2),
        declined BOOLEAN,
        FOREIGN KEY (company_id) REFERENCES company(id) 
    );
    
-- Ahora rellenamos nuestras tablas al ejecutar el codigo del segundo documento sql "datos_introducir"
-- Para acceder al diagrama de la base de datos, voy al menú superior, pulso Database → Reverse Engineer.
    
 -- Ejercicio 2
/*Utilizando JOIN realizarás las siguientes consultas:
Listado de los países que están generando ventas.
Desde cuántos países se generan las ventas.*/

SELECT DISTINCT c.country FROM company c
JOIN transaction t 
ON c.id = t.company_id
WHERE t.declined <>0 -- porque las transacciones fallidas no las debemos incluir
ORDER BY c.country ASC;



 -- Identifica a la compañía con la mayor media de ventas
SELECT c.company_name, ROUND(AVG(t.amount),2) as media
FROM company c 
JOIN transaction t
ON c.id=t.company_id
WHERE t.declined <>0
GROUP BY c.company_name
ORDER BY media DESC
LIMIT 1;
-- Para practicar window function opcion dos
SELECT c.company_name, ROUND(AVG(t.amount) OVER (PARTITION BY c.company_name),2) AS media_ventas 
FROM company c
JOIN transaction t 
ON c.id=t.company_id
WHERE t.declined <>0
ORDER BY media_ventas DESC
LIMIT 1;

/*Ejercicio 3
Utilizando sólo subconsultas (sin utilizar JOIN):

Muestra todas las transacciones realizadas por empresas de Alemania.*/

SELECT * FROM transaction
WHERE company_id IN (
SELECT id
FROM company
WHERE country ="Germany" 
);
 -- Lista las empresas que han realizado transacciones por un monto superior a la media de todas las transacciones.
SELECT company_name
FROM company
WHERE id IN (
	SELECT company_id 
	FROM transaction
	WHERE amount > (
		SELECT AVG(amount) FROM transaction)
)
 ORDER BY company_name DESC;

 -- Elimina del sistema las empresas que carecen de transacciones registradas, entrega el listado de estas empresas
 -- primero hago consulta para sacar la lista de empresas que no tienen transacciones registradas y como podemos
 -- observar no existen en esta base de datos empresas que no hayan realizado alguna transaccion.

SELECT  * FROM company
WHERE NOT EXISTS (
	SELECT company_id
	FROM transaction
    WHERE company_id IS NOT NULL)
    ;
    -- igualmente para eliminar estas empresas hubieramos usado el siguiente codigo
 DELETE FROM company
 WHERE NOT EXISTS (
	SELECT company_id
	FROM transaction
    WHERE company_id IS NOT NULL)
    ;  
    
-- EJERCICIO 4 Pimero creo la tabla credit_card.  Para saber qué columnas tengo que crear, miro el documento "datos_introducit_credit_card".
DROP TABLE IF EXISTS credit_card;

CREATE TABLE IF NOT EXISTS credit_card (
id VARCHAR(15),
iban VARCHAR(34),
pan VARCHAR(19),
pin VARCHAR(4),
cvv VARCHAR(3),
expiring_date VARCHAR(10)
);
-- Procedemos a llenar nueva tabla con los registros del documento numero 4 "datos_introducir_credit_card" y despues reviso como se ve la tabla
SELECT * FROM credit_card
LIMIT 10;
--- limpieza de la tabla. revisamos si hay duplicados
SELECT id, COUNT(*)
FROM credit_card
GROUP BY id
HAVING COUNT(id) <> 1; 
-- miramos si hay NULL
SELECT *
FROM credit_card
WHERE id IS NULL;

-- Modificamos tipos de atributos en la nueva tabla credit_card. EN este caso solo hace falta cambiar expiring_date de VARCHAR a DATE
-- primero modifico formato
SET SQL_SAFE_UPDATEs =0;
UPDATE credit_card
SET expiring_date = STR_TO_DATE(expiring_date, '%m/%d/%y')
WHERE id IS NOT NULL;

ALTER TABLE credit_card
MODIFY COLUMN expiring_date DATE,
ADD PRIMARY KEY (id);

SET SQL_SAFE_UPDATEs =1;

-- vuelvo a revisar como quedo la tabla credit_card
DESCRIBE credit_card;

/*ahora tenemos que crear relacion entre la nueva tabla de dimensiones credit_card y transaction (tabla de hechos), en la tabla transaction tenemos columna "credit_card_id" 
que sera la FK relacionada a "id" de la tabla credit_card que es su PK*/
ALTER TABLE transaction
DROP CONSTRAINT fk_transaction_credit_card;
ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_credit_card
FOREIGN KEY (credit_card_id) 
REFERENCES credit_card(id);


-- Ejercicio 5
/*El departamento de Recursos Humanos ha identificado un error en el número de cuenta asociado a su tarjeta de crédito con ID CcU-2938.
 La información que debe mostrarse para este registro es: TR323456312213576817699999. Recuerda mostrar que el cambio se realizó.*/
--  Modifico el número de cuenta (IBAN) de la tarjeta
UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';

-- Reviso que esta correctamente
SELECT id, iban
FROM credit_card
WHERE id = 'CcU-2938';
-- Ejercicio 6
-- En la tabla "transaction" ingresa una nueva transacción.

INSERT INTO transaction (id, credit_card_id,company_id,user_id,lat, longitude, amount, declined) 
VALUES ("108B1D1D-5B23-A76C-55EF-C568E49A99DD","CcU-9999","b-9999","9999","829.999","-117.999","111.11", "0");

/* cuando lo intento hacer, me encuentro con el problema que la empresa no existe en la tabla "company" y el numeor de tarjeta no existe en la tabla "credit_card"
asi que primero las tengo que crear en dichas tablas ya que las tablas estan relacionadas.*/

INSERT INTO company (id) VALUES ("b-9999");


INSERT INTO credit_card (id) VALUES ("CcU-9999");

-- ahora podemos anadir nuevo registro en transaction
INSERT INTO transaction (id, credit_card_id,company_id,user_id,lat, longitude, amount, declined) 
VALUES ("108B1D1D-5B23-A76C-55EF-C568E49A99DD","CcU-9999","b-9999","9999","829.999","-117.999","111.11", "0");

-- Comprobamos si se guardo de forma correcta
SELECT * FROM transaction
WHERE credit_card_id = "CcU-9999";

-- Ejercicio 7
-- Desde recursos humanos te solicitan eliminar la columna "pan" de la tabla credit_card. Recuerda mostrar el cambio realizado.
-- Eliminamos la columna
ALTER TABLE credit_card
DROP COLUMN pan;
-- Comprobamos que la tabla ya no tiene la columna
DESCRIBE credit_card;

-- Ejercicio 8 Crear una base de datos que llame transact nuevo con datos de varios CSVs.alter
DROP DATABASE IF EXISTS transact;
CREATE DATABASE IF NOT EXISTS transact;
USE transact;

-- Empiezo por crear las dos tablas de usuarios y tengo que anadir una columna nueva region para poder despues unificar estas dos
-- tablas, usuarios de EEUU y UE
CREATE TABLE users_euro (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(150),
    birth_date VARCHAR(50),     
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),     
    address VARCHAR(255),       
    signup_date VARCHAR(50),     
    user_segment VARCHAR(50),    
    income_band VARCHAR(50),     
    region VARCHAR(10)          
);

-- cargamos los datos en la tabla de users_euro
LOAD DATA
INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\N1-Ex.8__european_users.csv" -- anadí doble diagonal al ver el video de V.Hugo
INTO TABLE users_euro
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, name, surname, phone, email, birth_date, country, city,
 postal_code, address, signup_date, user_segment, income_band)
SET region = 'EU'
;

-- ahora creo la tabla de clientes de EEUU
CREATE TABLE users_unitedstates (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(150),
    birth_date VARCHAR(50),     
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),     
    address VARCHAR(255),       
    signup_date VARCHAR(50),     
    user_segment VARCHAR(50),    
    income_band VARCHAR(50),     
    region VARCHAR(10)          
);

-- ahora cargamos los registros a la segunda tabla, users_unidtedstates
LOAD DATA
INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\N1-Ex.8__american_users.csv" 
INTO TABLE users_unitedstates
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, name, surname, phone, email, birth_date, country, city,
 postal_code, address, signup_date, user_segment, income_band)
SET region = 'US'
;
-- ahora creamos una sola tabla de dimensiones "users", llenando los datos de las anteriores tablas US y EU:
CREATE TABLE users (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(150),
    birth_date VARCHAR(50),     
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),     
    address VARCHAR(255),       
    signup_date VARCHAR(50),     
    user_segment VARCHAR(50),    
    income_band VARCHAR(50),     
    region VARCHAR(10)          
);
-- llenamos la tabla users con los datos de las tablas users US y EU usando UNION ALL
INSERT INTO users (
    id, name, surname, phone, email, birth_date,
    country, city, postal_code, address, signup_date,
    user_segment, income_band, region
)
SELECT
    id, name, surname, phone, email, birth_date,
    country, city, postal_code, address, signup_date,
    user_segment, income_band, 'EU'
FROM users_euro

UNION ALL-- deja los duplicados

SELECT
    id, name, surname, phone, email, birth_date,
    country, city, postal_code, address, signup_date,
    user_segment, income_band, 'US'
FROM users_unitedstates;
-- Finalmente elimino las tablas users_euro,users_unitedstates
DROP TABLE users_euro;
DROP TABLE users_unitedstates;

-- Ahora que tengo la tabla users lista procedo a modificar los formatos de columnas que se necesite 
-- modifico el formato de la columna birth_date
-- pero como ya tengo las PK establecidas tengo que desactivar SAFE MODE (aunque sé que no es recomendable)
SET SQL_SAFE_UPDATES = 0;
UPDATE users
SET birth_date = DATE_FORMAT(
    STR_TO_DATE(birth_date, '%b %d, %Y'),
    '%Y-%m-%d'
)
WHERE birth_date LIKE '% % %';
-- volvemos a instalar SAFE MODE
SET SQL_SAFE_UPDATES = 1;

-- una vez comprobado que el formato ya se ve bien, procedo a actualizar el tipo de columna
ALTER TABLE users
MODIFY COLUMN birth_date DATE;
	
-- modifico tipo de columna signup_date. EL formato estaba bien pero tipo era VARCHAR y lo cambio al DATE
ALTER TABLE users
MODIFY COLUMN signup_date DATE;


-- ahora creamos la tabla de dimensiones credit_cards
CREATE TABLE IF NOT EXISTS credit_cards(
	id VARCHAR(50) PRIMARY KEY,
	user_id VARCHAR(15),
	iban VARCHAR(34),
	pan VARCHAR(19),
	pin VARCHAR(4),
	cvv VARCHAR(4),
	track1 VARCHAR(150),
	track2 VARCHAR(150),
	expiring_date VARCHAR(10),
	card_type VARCHAR (15),
	card_renewal_flag BOOLEAN
);


-- cargamos los datos desde csv
LOAD DATA
INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\N1-Ex.8__credit_cards.csv"
INTO TABLE credit_cards
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- creamos la tabla de dimensiones "companies"
CREATE TABLE companies(
company_id VARCHAR(15) PRIMARY KEY,
company_name VARCHAR(150),
phone VARCHAR (50),
email VARCHAR (50),
country VARCHAR (50),
website VARCHAR(150),
merchant_category VARCHAR(50),
merchant_price_position VARCHAR(50)
);


-- cargamos los registros para la tabla de companies

LOAD DATA
INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\N1-Ex.8__companies.csv"
INTO TABLE companies
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
-- ahora creo la tabla de hechos transactions donde añadiremos los FK
CREATE TABLE IF NOT EXISTS transactions(
id VARCHAR(50) PRIMARY KEY,
card_id VARCHAR(50) REFERENCES credit_cards(id),
business_id VARCHAR(50) REFERENCES companies(company_id),
timestamp TIMESTAMP,
amount DECIMAL(10,2),
declined BOOLEAN,
products_ids TEXT,
user_id VARCHAR(50) REFERENCES users(id),
lat FLOAT,               
longitude FLOAT,
discount_amount DECIMAL(10,2),
tax_amount DECIMAL(10,2),
shipping_amount DECIMAL(10,2),
channel VARCHAR(50),
campaign_id VARCHAR(50),
device_type VARCHAR(50),
is_international BOOLEAN,
decline_reason VARCHAR(255),
distance_km DECIMAL(8, 2)
  )
;
-- cargamos los registros para la tabla de transactions
LOAD DATA
INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\N1-Ex.8__transactions.csv"
INTO TABLE transactions
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Ejercicio 9
-- Realiza una subconsulta que muestre a todos los usuarios con más de 80 transacciones utilizando al menos 2 tablas.
SELECT * FROM users
WHERE id IN (
	SELECT user_id FROM transactions
    GROUP BY user_id
	HAVING COUNT(id) > 80
    ORDER BY COUNT(id) DESC);

-- EJERCICIO 10
-- Muestra la media de cantidad de transacciones (amount) por IBAN de las tarjetas de crédito en la compañía Donec Ltd., utiliza por lo menos 2 tablas.
SELECT c.iban, ROUND(AVG(t.amount),2) AS media FROM transactions t
JOIN credit_cards c
ON t.card_id=c.id
JOIN companies comp 
ON comp.company_id = t.business_id
WHERE comp.company_name ="Donec Ltd"
GROUP BY c.iban;

--------------
-- NIVEL 2
-- Ejercicio 1
/*Identifica los cinco días que se generó la mayor cantidad de ingresos en la empresa por ventas.
 Muestra la fecha de cada transacción junto con el total de las ventas.*/
 SELECT DATE(timestamp) AS fecha, ROUND(SUM(amount)- SUM(discount_amount),2) AS total_ventas 
 FROM transactions
 WHERE declined <>0
 GROUP BY DATE(timestamp)
ORDER BY total_ventas DESC
 LIMIT 5;
 
-- Ejercicio 2
/*Ejercicio 2
Presenta el nombre, teléfono, país, fecha y amount, de aquellas empresas que realizaron transacciones con un valor comprendido entre 350 y 400 euros
 y en alguna de estas fechas: 29 de abril de 2015, 20 de julio de 2018 y 13 de marzo de 2024.
 Ordena los resultados de mayor a menor cantidad.*/
 -- en este caso, vi oportuno crear un index B-tree (secundario) porque está claro que se va a recurrir mucho a la columna de amount y de la fecha en la tabla de transacciones
CREATE INDEX idx_amount_date
ON transactions(amount, timestamp);

 SELECT c.company_name, c.phone, c.country,t.timestamp AS date, ROUND(t.amount,2) AS Amount
 FROM companies c 
 JOIN transactions t 
	ON c.company_id= t.business_id
 WHERE ROUND(t.amount,2) BETWEEN 350 AND 400
 AND DATE(timestamp) IN ("2015-04-29", "2018-07-20", "2024-03-13")
 ORDER BY ROUND(t.amount,2) DESC;

-- EJERCICIO 3
/*
Necesitamos optimizar la asignación de los recursos y dependerá de la capacidad operativa que se requiera, por lo que te piden la información 
sobre la cantidad de transacciones que realizan las empresas, pero el departamento de recursos humanos es exigente
 y quiere un listado de las empresas en las que especifiques si tienen igual o más de 400 transacciones o menos.*/
 SELECT c.company_name, COUNT(t.id) AS cantidad_transacciones,
	CASE
		WHEN COUNT(t.id) >= 400 THEN "ALTO"
		ELSE "BAJO"
	END AS 'Volumen Transacciones'
 FROM companies c
 JOIN transactions t 
	ON c.company_id = t.business_id
GROUP BY c.company_name
ORDER BY cantidad_transacciones DESC;

-- Ejercicio 4
-- Elimina de la tabla transacción el registro con ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de datos.
-- primero comprobaré que este registro existe y de que se trata para estar segura:
SELECT *
FROM transactions
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';
-- ahora procedo a eliminarlo

DELETE FROM transactions
WHERE id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD";

-- comprueblo de nuevo que se haya eliminado con exito
SELECT *
FROM transactions;
-- EJERCICIO 5
/*La sección de marketing desea tener acceso a información específica para realizar análisis y estrategias efectivas. 
Se ha solicitado crear una vista que proporcione detalles clave sobre las compañías y sus transacciones. 
Será necesaria que crees una vista llamada VistaMarketing que contenga la siguiente información: 
Nombre de la compañía. Teléfono de contacto. País de residencia. Media de compra realizado por cada compañía.
 Presenta la vista creada, ordenando los datos de mayor a menor promedio de compra.*/
 
 DROP VIEW `VistaMarketing`;
 CREATE VIEW `VistaMarketing` AS
SELECT c.company_name, c.phone, c.country, ROUND(AVG(t.amount),2) AS media_compra
FROM companies AS c
JOIN transactions AS t
    ON c.company_id = t.business_id
GROUP BY c.company_name, c.phone, c.country;

-- reviso que funciona
SELECT * FROM  `VistaMarketing`;

-- ordeno la vista del mayor a menor
SELECT * FROM  `VistaMarketing`
ORDER BY media_compra DESC;


-- NIVEL 3
-- EJERCICIO 1
/*Crea una nueva tabla que refleje el estado de las tarjetas de crédito 
basado en si las tres últimas transacciones han sido declinadas entonces es inactivo,
 si por lo menos una no es rechazada entonces es activo. Partiendo de esta tabla responde:
¿Cuántas tarjetas están activas?*/

-- primer paso creamos nueva tabla
DROP TABLE IF EXISTS card_status;
 CREATE TABLE IF NOT EXISTS card_status
SELECT card_id,
CASE
		WHEN SUM(declined) > 0 THEN 'INACTIVA'
        ELSE 'ACTIVA'
END AS estatus
FROM (SELECT id, card_id, declined, ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS rank_fecha FROM transactions) AS ranked
WHERE rank_fecha <= 3
GROUP BY card_id;
-- segundo paso revisamos cuantas tarjetas activas tenemos. Son 4874.
SELECT * FROM card_status
WHERE estatus ="ACTIVA";

-- EJERCICIO 2
/*Crea una tabla con la que podamos unir los datos del archivo de products.csv con la base de datos creada 
(ya que hasta ahora no podíamos hacerlo), teniendo en cuenta que desde transaction tienes product_ids. Genera la siguiente consulta:
Necesitamos conocer el número de veces que se ha vendido cada producto.*/

-- primero creamos la tabla products y llenaremos los datos. Despues crearemos la tabla intermedia transactions_products que une las dos.
CREATE TABLE products(
	id VARCHAR(50) PRIMARY KEY,
	product_name VARCHAR(150),
	price DECIMAL(10, 2),
	colour VARCHAR(150),
	weight DECIMAL(10, 2),
	warehouse_id VARCHAR(15),
	category VARCHAR(150),
	brand VARCHAR(150),
	cost DECIMAL(10, 2),
	launch_date DATE
    );
    DESCRIBE products;
-- ahora llenamos la tabla products con los registros segun el documento csv. 
-- Tuve que eliminar el simbolo de dolar de los registros para que podamos trabajar con esta tabla de forma exitosa.
LOAD DATA 
INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\N1-Ex.8__products.csv"
INTO TABLE products
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    id,product_name, @price, colour, weight, warehouse_id,category,brand,@cost,launch_date
)
SET
    price = REPLACE(@price, '$', ''),
    cost = REPLACE(@cost, '$', '');

-- ahora creamos la tabla intermedia entre transactions y products ya que la columna de producs_id en transacrions conlleva varios productos

CREATE TABLE IF NOT EXISTS transactions_products(
	transaction_id VARCHAR(50),
    product_id VARCHAR(50),
    PRIMARY KEY (transaction_id, product_id),-- en una tabla intermedia que PK tiene que ser un compuestos de los dos
    FOREIGN KEY (transaction_id) REFERENCES transactions(id), 
    FOREIGN KEY (product_id) REFERENCES products(id)
    );
    
 
INSERT INTO transactions_products (transaction_id, product_id)
SELECT t.id, jt.product_id
FROM transactions t
JOIN JSON_TABLE(
    CONCAT('[', t.products_ids, ']'),
    '$[*]' COLUMNS (product_id INT PATH '$')
) jt;

 -- Calculamos el número de veces que se ha vendido cada producto
 SELECT p.id AS id, p.product_name AS product_name, COUNT(tp.product_id) AS times_sold
 FROM products p
 LEFT JOIN transactions_products tp
 ON p.id=tp.product_id
 GROUP BY p.id,p.product_name
 ORDER BY times_sold DESC;