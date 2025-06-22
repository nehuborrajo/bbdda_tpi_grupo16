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


--CREACION DE SP's--

--SP para crear usuario a partir de un nuevo dni de socio
go
create or alter procedure sp.CrearUsuarioNuevo (@dni int, @rol varchar(15), @id_usuario int output)
as
begin
	SET NOCOUNT ON;
	if not exists (select 1 from socios.Usuario where nombre_usuario = @dni)
	begin
		declare @fecha_cad date
		set @fecha_cad = DATEADD(YEAR, 1, GETDATE());
		insert into socios.Usuario values (@dni, @dni, @rol, @fecha_cad)
		set @id_usuario = SCOPE_IDENTITY()
	end
	else
		RAISERROR('El DNI ya esta asociado a un usuario existente.', 16, 1);
end

-----------------------------------------------------------------------------------------


-- sp para cifrar el dni, email y telefono de los empleados de la tabla Socio
go
create or alter procedure sp.EncriptarDatosEmpleados
as
begin
	
	OPEN SYMMETRIC KEY ClaveEmpleados DECRYPTION BY CERTIFICATE CertEmpleados;

	UPDATE s
	set
		email_cifrado = EncryptByKey(Key_GUID('ClaveEmpleados'), email),
		dni_cifrado = EncryptByKey(Key_GUID('ClaveEmpleados'), CONVERT(varchar(20), dni)),
		telefono_cifrado = EncryptByKey(Key_GUID('ClaveEmpleados'), telefono)
	FROM socios.Socio s
	JOIN socios.Usuario u ON s.usuario_id = u.id
	WHERE u.rol = 'Administrador';

	CLOSE SYMMETRIC KEY ClaveEmpleados;

end

-----------------------------------------------------------------------------------------

-- sp para ver desencriptados los datos de los empleados

go
create or alter procedure sp.VerDesencriptaDatosEmpleados
as
begin
	
	OPEN SYMMETRIC KEY ClaveEmpleados DECRYPTION BY CERTIFICATE CertEmpleados;

	SELECT 
		s.numero_socio,
		s.nombre,
		s.apellido,
		CONVERT(varchar(100), DecryptByKey(s.email_cifrado)) AS email,
		CONVERT(varchar(20), DecryptByKey(s.dni_cifrado)) AS dni,
		CONVERT(varchar(20), DecryptByKey(s.telefono_cifrado)) AS telefono,
		u.rol
	FROM socios.Socio s
	JOIN socios.Usuario u ON s.usuario_id = u.id
	WHERE u.rol = 'Administrador';

	CLOSE SYMMETRIC KEY ClaveEmpleados;

end

-----------------------------------------------------------------------------------------

-- sp para ver desencriptados los datos de empleado por dni

go
create or alter procedure sp.VerDesencriptadoDatosEmpleado @dni int
as
begin
	
	if not exists (select 1 from socios.Socio where dni = @dni)
	begin
		RAISERROR('No existe un socio con ese DNI.', 16, 1);
		return
	end

	OPEN SYMMETRIC KEY ClaveEmpleados DECRYPTION BY CERTIFICATE CertEmpleados;

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
	WHERE u.rol = 'Administrador' and dni = @dni;

	CLOSE SYMMETRIC KEY ClaveEmpleados;

end

-----------------------------------------------------------------------------------------

-- sp para insertar empleado con los datos ya encriptados

go
create or alter procedure sp.InsertarEmpleadoEncriptado (@nombre varchar(50), @apellido varchar(50), @dni int, @email varchar(100), @fecha_nac date, @telefono varchar(20))
as
begin

	if exists (select 1 from socios.Socio where dni = @dni)
	begin
		RAISERROR('Ya existe un socio con ese DNI.', 16, 1);
		return
	end

	begin try
		begin transaction
		declare @usuario_id int
		declare @numero_socio int = (select max(numero_socio)+1 from socios.Socio)
		exec sp.CrearUsuarioNuevo @dni, 'Administrador', @id_usuario = @usuario_id output

		OPEN SYMMETRIC KEY ClaveEmpleados DECRYPTION BY CERTIFICATE CertEmpleados;

		DECLARE @email_encriptado VARBINARY(256) = EncryptByKey(Key_GUID('ClaveEmpleados'), @email);
        DECLARE @dni_encriptado VARBINARY(256) = EncryptByKey(Key_GUID('ClaveEmpleados'), CAST(@dni AS varchar));
		DECLARE @telefono_encriptado VARBINARY(256) = EncryptByKey(Key_GUID('ClaveEmpleados'), @telefono);

		insert into socios.Socio (numero_socio, nombre, apellido, dni, dni_cifrado, email, email_cifrado, fecha_nac, telefono, telefono_cifrado, activo, usuario_id, es_empleado) 
		values (@numero_socio, @nombre, @apellido, @dni, @dni_encriptado, @email, @email_encriptado, @fecha_nac, @telefono, @telefono_encriptado, 0, @usuario_id, 1)
		
		CLOSE SYMMETRIC KEY ClaveEmpleados;
		commit transaction
	end try
	begin catch
		rollback transaction
		
		IF @usuario_id IS NOT NULL
        BEGIN
            DELETE FROM socios.Usuario WHERE id = @usuario_id;
        END

        -- Propagar el error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
	end catch
end

-----------------------------------------------------------------------------------------

-- sp para insertar empleado con los datos ya encriptados

go
create or alter procedure sp.InsertarEmpleado (@nombre varchar(50), @apellido varchar(50), @dni int, @email varchar(100), @fecha_nac date, @telefono varchar(20))
as
begin

	if exists (select 1 from socios.Socio where dni = @dni)
	begin
		RAISERROR('Ya existe un socio con ese DNI.', 16, 1);
		return
	end

	begin try
		begin transaction
		declare @usuario_id int
		declare @numero_socio int = (select max(numero_socio)+1 from socios.Socio)
		exec sp.CrearUsuarioNuevo @dni, 'Administrador', @id_usuario = @usuario_id output

		insert into socios.Socio (numero_socio, nombre, apellido, dni, email, fecha_nac, telefono, activo, usuario_id, es_empleado) 
		values (@numero_socio, @nombre, @apellido, @dni, @email, @fecha_nac, @telefono, 0, @usuario_id, 1)
		
		commit transaction
	end try
	begin catch
		rollback transaction
		
		IF @usuario_id IS NOT NULL
        BEGIN
            DELETE FROM socios.Usuario WHERE id = @usuario_id;
        END

        -- Propagar el error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
	end catch
end