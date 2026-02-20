/*Problema resuelto de encontrar alumnos que hayan cursado y aprobado todas la materias que ha impartido el profesor P0000001. */ 
/* 
    Implementación de una división del álgebra relacional 
    R÷S=π_boleta(R) - π_boleta((π_boleta(R)×S)-R)
 
S = materias que ha impartido el profesor 'P0000001'
R = alumnos que aprobaron alguna materia del profesor.
π_boleta(R) = lista de todos los alumnos.
π_boleta(R) × S = combina cada alumno con todas las materias del profesor.
(π_boleta(R) × S) - R = pares alumno-materia faltante, es decir materias que no aprobó.
π_boleta(...) = alumnos que tienen al menos una materia faltante.
Finalmente, restamos del total de alumnos: quedan solo los que aprobaron todas las materias.
 
*/
-- solución usando vistas
-- tabla virtual generada a través de una consulta
go
create view R as
SELECT DISTINCT c.boleta, c.clave
    FROM escuela.cursa c
    JOIN escuela.Imparte i
      ON c.clave = i.clave
    WHERE i.numEmpleado = 'P0000001'
      AND c.calif >= 6
 
 
go 
create view S as
SELECT DISTINCT clave
FROM escuela.Imparte
WHERE numEmpleado = 'P0000001'
 
go
create view RXS as
SELECT a.boleta, s.clave
    FROM (SELECT DISTINCT boleta FROM R) a
    CROSS JOIN S
 
go 
create view RXS_R as
   SELECT tc.boleta, tc.clave
    FROM RXS tc
	where not exists (select 1
	                  from R
					  where tc.boleta = r.boleta 
					  AND tc.clave = r.clave)

go
SELECT boleta
FROM R
EXCEPT
SELECT boleta 
FROM RXS_R

 
/*Tarea: cambiar la consulta ocupando WITH */
use Escuela

WITH R As (
SELECT DISTINCT c.boleta, c.clave
    FROM escuela.cursa c
    JOIN escuela.Imparte i
     ON c.clave = i.clave
    WHERE i.numEmpleado = 'P0000001'
      AND c.calif >= 6
),
S As(
    SELECT DISTINCT clave
    FROM escuela.Imparte
    WHERE numEmpleado = 'P0000001' 
),
RXS As (
    SELECT a.boleta, s.clave
    FROM (SELECT DISTINCT boleta FROM R) a
    CROSS JOIN S
), 
RXS_R As (
    SELECT tc.boleta, tc.clave
    FROM RXS tc
	where not exists (select 1
	                  from R
					  where tc.boleta = r.boleta 
					  AND tc.clave = r.clave
                      )
 )
             
SELECT boleta
FROM R
EXCEPT
SELECT boleta 
FROM RXS_R
