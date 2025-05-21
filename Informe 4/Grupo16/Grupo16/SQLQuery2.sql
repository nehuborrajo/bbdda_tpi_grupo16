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

--CREO SP PARA INSERTAR SOCIOS (Inscripcion Individual)
go
create or alter procedure sp.InsertarSocio (@nombre varchar(50), @apellido varchar(50), @dni int, @email varchar(40), @fecha_nac date, @telefono varchar(20), @tel_contacto varchar(20), @obra_social varchar(30), @num_carnet_obra_social varchar(30), @nuevo_id int output)
as
begin
	IF NOT EXISTS (SELECT 1 FROM socios.Socio WHERE dni = @dni)
	begin
	declare @usuario_id int
	DECLARE @edad INT;
	DECLARE @categoria VARCHAR(10);
	-- Calcular edad exacta
	SET @edad = DATEDIFF(YEAR, @fecha_nac, GETDATE());
	-- Ajustar edad si aún no cumplió años este año
	IF (DATEADD(YEAR, @edad, @fecha_nac) > GETDATE())
		SET @edad = @edad - 1;
	-- Asignar categoría según la edad
	SET @categoria = CASE 
		WHEN @edad <= 12 THEN 'Menor'
		WHEN @edad BETWEEN 13 AND 17 THEN 'Cadete'
		ELSE 'Mayor'
	END;

	declare @membresia_id int
	set @membresia_id = (select m.id from socios.Membresia m
						where m.nombre like @categoria)

	
	exec sp.CrearUsuario @dni, 'Socio', @id_usuario = @usuario_id OUTPUT
	insert into socios.Socio (nombre, apellido, dni, email, fecha_nac, telefono, tel_contacto, obra_social, num_carnet_obra_social, membresia_id, usuario_id)
	values (@nombre, @apellido, @dni, @email, @fecha_nac, @telefono, @tel_contacto, @obra_social,
	@num_carnet_obra_social, @membresia_id, @usuario_id)

	PRINT 'Socio agregado correctamente.';
	end

	else
		RAISERROR('El DNI especificado ya existe en el sistema.', 16, 1);

end

--SP para crear usuario a partir de un nuevo dni de socio
go
create or alter procedure sp.CrearUsuario (@dni int, @rol varchar(15), @id_usuario int output)
as
begin
	SET NOCOUNT ON;
	declare @fecha_cad date
	set @fecha_cad = DATEADD(YEAR, 1, GETDATE());
	insert into socios.Usuario values (@dni, @dni, @rol, @fecha_cad)
	SET @id_usuario = SCOPE_IDENTITY()
end


--CREO SP PARA INSERTAR Grupo Familiar (Inscripcion Familiar)
go
create or alter procedure sp.InsertarSocioFamiliar (@nombre varchar(50), @apellido varchar(50), @dni int, @email varchar(40), @fecha_nac date, @telefono varchar(20), @parentesco varchar(15),
@nombre_menor varchar(50), @apellido_menor varchar(50), @dni_menor int, @fecha_nac_menor date, @obra_social varchar(30), @num_carnet_obra_social varchar(30))
as
begin
	declare @usuario_id int
	declare responsable_id int
	if not exists (select 1 from socios.Usuario where nombre_usuario = @dni)
	begin
		exec sp.CrearUsuario @dni, 'Socio', @id_usuario = @usuario_id OUTPUT
	end
	else
	begin
		set @usuario_id = (select id from socios.Usuario where nombre_usuario = @dni)
	end
	insert into socios.Socio (nombre, apellido, dni, email, fecha_nac, telefono, parentesco, usuario_id) values (@nombre, @apellido, @dni, @email, @fecha_nac, @telefono, @parentesco, @usuario_id)
	
	exec sp.InsertarSocio @nombre_menor, @apellido_menor, @dni_menor, @fecha_nac_menor, @obra_social, @num_carnet_obra_social

	insert into socios.Socio (nombre, apellido, dni, email, fecha_nac, telefono, parentesco, usuario_id) values (@nombre, @apellido, @dni, @email, @fecha_nac, @telefono, @parentesco, @usuario_id)
end


