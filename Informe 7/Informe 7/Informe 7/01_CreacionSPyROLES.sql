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

--CREO ESQUEMAS PARA SP

IF NOT EXISTS (
    SELECT * FROM sys.schemas WHERE name = 'sp'
)
BEGIN
    EXEC('CREATE SCHEMA sp');
END;


-- CREACION DE ROLES --

-- Tesorería
CREATE ROLE JefeTesoreria;
CREATE ROLE AdministrativoCobranzas;
CREATE ROLE AdministrativoMorosidad;
CREATE ROLE AdministrativoFacturacion;

-- Socios
CREATE ROLE AdministrativoSocio;
CREATE ROLE SociosWeb;

-- Autoridades
CREATE ROLE Presidente;
CREATE ROLE Vicepresidente;
CREATE ROLE Secretario;
CREATE ROLE Vocales;


-- ASIGNACION DE ROLES --

-- Tesoreria

-- Roles AdministrativoCobranzas
GRANT SELECT, UPDATE, INSERT ON finanzas.Cuota TO AdministrativoCobranzas;
GRANT SELECT, INSERT ON finanzas.Factura TO AdministrativoCobranzas;
GRANT SELECT, INSERT ON finanzas.Pago TO AdministrativoCobranzas;
GRANT SELECT, UPDATE, INSERT ON finanzas.MetodoPago TO AdministrativoCobranzas;
GRANT SELECT, INSERT ON finanzas.TarifasAcceso TO AdministrativoCobranzas;

-- Roles AdministrativoMorosidad
GRANT SELECT, INSERT, UPDATE ON finanzas.Moroso TO AdministrativoMorosidad;
GRANT SELECT, INSERT ON finanzas.Factura TO AdministrativoMorosidad;
GRANT SELECT, INSERT ON finanzas.Cuota TO AdministrativoMorosidad;
GRANT SELECT, UPDATE, INSERT ON finanzas.Pago TO AdministrativoMorosidad;

-- Roles AdministrativoFacturacion
GRANT SELECT, UPDATE, INSERT ON finanzas.Factura TO AdministrativoFacturacion;
GRANT SELECT, UPDATE, INSERT ON finanzas.Cuota TO AdministrativoFacturacion;
GRANT SELECT, UPDATE, INSERT ON finanzas.Pago TO AdministrativoFacturacion;
GRANT SELECT, UPDATE, INSERT ON finanzas.MetodoPago TO AdministrativoFacturacion;

-- Roles JefeTesoreria
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::finanzas TO JefeTesoreria;

-- Socios

-- Roles AdministrativoSocio
GRANT SELECT, INSERT, UPDATE ON socios.Socio TO AdministrativoSocio;
GRANT SELECT, INSERT, UPDATE ON eventos.SocioActividad TO AdministrativoSocio;
GRANT SELECT, INSERT, UPDATE ON eventos.Actividad TO AdministrativoSocio;
GRANT SELECT, INSERT, UPDATE ON socios.Membresia TO AdministrativoSocio;
GRANT SELECT, INSERT, UPDATE ON socios.Usuario TO AdministrativoSocio;
GRANT SELECT, INSERT, UPDATE ON eventos.Reserva TO AdministrativoSocio;

-- Roles SociosWeb
GRANT SELECT ON socios.Socio TO SociosWeb;
GRANT SELECT ON finanzas.Cuota TO SociosWeb;
GRANT SELECT ON socios.Pago TO SociosWeb;
GRANT SELECT ON eventos.SocioActividad TO SociosWeb;

-- Autoridades

-- Roles Presidente
GRANT SELECT ON SCHEMA::socios TO Presidente;
GRANT SELECT ON SCHEMA::eventos TO Presidente;
GRANT SELECT ON SCHEMA::finanzas TO Presidente;

-- Roles Vicepresidente
GRANT SELECT ON SCHEMA::socios TO Vicepresidente;
GRANT SELECT ON SCHEMA::eventos TO Vicepresidente;
GRANT SELECT ON SCHEMA::finanzas TO Vicepresidente;

-- Roles Secretario 
GRANT SELECT ON SCHEMA::socios TO Secretario;
GRANT SELECT ON SCHEMA::eventos TO Secretario;
GRANT SELECT ON SCHEMA::finanzas TO Secretario;

-- Roles Vocales 
GRANT SELECT ON SCHEMA::socios TO Vocales;
GRANT SELECT ON SCHEMA::eventos TO Vocales;
GRANT SELECT ON SCHEMA::finanzas TO Vocales;



-- ENCRIPTACION DE DATOS --

-- creo clave maestra
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'TuPasswordFuerte123!';
GO

-- creo certificado
CREATE CERTIFICATE CertEmpleados
WITH SUBJECT = 'Certificado para datos sensibles';
GO

-- creo clave simetrica
CREATE SYMMETRIC KEY ClaveSocio
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE CertEmpleados;
GO


--CREACION DE SP's--

/*
alter table socios.Socio
add dni_cifrado VARBINARY(256);
alter table socios.Socio
add email_cifrado VARBINARY(256);
alter table socios.Socio
add telefono_cifrado VARBINARY(256);
*/

-- sp para cifrar el dni, email y telefono de los empleados de la tabla Socio
go
create or alter procedure sp.EncriptarDatosEmpleados
as
begin
	
	OPEN SYMMETRIC KEY ClaveSocio DECRYPTION BY CERTIFICATE CertEmpleados;

	UPDATE s
	set
		email_cifrado = EncryptByKey(Key_GUID('ClaveSocio'), email),
		dni_cifrado = EncryptByKey(Key_GUID('ClaveSocio'), CAST(dni AS VARCHAR)),
		telefono_cifrado = EncryptByKey(Key_GUID('ClaveSocio'), telefono)
	FROM socios.Socio s
	JOIN socios.Usuario u ON s.usuario_id = u.id
	WHERE u.rol = 'Administrador';

	CLOSE SYMMETRIC KEY ClaveSocio;

end

-----------------------------------------------------------------------------------------

-- sp para desencriptar los datos

go
create or alter procedure sp.DesencriptarDatosEmpleados
as
begin
	
	OPEN SYMMETRIC KEY ClaveSocio DECRYPTION BY CERTIFICATE CertEmpleados;

	SELECT 
		s.numero_socio,
		s.nombre,
		s.apellido,
		CONVERT(varchar(100), DecryptByKey(s.email_cifrado)) AS email,
		CONVERT(int, DecryptByKey(s.dni_cifrado)) AS dni,
		CONVERT(varchar(20), DecryptByKey(s.telefono_cifrado)) AS telefono,
		u.rol
	FROM socios.Socio s
	JOIN socios.Usuario u ON s.usuario_id = u.id
	WHERE u.rol = 'Administrador';

	CLOSE SYMMETRIC KEY ClaveSocio;

end
