/*
Enunciado Informe 7:
Asigne los roles correspondientes para poder cumplir con este requisito, según el área a la
cual pertenece.
Por otra parte, se requiere que los datos de los empleados se encuentren encriptados, dado
que los mismos contienen información personal.
La información de las cuotas pagadas y adeudadas es de vital importancia para el negocio,
por ello se requiere que se establezcan políticas de respaldo tanto en las ventas diarias
generadas como en los reportes generados.
Plantee una política de respaldo adecuada para cumplir con este requisito y justifique la
misma. No es necesario que incluya el código de creación de los respaldos.
Debe documentar la programación (Schedule) de los backups por día/semana/mes (de
acuerdo a lo que decidan) e indicar el RPO.

Fecha de entrega: 22/06/2025
Numero de comision: 5600
Numero de grupo: 16
Nombre de la materia: Bases de Datos Aplicadas

Integrantes:
	Borrajo, Nehuen (DNI 45581523)
	Zacarias, Franco Hernan (DNI 46422064)
*/

--use master

use Com5600G16
go

-- TESTING

-- Comenzamos insertando empleados 

exec sp.InsertarEmpleado 'Lionel', 'Messi', 99999999, 'messi@gmail.com', '2020-04-03', '11-22554488'
exec sp.InsertarEmpleado 'Pipi', 'Romagnoli', 99999998, 'pipi@gmail.com', '2020-04-03', '11-33224468'

select * from socios.Socio

-- Ahora puedo encriptar los datos de todos los empleados (chequea aquellos que tienen un usuario con rol 'Administrador' --> Empleado)
-- Completara las columnas de email_cifrado, dni_cifrado y telefono_cifrado

exec sp.EncriptarDatosEmpleados

select * from socios.Socio

-- Ahora podes ver desencriptados los datos de todos los empleados

exec sp.VerDesencriptaDatosEmpleados

-- O podes verlo desencriptado por dni

exec sp.VerDesencriptadoDatosEmpleado 99999999

-- Si seleccionas un DNI no existente devuelve error

exec sp.VerDesencriptadoDatosEmpleado 30156478


-- Tambien podes directamente insertar un empleado ya cifrado

exec sp.InsertarEmpleadoEncriptado 'Nehuen', 'Borrajo', 55581525, 'nehu@gmail.com', '2020-04-03', '11-33224568'

select * from socios.Socio

