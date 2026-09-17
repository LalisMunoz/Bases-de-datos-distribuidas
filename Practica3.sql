USE covidHistorico2;
GO
---------------------iNTEGRANTES:
--Muñoz Reyes Citlali
--Gutierrez Flores Jose Julian 
ALTER DATABASE Covidhistorico2 ADD FILEGROUP FG_ANTES_2020;
ALTER DATABASE CovidHistorico2 ADD FILEGROUP FG_2020;
ALTER DATABASE CovidHistorico2 ADD FILEGROUP FG_2021;
ALTER DATABASE CovidHistorico2 ADD FILEGROUP FG_2022_MAS;

ALTER DATABASE CovidHistorico2 
ADD FILE (NAME = FG_ANTES_2020_dat, FILENAME = 'D:\BDD\Data\FG_ANTES_2020.ndf')
TO FILEGROUP FG_ANTES_2020;

ALTER DATABASE CovidHistorico2
ADD FILE (NAME = FG_2020_dat, FILENAME = 'D:\BDD\Data\FG_2020.ndf')
TO FILEGROUP FG_2020;

ALTER DATABASE CovidHistorico2
ADD FILE (NAME = FG_2021_dat, FILENAME = 'D:\BDD\Data\FG_2021.ndf')
TO FILEGROUP FG_2021;

ALTER DATABASE CovidHistorico2
ADD FILE (NAME = FG_2022_MAS_dat, FILENAME = 'D:\BDD\Data\FG_2022_MAS.ndf')
TO FILEGROUP FG_2022_MAS;

-- 1. Creamos la función
CREATE PARTITION FUNCTION pf_anio (DATE)
AS RANGE RIGHT FOR VALUES 
('2020-01-01', '2021-01-01', '2022-01-01');
GO

---
CREATE PARTITION SCHEME ps_anio
AS PARTITION pf_anio
TO (
    FG_ANTES_2020,  -- < 2020-01-01
    FG_2020,        -- >= 2020-01-01 y < 2021-01-01
    FG_2021,        -- >= 2021-01-01 y < 2022-01-01
    FG_2022_MAS     -- >= 2022-01-01
);
/*
CREATE TABLE cc_particionado (
    Id INT NOT NULL,
    Fecha DATE NOT NULL,
    edad DECIMAL(10,2),
    CONSTRAINT PK_cc_particionado
        PRIMARY KEY CLUSTERED (Fecha, Id) -- 👈 clave alineada
)
ON ps_anio (Fecha);
*/
CREATE TABLE covid_particionado (
    FECHA_INGRESO DATE,
    ENTIDAD_RES VARCHAR(50),
    EDAD INT
)
ON ps_anio(FECHA_INGRESO);

CREATE CLUSTERED INDEX idx_fecha
ON covid_particionado(FECHA_INGRESO)
ON ps_anio(FECHA_INGRESO);
------------------
INSERT INTO covid_particionado (FECHA_INGRESO, ENTIDAD_RES, EDAD)
SELECT 
    TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO, '"', '')),
    REPLACE(ENTIDAD_RES, '"', ''),
    TRY_CONVERT(INT, REPLACE(EDAD, '"', ''))
FROM datoscovid
WHERE TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO, '"', ''))
IS NOT NULL;
GO

----------------tamaño
USE master;
GO

ALTER DATABASE covidHistorico2 MODIFY FILE (NAME = FG_ANTES_2020_dat, SIZE = 100MB);
ALTER DATABASE covidHistorico2 MODIFY FILE (NAME = FG_2020_dat, SIZE = 100MB);
ALTER DATABASE covidHistorico2 MODIFY FILE (NAME = FG_2021_dat, SIZE = 100MB);
ALTER DATABASE covidHistorico2 MODIFY FILE (NAME = FG_2022_MAS_dat, SIZE = 100MB);
GO
-------------------------------------
USE covidHistorico2;
GO

-- 1. Vaciamos la tabla para asegurar que no haya datos basura de intentos fallidos
TRUNCATE TABLE covid_particionado;
GO

-- 2. Insertamos una muestra pequeña del año 2020
INSERT INTO covid_particionado (FECHA_INGRESO, ENTIDAD_RES, EDAD)
SELECT TOP 50000 
    TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO, '"', '')),
    REPLACE(ENTIDAD_RES, '"', ''),
    TRY_CONVERT(INT, REPLACE(EDAD, '"', ''))
FROM datoscovid
WHERE TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO, '"', '')) >= '2020-01-01' 
  AND TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO, '"', '')) <= '2020-12-31';
GO

-- 3. Insertamos una muestra pequeña del año 2021
INSERT INTO covid_particionado (FECHA_INGRESO, ENTIDAD_RES, EDAD)
SELECT TOP 50000 
    TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO, '"', '')),
    REPLACE(ENTIDAD_RES, '"', ''),
    TRY_CONVERT(INT, REPLACE(EDAD, '"', ''))
FROM datoscovid
WHERE TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO, '"', '')) >= '2021-01-01' 
  AND TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO, '"', '')) <= '2021-12-31';
GO

-- 4. Insertamos una muestra pequeña del año 2022
INSERT INTO covid_particionado (FECHA_INGRESO, ENTIDAD_RES, EDAD)
SELECT TOP 50000 
    TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO, '"', '')),
    REPLACE(ENTIDAD_RES, '"', ''),
    TRY_CONVERT(INT, REPLACE(EDAD, '"', ''))
FROM datoscovid
WHERE TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO, '"', '')) >= '2022-01-01';
GO

-----------------------
USE covidHistorico2;
GO

-- 1. Vaciamos la tabla para iniciar limpios
TRUNCATE TABLE covid_particionado;
GO

-- 2. Volvemos a lanzar la inserción de datos
INSERT INTO covid_particionado (FECHA_INGRESO, ENTIDAD_RES, EDAD)
SELECT 
    TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO, '"', '')),
    REPLACE(ENTIDAD_RES, '"', ''),
    TRY_CONVERT(INT, REPLACE(EDAD, '"', ''))
FROM datoscovid
WHERE TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO, '"', '')) IS NOT NULL;
GO
------------ Comprobacion final 
USE covidHistorico2;
GO

SELECT 
    t.name AS [Tabla],
    p.partition_number AS [Número Partición],
    fg.name AS [Grupo de Archivos (Filegroup)],
    p.rows AS [Total de Filas por Año]
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
JOIN sys.destination_data_spaces dds ON i.data_space_id = dds.partition_scheme_id AND p.partition_number = dds.destination_id
JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
WHERE t.name = 'covid_particionado' AND i.index_id IN (0,1);
GO


-----verificacion 
USE covidHistorico2;
GO

SELECT 
    t.name AS [Tabla],
    p.partition_number AS [Número Partición],
    fg.name AS [Grupo de Archivos (Filegroup)],
    p.rows AS [Total de Filas por Año]
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
JOIN sys.destination_data_spaces dds ON i.data_space_id = dds.partition_scheme_id AND p.partition_number = dds.destination_id
JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
WHERE t.name = 'covid_particionado' AND i.index_id IN (0,1);
GO
