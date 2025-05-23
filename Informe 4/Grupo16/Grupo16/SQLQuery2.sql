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

--CREO SP PARA INSERTAR SOCIOS (Inscripcion Individual)
go
create or alter procedure sp.InsertarSocio (@nombre varchar(50), @apellido varchar(50), @dni int, @email varchar(40), @fecha_nac date, @telefono varchar(20), @tel_contacto varchar(20), @obra_social varchar(30), @num_carnet_obra_social varchar(30))
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
		WHEN @edad <= 12 THEN (select id from socios.Membresia where nombre = 'Menor')
		WHEN @edad BETWEEN 13 AND 17 THEN (select id from socios.Membresia where nombre = 'Cadete')
		ELSE (select id from socios.Membresia where nombre = 'Mayor')
	END;

	declare @membresia_id int
	set @membresia_id = (select m.id from socios.Membresia m
						where m.id like @edad)

	
	exec sp.CrearUsuarioNuevo @dni, 'Socio', @id_usuario = @usuario_id OUTPUT

	insert into socios.Socio (nombre, apellido, dni, email, fecha_nac, telefono, tel_contacto, obra_social, num_carnet_obra_social, membresia_id, usuario_id)
	values (@nombre, @apellido, @dni, @email, @fecha_nac, @telefono, @tel_contacto, @obra_social,
	@num_carnet_obra_social, @categoria, @usuario_id)

	PRINT 'Socio agregado correctamente.';
	end
	else
		RAISERROR('El DNI pertenece a un socio ya existente.', 16, 1);

end

--SP para crear usuario a partir de un nuevo dni de socio
go
create or alter procedure sp.CrearUsuarioNuevo (@dni int, @rol varchar(15))
as
begin
	SET NOCOUNT ON;
	if not exists (select 1 from socios.Usuario where nombre_usuario = @dni)
	begin
		declare @fecha_cad date
		set @fecha_cad = DATEADD(YEAR, 1, GETDATE());
		insert into socios.Usuario values (@dni, @dni, @rol, @fecha_cad)
	end
	else
		RAISERROR('El DNI ya esta asociado a un usuario existente.', 16, 1);
end

--SP para crear nuevo usuario a socio existente
go
create or alter procedure sp.CrearUsuarioSocio (@dni int, @rol varchar(20))
as
begin
	if exists (select 1 from socios.Socio where dni = @dni and activo=1 and usuario_id is NULL)
	begin
		if not exists (select 1 from socios.Usuario where nombre_usuario = @dni)
		begin
			declare @fecha_cad date
			declare @usuario_id int
			set @fecha_cad = DATEADD(YEAR, 1, GETDATE());
			insert into socios.Usuario values (@dni, @dni, @rol, @fecha_cad)
			SET @usuario_id = SCOPE_IDENTITY()
			update socios.Socio	
				set usuario_id = @usuario_id
				where dni = @dni
		end
		else
			RAISERROR('El DNI pertene a un socio con usuario.', 16, 1);
	end
	else
		RAISERROR('El DNI no pertenece a un socio activo o ya tiene un usuario asociado.', 16, 1);
end

