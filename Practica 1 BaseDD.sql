select name, cant
from Production.product p
join (select top 10 productid, sum(orderqty) cant
              from sales.SalesOrderDetail sod
			  group by productid
              order by cant desc) as T
on p.ProductID = t.ProductID
 
select soh.SalesOrderID, sod.ProductID, sod.OrderQty, soh.CustomerID
from sales.SalesOrderHeader soh join sales.SalesOrderDetail sod
on soh.SalesOrderID = sod.SalesOrderID
where year(OrderDate) = '2014'


/*Ejercicio 1. Encuentra los 10 productos más vendidos en 2014, mostrando nombre 
del producto, cantidad total vendida y nombre del cliente.*/

WITH Top10Productos AS (
    --10 productos más vendidos del 2014
    SELECT TOP 10 
        sod.ProductID, 
        SUM(sod.OrderQty) AS CantidadTotalGlobal
    FROM Sales.SalesOrderDetail sod
    JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    WHERE YEAR(soh.OrderDate) = 2014
    GROUP BY sod.ProductID
    ORDER BY CantidadTotalGlobal DESC
),
VentasDetalladas AS (
    -- Cantidad que compro cada cliente de esos 10 productos
    SELECT 
        t10.ProductID,
        t10.CantidadTotalGlobal,
        soh.CustomerID,
        SUM(sod.OrderQty) AS CantidadPorCliente,
        ROW_NUMBER() OVER(PARTITION BY t10.ProductID ORDER BY SUM(sod.OrderQty) DESC) as RankingCliente
    FROM Top10Productos t10
    JOIN Sales.SalesOrderDetail sod ON t10.ProductID = sod.ProductID
    JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    WHERE YEAR(soh.OrderDate) = 2014
    GROUP BY t10.ProductID, t10.CantidadTotalGlobal, soh.CustomerID
)
--Union de nombre de productos y personas
SELECT 
    p.Name AS [Nombre del Producto],
    vd.CantidadTotalGlobal AS [Total Vendido 2014],
    per.FirstName + ' ' + per.LastName AS [Cliente que más compró],
    vd.CantidadPorCliente AS [Cantidad comprada por este cliente]
FROM VentasDetalladas vd
JOIN Production.Product p ON vd.ProductID = p.ProductID
JOIN Sales.Customer c ON vd.CustomerID = c.CustomerID
JOIN Person.Person per ON c.PersonID = per.BusinessEntityID
WHERE vd.RankingCliente = 1
ORDER BY vd.CantidadTotalGlobal DESC;


--Solucion Practica 1 Ejercicio 1.1	Una vez resuelta la consulta: agrega el precio unitario
--promedio (AVG(UnitPrice)) y filtra solo productos con ListPrice > 1000.
SELECT 
    p.Name, 
    t.cant, 
    t.PromedioPrecio, 
    MAX(per.FirstName + ' ' + per.LastName) AS [Cliente (Ejemplo)]
FROM Production.Product p
JOIN (
    SELECT TOP 10 
        sod.ProductID, 
        SUM(sod.OrderQty) AS cant, 
        AVG(sod.UnitPrice) AS PromedioPrecio
    FROM sales.SalesOrderDetail sod
    JOIN sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    JOIN Production.Product p_f ON sod.ProductID = p_f.ProductID
    WHERE YEAR(soh.OrderDate) = '2014' 
      AND p_f.ListPrice > 1000
    GROUP BY sod.ProductID
    ORDER BY cant DESC
) AS t ON p.ProductID = t.ProductID
JOIN sales.SalesOrderDetail sod_all ON p.ProductID = sod_all.ProductID
JOIN sales.SalesOrderHeader soh_all ON sod_all.SalesOrderID = soh_all.SalesOrderID
JOIN sales.Customer c ON soh_all.CustomerID = c.CustomerID
JOIN Person.Person per ON c.PersonID = per.BusinessEntityID
WHERE YEAR(soh_all.OrderDate) = '2014'
GROUP BY p.Name, t.cant, t.PromedioPrecio
ORDER BY t.cant DESC;

