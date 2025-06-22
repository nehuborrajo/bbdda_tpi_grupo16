/*
Enunciado Informe 6:
Reporte 1
Reporte de los socios morosos, que hayan incumplido en más de dos oportunidades dado un
rango de fechas a ingresar. El reporte debe contener los siguientes datos:
Nombre del reporte: Morosos Recurrentes
Período: rango de fechas
Nro de socio
Nombre y apellido.
Mes incumplido
Ordenados de Mayor a menor por ranking de morosidad
El mismo debe ser desarrollado utilizando Windows Function.
Reporte 2
Reporte acumulado mensual de ingresos por actividad deportiva al momento en que se saca
el reporte tomando como inicio enero.
Reporte 3
Reporte de la cantidad de socios que han realizado alguna actividad de forma alternada
(inasistencias) por categoría de socios y actividad, ordenado según cantidad de inasistencias
ordenadas de mayor a menor.
Reporte 4
Reporte que contenga a los socios que no han asistido a alguna clase de la actividad que
realizan. El reporte debe contener: Nombre, Apellido, edad, categoría y la actividad

Fecha de entrega: 20/06/2025
Numero de comision: 5600
Numero de grupo: 16
Nombre de la materia: Bases de Datos Aplicadas

Integrantes:
	Borrajo, Nehuen (DNI 45581523)
	Ferro, Nicolas Ariel (DNI 40971610)
	Lopez, Leandro Nahuel (DNI 40745048)
	Zacarias, Franco Hernan (DNI 46422064)
*/

--use master

use Com5600G16
go

-- TESTING

-- Comenzamos insertando empleados 

exec sp.InsertarEmpleado 'Lionel', 'Messi', 20156478, 'messi@gmail.com', '2020-04-03', '11-22554488'
exec sp.InsertarEmpleado 'Pipi', 'Romagnoli', 27541235, 'pipi@gmail.com', '2020-04-03', '11-33224468'

select * from socios.Socio

-- Ahora puedo encriptar los datos de todos los empleados (chequea aquellos que tienen un usuario con rol 'Administrador' --> Empleado)
-- Completara las columnas de email_cifrado, dni_cifrado y telefono_cifrado

exec sp.EncriptarDatosEmpleados

select * from socios.Socio

-- Ahora podes ver desencriptados los datos de todos los empleados

exec sp.VerDesencriptaDatosEmpleados

-- O podes verlo desencriptado por dni

exec sp.VerDesencriptadoDatosEmpleado 20156478

-- Si seleccionas un DNI no existente devuelve error

exec sp.VerDesencriptadoDatosEmpleado 30156478


-- Tambien podes directamente insertar un empleado ya cifrado

exec sp.InsertarEmpleadoEncriptado 'Nehuen', 'Borrajo', 55581523, 'nehu@gmail.com', '2020-04-03', '11-33224568'

select * from socios.Socio