--CREO SP PARA INSERTAR Grupo Familiar (Inscripcion Familiar)
go
create or alter procedure sp.InsertarSocioFamiliar (@nombre varchar(50), @apellido varchar(50), @dni int, @email varchar(40), @fecha_nac date, @telefono varchar(20), @parentesco varchar(15),
@nombre_menor varchar(50), @apellido_menor varchar(50), @dni_menor int, @fecha_nac_menor date, @obra_social varchar(30), @num_carnet_obra_social varchar(30))
as
begin
	declare @usuario_id int
	declare @familiar_id int
	if not exists (select 1 from socios.Usuario where nombre_usuario = @dni)
	begin
		exec sp.CrearUsuario @dni, 'Socio', @id_usuario = @usuario_id OUTPUT
	end
	else
	begin
		set @usuario_id = (select id from socios.Usuario where nombre_usuario = @dni)
	end

	--inserto primero al menor
	IF DATEDIFF(YEAR, @fecha_nac_menor, GETDATE()) < 18
	begin
		if not exists (select 1 from socios.Socio where dni = @dni_menor)
		begin
			DECLARE @edad INT;
			DECLARE @membresia VARCHAR(10);
			-- Calcular edad exacta
			SET @edad = DATEDIFF(YEAR, @fecha_nac_menor, GETDATE());
			-- Ajustar edad si aún no cumplió años este año
			IF (DATEADD(YEAR, @edad, @fecha_nac_menor) > GETDATE())
				SET @edad = @edad - 1;
			-- Asignar categoría según la edad
			SET @membresia = CASE 
				WHEN @edad <= 12 THEN (select id from socios.Membresia where nombre = 'Menor')
				WHEN @edad BETWEEN 13 AND 17 THEN (select id from socios.Membresia where nombre = 'Cadete')
				ELSE (select id from socios.Membresia where nombre = 'Mayor')
			END;

			insert into socios.Socio (nombre, apellido, dni, email, fecha_nac, tel_contacto, obra_social, num_carnet_obra_social, es_menor, membresia_id) values (@nombre_menor, @apellido_menor, @dni_menor, @email, @fecha_nac_menor, @telefono, @obra_social, @num_carnet_obra_social, 1, @membresia)
			SET @familiar_id = SCOPE_IDENTITY()
			if not exists (select 1 from socios.Socio where dni = @dni)
			begin
				insert into socios.Socio (nombre, apellido, dni, email, fecha_nac, telefono, es_responsable, parentesco, usuario_id) values (@nombre, @apellido, @dni, @email, @fecha_nac, @telefono, 1, @parentesco, @usuario_id)
				SET @familiar_id = SCOPE_IDENTITY()
				update socios.Socio
					set id_responsable = @familiar_id
					where dni = @dni_menor
			end
			else
			begin
				set @familiar_id = (select numero_socio from socios.Socio where dni = @dni)
				update socios.Socio
					set id_responsable = @familiar_id
					where dni = @dni_menor
			end
		end
		else
			RAISERROR('El DNI del menor ya se encuentra en el sistema.', 16, 1); 
	end
		else
			RAISERROR('Error. El "menor" a asociar ya es mayor de edad.', 16, 1); 

end

--SP para asociar Responsable por DNI
go
create or alter procedure sp.AsociarResponsable (@dni int)
as
begin
	IF EXISTS (SELECT 1 FROM socios.Socio WHERE dni = @dni and es_responsable = 1 and responsable_y_socio = 0)
	begin
	update socios.Socio
		set responsable_y_socio = 1, membresia_id = (select id from socios.Membresia where nombre = 'Mayor')
		where dni = @dni
	print 'DNI correspondiente a responsable no socio. Fue asociado correctamente.'
	end
	else
		RAISERROR('El DNI no existe en el sistema o ya pertenece a un socio ya existente.', 16, 1);
end

--SP para desasociar Responsable por DNI
go
create or alter procedure sp.DesasociarResponsable (@dni int)
as
begin
	IF EXISTS (SELECT 1 FROM socios.Socio WHERE dni = @dni and es_responsable = 1 and responsable_y_socio = 1)
	begin
	update socios.Socio
		set responsable_y_socio = 0
		where dni = @dni
	print 'DNI correspondiente a responsable socio. Fue desasociado correctamente.'
	end
	else
		RAISERROR('El DNI no existe en el sistema o ya pertenece a un no socio ya existente.', 16, 1);
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

--SP para actualizar contrasenia de usuario a partir del DNI (nombre_usuario)
go
create or alter procedure sp.ActualizarContraseniaUsuario (@dni int, @nueva_contra varchar(20))
as
begin
	if exists (select 1 from socios.Usuario where nombre_usuario = @dni)
	begin
		update socios.Usuario
			set contrasenia = @nueva_contra, fecha_vigencia_contra = DATEADD(YEAR, 1, GETDATE())
			where nombre_usuario = @dni
			print 'Contrasenia actualizada correctamente.'
	end
	else
		RAISERROR('El DNI especificado no esta asociado a ningun usuario.', 16, 1);
end

--SP para eliminar usuarios a partir del DNI (nombre_usuario)
go
create or alter procedure sp.EliminarUsuario (@dni int)
as
begin
	if exists (select 1 from socios.Usuario where nombre_usuario = @dni)
	begin
		IF exists (select 1 from socios.Socio where dni = @dni and activo = 0)
		begin
			update socios.Socio
				set usuario_id = NULL
				where dni = @dni
			delete from socios.Usuario where nombre_usuario = @dni
			print 'Usuario eliminado correctamente.'
		end
		else
			RAISERROR('El DNI especificado esta asociado a un socio Activo.', 16, 1);
	end
	else
		RAISERROR('El DNI especificado no esta asociado a ningun usuario.', 16, 1);
end