/*Practica 1 Ejercicio 2:Lista los empleados que han vendido más que el promedio
de ventas por empleado en el territorio 'Northwest'.*/
-- 1. Calculamos el promedio global del territorio 'Northwest'
DECLARE @PromedioNorthwest MONEY;

SELECT @PromedioNorthwest = AVG(TotalVentas)
FROM (
    SELECT SUM(TotalDue) as TotalVentas
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
    WHERE st.Name = 'Northwest'
    GROUP BY SalesPersonID
) AS VentasPorVendedor;

-- 2. Listamos a los empleados que superan ese promedio
SELECT 
    p.FirstName + ' ' + p.LastName AS Empleado,
    SUM(soh.TotalDue) AS TotalVendidoEmpleado,
    @PromedioNorthwest AS PromedioDelTerritorio
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
JOIN Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
WHERE st.Name = 'Northwest'
GROUP BY p.FirstName, p.LastName, sp.BusinessEntityID
HAVING SUM(soh.TotalDue) > @PromedioNorthwest;
---1.	Requisito adicional: aplicar subconsultas.
--Solucion Usando Subconsultas 
SELECT 
    p.FirstName + ' ' + p.LastName AS Empleado,
    SUM(soh.TotalDue) AS TotalVendidoEmpleado
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
WHERE st.Name = 'Northwest'
GROUP BY p.FirstName, p.LastName
HAVING SUM(soh.TotalDue) > (
    -- Subconsulta: El promedio de Northwest
    SELECT AVG(VentasTotales)
    FROM (
        SELECT SUM(TotalDue) AS VentasTotales
        FROM Sales.SalesOrderHeader soh2
        JOIN Sales.SalesTerritory st2 ON soh2.TerritoryID = st2.TerritoryID
        WHERE st2.Name = 'Northwest'
        GROUP BY SalesPersonID
    ) AS Sub
);
---2.	Una vez resuelta la consulta convierte la subconsulta en un CTE (Common Table Expresión).
--Conversion a CTE
WITH VentasVendedores AS (
    SELECT 
        p.FirstName + ' ' + p.LastName AS Empleado,
        SUM(soh.TotalDue) AS TotalVendido
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
    JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
    JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
    WHERE st.Name = 'Northwest'
    GROUP BY p.FirstName, p.LastName
),
PromedioFinal AS (
    SELECT AVG(TotalVendido) AS PromedioGlobal FROM VentasVendedores
)
SELECT 
    v.Empleado, 
    v.TotalVendido AS TotalVendidoEmpleado, 
    p.PromedioGlobal AS PromedioDelTerritorio
FROM VentasVendedores v, PromedioFinal p
WHERE v.TotalVendido > p.PromedioGlobal;
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

Use AdventureWorks2022;
go
----Analisis de la base de datos 
select * from  Sales.SalesOrderHeader
select *from Sales.SalesOrderDetail
select* from Production.Product
select *from HumanResources.Employee
select *from Person.Person

/*Ejercicio 3: Calcula ventas totales por territorio y año, mostrando solo aquellos 
con más de 5 órdenes y ventas > $1,000,000, ordenado por ventas descendente.*/
select * FROM Sales.SalesTerritory
select * from Sales.SalesOrderHeader

WITH Datos AS (
    SELECT 
        STerritorio.Name AS Territorio, ---por territorio y año
        YEAR(SOHeader.OrderDate) AS Anio,
        SUM(SOHeader.TotalDue) AS VentasTotales, ---- Calcula ventas totales
        COUNT(SOHeader.SalesOrderID) AS TotalOrdenes
    FROM Sales.SalesOrderHeader SOHeader
    JOIN Sales.SalesTerritory STerritorio ON SOHeader.TerritoryID = STerritorio.TerritoryID
    GROUP BY STerritorio.Name, YEAR(SOHeader.OrderDate)  ---SalesTerritory
)
    SELECT 
        Territorio,
        Anio,
        VentasTotales,
        TotalOrdenes
    FROM Datos
    WHERE TotalOrdenes > 5 AND VentasTotales > 1000000 -----con más de 5 órdenes y ventas > $1,000,000
    ORDER BY VentasTotales DESC; ------descendente
		
