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
		if @numero_socio is NULL
			set @numero_socio = 1
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
		if @numero_socio is NULL
			set @numero_socio = 1
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