--SP para borrado logico (socio inactivo) a partir de DNI
go
create or alter procedure sp.DesactivarSocio (@dni int)
as
begin
		IF EXISTS (SELECT 1 FROM socios.Socio WHERE dni = @dni AND activo = 1)
		begin
			update socios.Socio
			set activo = 0
			where dni = @dni
			print 'Socio inhabilitado correctamente.'
		end
		else
			RAISERROR('El DNI especificado no existe en el sistema o el socio ya se encuentra inactivo.', 16, 1);
end

--SP para borrado fisico de un socio a partir de DNI
go
create or alter procedure sp.EliminarSocio (@dni int)
as
begin
		IF EXISTS (SELECT 1 FROM socios.Socio WHERE dni = @dni)
		begin
			delete from socios.Socio
			where dni = @dni
			print 'Socio eliminado correctamente.'
		end
		else
			RAISERROR('El DNI especificado no existe en el sistema.', 16, 1);
end

--SP para dar de alta de forma logica un socio a partir de DNI
go
create or alter procedure sp.ActivarSocio (@dni int)
as
begin
		IF EXISTS (SELECT 1 FROM socios.Socio WHERE dni = @dni AND activo = 0)
		begin
			update socios.Socio
			set activo = 1
			where dni = @dni
			print 'Socio activado correctamente.'
		end
		else
			RAISERROR('El DNI especificado no existe en el sistema o ya se encuenta activo.', 16, 1);
end


--SP para insertar tipos de membresias
go
create or alter procedure sp.InsertarMembresia (@nombre varchar(15), @precio float)
as
begin
	IF NOT EXISTS (SELECT 1 FROM socios.Membresia WHERE nombre = @nombre)
	begin
		insert into socios.Membresia values (@nombre, @precio)
		PRINT 'Membresia insertada correctamente.';
	end
	else
		RAISERROR('La membresia especificada ya existe.', 16, 1);
end

--SP para modificar los valores de las membresias
go
create or alter procedure sp.ModificarValorMembresia (@nombre varchar(15), @nuevo_precio float)
as
begin
	IF EXISTS (SELECT 1 FROM socios.Membresia WHERE nombre = @nombre)
    BEGIN
        UPDATE socios.Membresia
        SET costo = @nuevo_precio
        WHERE nombre = @nombre;

        PRINT 'Precio actualizado correctamente.';
    END
    ELSE
    BEGIN
        RAISERROR('La membresía especificada no existe.', 16, 1);
    END
end

--SP para borrar Membresia por ID
go
create or alter procedure sp.EliminarMembresia (@id int)
as
begin
	IF EXISTS (SELECT 1 FROM socios.Membresia WHERE id = @id)
	begin
		delete from socios.Membresia
		where id = @id
		PRINT 'Membresia eliminada correctamente.';
	end
	else
		RAISERROR('La Membresia especificada no existe.', 16, 1);
end


--SP para insertar Actividades
go
create or alter procedure sp.InsertarActividad (@nombre varchar(15), @precio float)
as
begin
	IF NOT EXISTS (SELECT 1 FROM eventos.Actividad WHERE nombre = @nombre)
	begin
		insert into eventos.Actividad values (@nombre, @precio)
		PRINT 'Actividad insertada correctamente.';
	end
	else
		RAISERROR('La actividad especificada ya existe.', 16, 1);
end

--SP para modificar los valores de las Actividades
go
create or alter procedure sp.ModificarValorActividad (@nombre varchar(30), @nuevo_precio float)
as
begin
	IF EXISTS (SELECT 1 FROM eventos.Actividad WHERE nombre = @nombre)
    BEGIN
        UPDATE eventos.Actividad
        SET costo = @nuevo_precio
        WHERE nombre = @nombre;

        PRINT 'Precio actualizado correctamente.';
    END
    ELSE
    BEGIN
        RAISERROR('La actividad especificada no existe.', 16, 1);
    END
end


--SP para borrar Actividad por ID
go
create or alter procedure sp.EliminarActividad (@id int)
as
begin
	IF EXISTS (SELECT 1 FROM eventos.Actividad WHERE id = @id)
	begin
		delete from eventos.Actividad
		where id = @id
		PRINT 'Actividad eliminada correctamente.';
	end
	else
		RAISERROR('La actividad especificada no existe.', 16, 1);
end