--1.	Una vez resuelta la consulta agrega desviación estándar de ventas --->STDEV()
WITH Datos AS (
    SELECT 
        STerritorio.Name AS Territorio, ---por territorio y año
        YEAR(SOHeader.OrderDate) AS Anio,
        SUM(SOHeader.TotalDue) AS VentasTotales, ---- Calcula ventas totales
        COUNT(SOHeader.SalesOrderID) AS TotalOrdenes,
        STDEV(SOHeader.TotalDue) AS DesviacionEstandar
    FROM Sales.SalesOrderHeader SOHeader
    JOIN Sales.SalesTerritory STerritorio ON SOHeader.TerritoryID = STerritorio.TerritoryID
    GROUP BY STerritorio.Name, YEAR(SOHeader.OrderDate)  ---SalesTerritory
) 
        SELECT *
    FROM Datos
    WHERE TotalOrdenes > 5 AND VentasTotales > 1000000 -----con más de 5 órdenes y ventas > $1,000,000
    ORDER BY VentasTotales DESC; ------descendente


/*Ejercicio 4: Encuentra vendedores que han vendido TODOS los productos de la categoría "Bikes".*/
use AdventureWorks2022
SELECT 
    P.FirstName + ' ' + P.LastName AS Vendedor,
    COUNT(DISTINCT SOD.ProductID) AS ProductosBikesVendidos
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN Production.Product PR ON SOD.ProductID = PR.ProductID
JOIN Production.ProductSubcategory PS ON PR.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
JOIN HumanResources.Employee E ON SOH.SalesPersonID = E.BusinessEntityID
JOIN Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
WHERE PC.Name = 'Bikes'
GROUP BY P.FirstName, P.LastName
HAVING COUNT(DISTINCT SOD.ProductID) = (
    -- Esta subconsulta cuenta cuántas "Bikes" existen en total
    SELECT COUNT(ProductID) 
    FROM Production.Product P2
    JOIN Production.ProductSubcategory PS2 ON P2.ProductSubcategoryID = PS2.ProductSubcategoryID
    JOIN Production.ProductCategory PC2 ON PS2.ProductCategoryID = PC2.ProductCategoryID
    WHERE PC2.Name = 'Bikes'
);
--1.	Cambia a categoría "Clothing" (ID=4).
SELECT 
    P.FirstName + ' ' + P.LastName AS Vendedor,
    COUNT(DISTINCT SOD.ProductID) AS ProductosRopaVendidos
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN Production.Product PR ON SOD.ProductID = PR.ProductID
JOIN Production.ProductSubcategory PS ON PR.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN HumanResources.Employee E ON SOH.SalesPersonID = E.BusinessEntityID
JOIN Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
WHERE PS.ProductCategoryID = 4 -- Filtro directo por el ID de "Clothing"
GROUP BY P.FirstName, P.LastName
HAVING COUNT(DISTINCT SOD.ProductID) = (
    -- Cuenta cuántos productos existen en la categoría 4
    SELECT COUNT(ProductID) 
    FROM Production.Product P2
    JOIN Production.ProductSubcategory PS2 ON P2.ProductSubcategoryID = PS2.ProductSubcategoryID
    WHERE PS2.ProductCategoryID = 4
);

--2.	Cuenta cuántos productos por categoría maneja cada vendedor.
SELECT 
    P.FirstName + ' ' + P.LastName AS Vendedor,
    PC.Name AS Categoria,
    COUNT(DISTINCT SOD.ProductID) AS CantidadProductosDistintos
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN Production.Product PR ON SOD.ProductID = PR.ProductID
JOIN Production.ProductSubcategory PS ON PR.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
JOIN HumanResources.Employee E ON SOH.SalesPersonID = E.BusinessEntityID
JOIN Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
GROUP BY P.FirstName, P.LastName, PC.Name
--ORDER BY Vendedor, CantidadProductosDistintos DESC;
ORDER BY CantidadProductosDistintos DESC, Vendedor ASC;


