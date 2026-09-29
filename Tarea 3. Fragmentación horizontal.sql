 /*
    Fragmentación 
	1.- Modelo de datos (modelo relacional de la BD)
	2.- Aplicaciones que acceden a los datos (consultas)
	3.- Seleccionar tipo de fragmenmtación 
		a.- horizontal 
		    - primaria (definir el conjunto de predicados)
			  Aplica el algoritmo COM_MIN 
			  Aplica el algitmo de PHORIZONTAL
            - derivada (semi-join)

			   Tabla A   (Propietarias)
			   |      |
           Tabla B   Tabla C (Miembro) (Propietaria)
		               |
		             Tabla D (Miembro) 

           Semijoin Tabla A y Tabla C
		     Seleccionar filas de la Tabla C que se relacionen
			 con cada uno de los fragmentos de la Tabla A.

			 Supongamos que la tabla A se fragmente en A1 y A2

			 C1 =  select Tabla_C.* 
			       from Tabla_C join Tabla_A1
			       C.atributo = A1.atributo 
				   					 

*/

/* Propuestas para fragmentar */

/*
  Ejercicio 3: Distribuir la cartera de clientes en los 5 
  nodos geográficos para que cada región administre y 
  consulte de forma autónoma los datos de sus propios 
  compradores. Tabla Sales.Customer, columna CustomerId 
  (rangos).
*/


/* Para calcular los rangos de una columna en la 
   Fragmentación Horizontal Primaria, se utiliza una 
   combinación de análisis estadístico de los datos 
   (consultando la base de datos) y criterios de 
   distribución de carga (según la teoría de Özsu).
     */
   
--SQL
USE AdventureWorks2022;
GO

SELECT 
    MIN(ProductID) AS MinimoID,
    MAX(ProductID) AS MaximoID,
    COUNT(*) AS TotalRegistros
FROM Production.Product;

 --H1

SELECT h.* FROM Sales.SalesOrderHeader h 
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID 
WHERE c.CustomerID <= 6024;
---0
SELECT COUNT(*) AS TotalFilas
FROM Sales.SalesOrderHeader
WHERE CustomerID <= 6024;

--H2
SELECT h.* 
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
WHERE c.CustomerID > 6024 AND c.CustomerID <= 12047;
--3082
SELECT COUNT(*) AS TotalFilas
FROM Sales.SalesOrderHeader
WHERE CustomerID > 6024 AND CustomerID <= 12047;

--H3
SELECT h.* 
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
WHERE c.CustomerID > 12047 AND c.CustomerID <= 18070;

---10718
SELECT COUNT(*) AS TotalFilas
FROM Sales.SalesOrderHeader
WHERE CustomerID > 12047 AND CustomerID <= 18070;

---H4
SELECT h.* 
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
WHERE c.CustomerID > 18070 AND c.CustomerID <= 24094;

--7569
SELECT COUNT(*) AS TotalFilas
FROM Sales.SalesOrderHeader
WHERE CustomerID > 18070 AND CustomerID <= 24094;


---H5
SELECT h.* 
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
WHERE c.CustomerID > 24094;

--10096
SELECT COUNT(*) AS TotalFilas
FROM Sales.SalesOrderHeader
WHERE CustomerID > 24094;

-------------------------------------------
WITH VentasOrdenadas AS (
    SELECT 
        CustomerID,
        NTILE(5) OVER (ORDER BY CustomerID) AS NumeroNodo
    FROM Sales.SalesOrderHeader
)
SELECT 
    NumeroNodo,
    MIN(CustomerID) AS MinCustomerID,
    MAX(CustomerID) AS MaxCustomerID,
    COUNT(*) AS TotalPedidos
FROM VentasOrdenadas
GROUP BY NumeroNodo
ORDER BY NumeroNodo;

---------------------------
--H1 norte

SELECT h.* FROM Sales.SalesOrderHeader h 
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID 
WHERE c.CustomerID <= 13629;

SELECT COUNT(*) AS TotalFilas
FROM Sales.SalesOrderHeader
WHERE CustomerID <= 13629;
---6294

--H2
SELECT h.* 
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
WHERE c.CustomerID > 13629 AND c.CustomerID <= 17245;

SELECT COUNT(*) AS TotalFilas
FROM Sales.SalesOrderHeader
WHERE CustomerID > 13629 AND CustomerID <= 17245;
----6293

---H3
SELECT h.* 
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
WHERE c.CustomerID > 17245 AND c.CustomerID <= 21921;

SELECT COUNT(*) AS TotalFilas
FROM Sales.SalesOrderHeader
WHERE CustomerID > 17245 AND CustomerID <= 21921;
----6292

--H4
SELECT h.* 
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
WHERE c.CustomerID > 21921 AND c.CustomerID <= 27239;

SELECT COUNT(*) AS TotalFilas
FROM Sales.SalesOrderHeader
WHERE CustomerID > 21921 AND CustomerID <= 27239;
--6293

---H5
SELECT h.* 
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
WHERE c.CustomerID > 27239;

SELECT COUNT(*) AS TotalFilas
FROM Sales.SalesOrderHeader
WHERE CustomerID > 27239;

-----6293

------------------------------
--D1
SELECT d.* 
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
WHERE c.CustomerID <=13629;


---D2
SELECT d.* 
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
WHERE c.CustomerID > 13629 AND c.CustomerID <=17245;

---D3
SELECT d.* 
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
WHERE c.CustomerID > 17245 AND c.CustomerID <= 21921;

----D4
SELECT d.* 
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
WHERE c.CustomerID > 21921 AND c.CustomerID <= 27239;

----D5
SELECT d.* 
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
WHERE c.CustomerID > 27239;











