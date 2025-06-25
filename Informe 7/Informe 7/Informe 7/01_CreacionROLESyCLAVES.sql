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


-- CREACION DE ROLES --

-- Tesorería
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'JefeTesoreria')
    CREATE ROLE JefeTesoreria;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'AdministrativoCobranzas')
    CREATE ROLE AdministrativoCobranzas;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'AdministrativoMorosidad')
    CREATE ROLE AdministrativoMorosidad;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'AdministrativoFacturacion')
    CREATE ROLE AdministrativoFacturacion;

-- Socios
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'AdministrativoSocio')
    CREATE ROLE AdministrativoSocio;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'SociosWeb')
    CREATE ROLE SociosWeb;

-- Autoridades
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Presidente')
    CREATE ROLE Presidente;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Vicepresidente')
    CREATE ROLE Vicepresidente;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Secretario')
    CREATE ROLE Secretario;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Vocales')
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
GRANT SELECT ON finanzas.Pago TO SociosWeb;
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
IF NOT EXISTS (
    SELECT * FROM sys.symmetric_keys 
    WHERE name = '##MS_DatabaseMasterKey##'
)
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'TuPasswordFuerte123!';
GO

-- creo certificado
IF NOT EXISTS (
    SELECT * FROM sys.certificates 
    WHERE name = 'CertEmpleados'
)
CREATE CERTIFICATE CertEmpleados
WITH SUBJECT = 'Certificado para datos sensibles';
GO

-- creo clave simetrica
IF NOT EXISTS (
    SELECT * FROM sys.symmetric_keys 
    WHERE name = 'ClaveEmpleados'
)
CREATE SYMMETRIC KEY ClaveEmpleados
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE CertEmpleados;
GO