/* Ejercicio 5: Determinar el producto más vendido de cada categoría de producto, 
considerando el escenario de que el esquema SALES se encuentra en una instancia (servidor) A 
y el esquema PRODUCTION en otra instancia (servidor) B.*/

-- CTE 1: Ventas en el servidor local
WITH VentasLocales AS (
    SELECT ProductID, SUM(OrderQty) AS CantidadTotal
    FROM Sales.SalesOrderDetail
    GROUP BY ProductID
),
-- CTE 2: Catálogo en el servidor vinculado 'CITLALi'
CatalogoRemoto AS (
    SELECT 
        p.ProductID, 
        p.Name AS NombreProducto, 
        c.Name AS NombreCategoria
    FROM CITLALi.AdventureWorks2022.Production.Product p
    JOIN CITLALi.AdventureWorks2022.Production.ProductSubcategory s ON p.ProductSubcategoryID = s.ProductSubcategoryID
    JOIN CITLALi.AdventureWorks2022.Production.ProductCategory c ON s.ProductCategoryID = c.ProductCategoryID
),
-- CTE 3: Identificar el producto más vendido por categoría
RankingProductos AS (
    SELECT 
        cr.NombreCategoria,
        cr.NombreProducto,
        vl.CantidadTotal,
        RANK() OVER (PARTITION BY cr.NombreCategoria ORDER BY vl.CantidadTotal DESC) AS Posicion
    FROM VentasLocales vl
    JOIN CatalogoRemoto cr ON vl.ProductID = cr.ProductID
)
-- Consulta Final
SELECT NombreCategoria, NombreProducto, CantidadTotal
FROM RankingProductos
WHERE Posicion = 1
ORDER BY CantidadTotal DESC;

--Con mi propia maquina
SELECT @@SERVERNAME;

-- Creamos el servidor vinculado usando tu nombre de instancia
EXEC sp_addlinkedserver 
    @server = 'BOLILLOJULIAN\SQLEXPRESS', 
    @srvproduct = '',
    @provider = 'SQLNCLI', 
    @datasrc = 'BOLILLOJULIAN\SQLEXPRESS';

-- Configuramos para que use tus mismas credenciales actuales
EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = 'BOLILLOJULIAN\SQLEXPRESS', 
    @useself = 'True';

----------
-- CTE 1: Agregamos las ventas desde el esquema SALES (Instancia A)
WITH VentasLocales AS (
    SELECT ProductID, SUM(OrderQty) AS CantidadTotal
    FROM Sales.SalesOrderDetail
    GROUP BY ProductID
),
-- CTE 2: Consultamos el catálogo desde el esquema PRODUCTION (Instancia B - Tu PC)
CatalogoRemoto AS (
    SELECT 
        p.ProductID, 
        p.Name AS NombreProducto, 
        c.Name AS NombreCategoria
    -- Usamos el nombre de tu instancia: [Servidor].[Base].[Esquema].[Tabla]
    FROM [BOLILLOJULIAN\SQLEXPRESS].AdventureWorks2022.Production.Product p
    JOIN [BOLILLOJULIAN\SQLEXPRESS].AdventureWorks2022.Production.ProductSubcategory s 
        ON p.ProductSubcategoryID = s.ProductSubcategoryID
    JOIN [BOLILLOJULIAN\SQLEXPRESS].AdventureWorks2022.Production.ProductCategory c 
        ON s.ProductCategoryID = c.ProductCategoryID
),
-- CTE 3: Identificamos el producto más vendido por categoría
RankingProductos AS (
    SELECT 
        cr.NombreCategoria,
        cr.NombreProducto,
        vl.CantidadTotal,
        RANK() OVER (PARTITION BY cr.NombreCategoria ORDER BY vl.CantidadTotal DESC) AS Posicion
    FROM VentasLocales vl
    JOIN CatalogoRemoto cr ON vl.ProductID = cr.ProductID
)
-- Resultado Final
SELECT NombreCategoria, NombreProducto, CantidadTotal
FROM RankingProductos
WHERE Posicion = 1
ORDER BY CantidadTotal DESC;