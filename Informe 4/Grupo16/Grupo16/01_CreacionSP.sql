/*
Enunciado Informe 4:
Luego de decidirse por un motor de base de datos relacional, llegó el momento de generar la
base de datos. En esta oportunidad utilizarán SQL Server.
Deberá instalar el DMBS y documentar el proceso. No incluya capturas de pantalla. Detalle
las configuraciones aplicadas (ubicación de archivos, memoria asignada, seguridad, puertos,
etc.) en un documento como el que le entregaría al DBA.
Cree la base de datos, entidades y relaciones. Incluya restricciones y claves. Deberá entregar
un archivo .sql con el script completo de creación (debe funcionar si se lo ejecuta “tal cual” es
entregado en una sola ejecución). Incluya comentarios para indicar qué hace cada módulo
de código.
Genere store procedures para manejar la inserción, modificado, borrado (si corresponde,
también debe decidir si determinadas entidades solo admitirán borrado lógico) de cada tabla.
Los nombres de los store procedures NO deben comenzar con “SP”.
Algunas operaciones implicarán store procedures que involucran varias tablas, uso de
transacciones, etc. Puede que incluso realicen ciertas operaciones mediante varios SPs.
Asegúrense de que los comentarios que acompañen al código lo expliquen.
Genere esquemas para organizar de forma lógica los componentes del sistema y aplique esto
en la creación de objetos. NO use el esquema “dbo”.
Todos los SP creados deben estar acompañados de juegos de prueba. Se espera que
realicen validaciones básicas en los SP (p/e cantidad mayor a cero, CUIT válido, etc.) y que
en los juegos de prueba demuestren la correcta aplicación de las validaciones.
Las pruebas deben realizarse en un script separado, donde con comentarios se indique en
cada caso el resultado esperado
El archivo .sql con el script debe incluir comentarios donde consten este enunciado, la fecha
de entrega, número de grupo, nombre de la materia, nombres y DNI de los alumnos.
Entregar todo en un zip (observar las pautas para nomenclatura antes expuestas) mediante
la sección de prácticas de MIEL. Solo uno de los miembros del grupo debe hacer la entrega.

Fecha de entrega: 23/05/2025
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

--SP para crear profesor
go
create or alter procedure sp.CrearProfesor (@nombre varchar(50))
as
begin
	insert into eventos.Profesor (nombre) values (@nombre)
end

--SP para eliminar profesor por ID
go
create or alter procedure sp.EliminarProfesor (@id int)
as
begin
	if exists (select 1 from eventos.Profesor where id = @id)
		delete from eventos.Profesor where id = @id
	else
		RAISERROR('El ID no existe.', 16, 1);
end


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
	if @edad < 18
	begin
		RAISERROR('El DNI pertenece a un menor.', 16, 1);
		return
	end
	SET @categoria = CASE 
		WHEN @edad <= 12 THEN (select id from socios.Membresia where nombre = 'Menor')
		WHEN @edad BETWEEN 13 AND 17 THEN (select id from socios.Membresia where nombre = 'Cadete')
		ELSE (select id from socios.Membresia where nombre = 'Mayor')
	END;

	declare @membresia_id int
	set @membresia_id = (select m.id from socios.Membresia m
						where m.id like @edad)

	
	exec sp.CrearUsuarioNuevo @dni, 'Socio', @id_usuario = @usuario_id output

	insert into socios.Socio (nombre, apellido, dni, email, fecha_nac, telefono, tel_contacto, obra_social, num_carnet_obra_social, membresia_id, usuario_id)
	values (@nombre, @apellido, @dni, @email, @fecha_nac, @telefono, @tel_contacto, @obra_social,
	@num_carnet_obra_social, @categoria, @usuario_id)

	if exists (select 1 from eventos.Invitado where dni = @dni)
	begin
		delete from eventos.Invitado where dni = @dni
	end
	PRINT 'Socio agregado correctamente.';
	end
	else
		RAISERROR('El DNI pertenece a un socio ya existente.', 16, 1);

end



--SP para crear nuevo usuario a socio existente
go
create or alter procedure sp.CrearUsuarioSocio (@dni int, @rol varchar(20))
as
begin
	if (@rol not in('Socio', 'Administrador'))
	begin
		RAISERROR('Rol invalido.', 16, 1);
		return
	end
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
			RAISERROR('El DNI pertenece a un socio con usuario.', 16, 1);
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
		exec sp.CrearUsuarioNuevo @dni, 'Socio', @id_usuario = @usuario_id output
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
				--envio el id del responsable a la columna id_responsable del menor (para saber de quien depende)
				set @familiar_id = (select numero_socio from socios.Socio where dni = @dni)
				update socios.Socio
					set id_responsable = @familiar_id
					where dni = @dni_menor
				
				--si ya preexistia y no era responsable, quiere decir que era socio, entonces ahora es responsbale y socio
				if ((select es_responsable from socios.Socio where dni = @dni) = 0)
				begin
					update socios.Socio
					set responsable_y_socio = 1
					where dni = @dni
				end

				--actualizo en caso de preexistir como no responsable
				update socios.Socio
				set es_responsable = 1
				where dni = @dni
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
		IF EXISTS (SELECT 1 FROM socios.Socio WHERE dni = @dni and activo=1)
		begin
			declare @id_socio int
			set @id_socio = (select numero_socio from socios.Socio where dni = @dni)
			
			delete from eventos.SocioActividad
			where id_socio = @id_socio

			delete from socios.Socio
			where dni = @dni

			delete from socios.Usuario
			where nombre_usuario = @dni	
					
			print 'Socio eliminado correctamente.'
		end
		else
			RAISERROR('El DNI especificado no existe en el sistema o pertenece a un socio activo.', 16, 1);
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
	IF NOT EXISTS (SELECT 1 FROM socios.Membresia WHERE nombre = @nombre) --verificamos que no exista ya una membresia con ese nombre
	begin
		insert into socios.Membresia values (@nombre, @precio)
		PRINT 'Membresia insertada correctamente.';
	end
	else
		RAISERROR('La membresia especificada ya existe.', 16, 1);
end

--SP para modificar los valores de las membresias
go
create or alter procedure sp.ModificarValorMembresia (@id int, @nuevo_precio float)
as
begin
	if @nuevo_precio < 1 
	begin
		RAISERROR('El valor indicado es invalido.', 16, 1);
		return
	end
	IF EXISTS (SELECT 1 FROM socios.Membresia WHERE id = @id) --verificamos que exista la membresia a modificar
    BEGIN
        UPDATE socios.Membresia
        SET costo = @nuevo_precio
        WHERE id = @id;

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
create or alter procedure sp.ModificarValorActividad (@id int, @nuevo_precio float)
as
begin
	if @nuevo_precio < 1 
	begin
		RAISERROR('El valor indicado es invalido.', 16, 1);
		return
	end
	IF EXISTS (SELECT 1 FROM eventos.Actividad WHERE id = @id)
    BEGIN
        UPDATE eventos.Actividad
        SET costo = @nuevo_precio
        WHERE id = @id;

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
	if len(@nueva_contra) < 8
	begin
		RAISERROR('La contraseña ingresada es invalida.', 16, 1);
		return
	end
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

--SP para anotar socio a actividad
go
create or alter procedure sp.InscribirSocioActividad (@dni int, @id_activ int)
as
begin
	if exists (select 1 from eventos.Actividad where id = @id_activ)
	begin
		if exists (select 1 from socios.Socio where dni = @dni and activo = 1)
		begin
			DECLARE @es_responsable BIT
			DECLARE @responsable_y_socio BIT
			declare @id_socio int

			SELECT 
				@es_responsable = es_responsable,
				@responsable_y_socio = responsable_y_socio,
				@id_socio = numero_socio
			FROM socios.Socio
			WHERE dni = @dni;

			if @es_responsable = 0 or (@es_responsable = 1 and @responsable_y_socio = 1)
			begin
				insert into eventos.SocioActividad values (@id_socio, @id_activ)
			end
			else
				RAISERROR('El DNI especificado pertenece a un responsbable no socio.', 16, 1);		

		end
		else
			RAISERROR('El DNI especificado no pertenece a un socio activo del club.', 16, 1);
	end
	ELSE
		RAISERROR('La actividad especificada no existe.', 16, 1);
end

--sp para eliminar un socio de una actividad por dni
go
create or alter procedure sp.EliminarSocioActividad (@dni int, @id_activ int)
as
begin
	declare @id_socio int
	select @id_socio = numero_socio from socios.Socio where dni = @dni
	if exists (select 1 from eventos.Actividad where id = @id_activ) and exists (select 1 from socios.Socio where dni = @dni)
	begin
		if exists (select 1 from eventos.SocioActividad where id_socio = @id_socio)
		begin
			if exists (select 1 from eventos.SocioActividad where id_socio = @id_socio and id_actividad = @id_activ)
			begin
				delete from eventos.SocioActividad where id_socio = @id_socio and id_actividad = @id_activ
			end
			else
				RAISERROR('El DNI especificado no realiza la actividad especificada.', 16, 1);
		end
		else
			RAISERROR('El DNI especificado no esta asociado a ninguna actividad.', 16, 1);
		end
	else
		RAISERROR('El DNI especificado o la actividad especificada no existe.', 16, 1);
end

--sp para generar una factura a partir de un cuota id
go
create or alter procedure sp.GenerarFacturaCuota (@id_cuota int, @descAct bit, @descMemb bit, @acumAct float, @acumMem float)
as
begin
	if not exists (select 1 from finanzas.Cuota where id = @id_cuota)
	begin
		RAISERROR('El ID especificado no corresponde a ninguna cuota existente.', 16, 1);
		return
	end
	if exists (select 1 from finanzas.Factura where id_cuota = @id_cuota)
	begin
		RAISERROR('El ID especificado ya tiene una factura generada.', 16, 1);
		return
	end

	declare @id_socio int
	declare @valor float
	declare @fecha_venc date
	declare @detalleAct varchar(80)
	declare @detalleMem varchar(80)
	declare @detalle varchar(160)
	declare @desc float

	SELECT 
			@id_socio = id_socio,
			@valor = valor
		FROM finanzas.Cuota
		WHERE id = @id_cuota
	
	set @detalleAct = 'Valor actividades: ' + cast(@acumAct as varchar) + CHAR(13) + CHAR(10)
	if(@descAct=1)
	begin
		set @desc = ((@acumAct*100)/90) - @acumAct
		set @detalleAct = @detalleAct + '(Descuento Actividades: ' + cast(@desc as varchar) +')' + CHAR(13) + CHAR(10)
	end

	set @detalleMem = 'Valor Membresia: ' + cast(@acumMem as varchar)  + CHAR(13) + CHAR(10)
	if(@descMemb=1)
	begin
		set @desc = ((@acumMem*100)/85) - @acumMem
		set @detalleMem= @detalleMem + '(Descuento Membresia: ' + cast(@desc as varchar) + ')'
	end
	set @detalle = @detalleAct + @detalleMem

	set @fecha_venc = DATEADD(DAY, 5, GETDATE());

	insert into finanzas.Factura (id_cuota, id_socio, valor, fecha_emision, fecha_vencimiento, estado, origen, detalle) values (@id_cuota, @id_socio, @valor, GETDATE(), @fecha_venc, 'Pendiente', 'Cuota', @detalle)
	print 'Factura generada correctamente'
end

--sp para crear cuota socio a partir de las actividades	
go
create or alter procedure sp.GenerarCuotaSocio (@dni int, @periodo varchar(10))
as
begin
	SET NOCOUNT ON;
	if exists (select 1 from socios.Socio where dni = @dni and activo = 1)
	begin
		DECLARE @es_responsable BIT
		DECLARE @responsable_y_socio BIT
		declare @id_socio int
		declare @id_fami int
		declare @id_mem int

		SELECT 
			@es_responsable = es_responsable,
			@responsable_y_socio = responsable_y_socio,
			@id_socio = numero_socio,
			@id_fami = id_responsable,
			@id_mem =membresia_id
		FROM socios.Socio
		WHERE dni = @dni;
		
		if ((@es_responsable = 0 and @id_fami is null) or (@es_responsable = 1 and @responsable_y_socio = 1))
		begin
			declare @fecha date
			--declare @periodo varchar(10)
			declare @acum_act float
			declare @acum_mem float
			declare @acum float
			declare @id_cuota int
			declare @tieneDescActividad bit
			declare @tieneDescMembresia bit
			set @tieneDescActividad = 0
			set @tieneDescMembresia = 0
			
			set @fecha = GETDATE()
			--set @periodo = FORMAT(GETDATE(), 'MM-yyyy')
			if exists (select 1 from finanzas.Cuota where id_socio = @id_socio and ((@id_fami is null and id_responsable is null) or id_responsable = @id_fami) and periodo = @periodo)	
			begin	
				print 'Ya existe una cuota generada para ese socio en el periodo actual.'	
				return
			end
			if exists (select 1 from eventos.SocioActividad where id_socio = @id_socio)
			begin
				set @acum_act = (
							select sum(a.costo)
							from eventos.SocioActividad sa
							join eventos.Actividad a on a.id = sa.id_actividad
							where sa.id_socio = @id_socio
						)
				if ((select count(*) from eventos.SocioActividad where id_socio = @id_socio) > 1)
				begin	
					set @acum_act *= 0.90
					set @tieneDescActividad = 1
				end
			end
			else
			begin
				set @acum_act =  0
			end

			set @acum_mem = (select m.costo from socios.Membresia m where id = @id_mem)
			if ((@id_fami is not null) or (@responsable_y_socio=1))
			begin	
				set @acum_mem  *= 0.85
				set @tieneDescMembresia = 1
			end

			set @acum = @acum_act + @acum_mem

			insert into finanzas.Cuota (id_socio, id_responsable, valor, fecha, periodo, estado) values (@id_socio, NULL, @acum, @fecha, @periodo, 'Pendiente')
			set @id_cuota = SCOPE_IDENTITY()
			exec sp.GenerarFacturaCuota @id_cuota, @tieneDescActividad, @tieneDescMembresia, @acum_act, @acum_mem
			print 'Cuota generada correctamente.'
		end
		else if (@es_responsable = 0 and @id_fami is not null)
		begin
			declare @fecha2 date
			--declare @periodo2 varchar(10)
			declare @acum_act2 float
			declare @acum_mem2 float
			declare @acum2 float

			set @fecha2 = GETDATE()
			--set @periodo2 = FORMAT(GETDATE(), 'MM-yyyy')
			if exists (select 1 from finanzas.Cuota where id_socio = @id_socio and ((@id_fami is null and id_responsable is null) or id_responsable = @id_fami) and periodo = @periodo)	
			begin	
				print 'Ya existe una cuota generada para ese socio en el periodo actual.'	
				return
			end
			if exists (select 1 from eventos.SocioActividad where id_socio = @id_socio)
			begin
				set @acum_act2 = (
							select sum(a.costo)
							from eventos.SocioActividad sa
							join eventos.Actividad a on a.id = sa.id_actividad
							where sa.id_socio = @id_socio
						)
				if ((select count(*) from eventos.SocioActividad where id_socio = @id_socio) > 1)
				begin	
					set @acum_act2 *= 0.90
					set @tieneDescActividad = 1
				end
			end
			else
			begin
				set @acum_act2 =  0
			end

			set @acum_mem2 = (select m.costo from socios.Membresia m where id = @id_mem)
			set @acum_mem2  *= 0.85
			set @tieneDescMembresia = 1
			set @acum2 = @acum_act2 + @acum_mem2
			

			insert into finanzas.Cuota values (@id_socio, @id_fami, @acum2, @fecha2, @periodo, 'Pendiente')		
			
			set @id_cuota = SCOPE_IDENTITY()
			exec sp.GenerarFacturaCuota @id_cuota, @tieneDescActividad, @tieneDescMembresia, @acum_act2, @acum_mem2
			print 'Cuota generada correctamente.'
		end
		else
			RAISERROR('El DNI especificado pertenece a un responsbable no socio.', 16, 1);		

		end
		else
			RAISERROR('El DNI especificado no pertenece a un socio activo.', 16, 1);
end


--sp para eliminar cuota con id cuota
go
create or alter procedure sp.EliminarCuota (@id_cuota int)
as
begin
	if exists (select 1 from finanzas.Cuota where id = @id_cuota)
	begin
		delete from finanzas.Factura where id_cuota = @id_cuota
		delete from finanzas.Cuota where id = @id_cuota
	end
	else
		RAISERROR('El ID especificado no corresponde a una cuota.', 16, 1);
end


--SP para crear invitados
go
create or alter procedure sp.CrearInvitado (@nombre varchar(50), @apellido varchar(50), @dni int, @telefono varchar(20))
as
begin
	if exists (select 1 from eventos.Invitado where dni = @dni) --verifica que no exista el dni registrado
	begin
		RAISERROR('El DNI especificado corresponde a un invitado ya registrado.', 16, 1);
		return
	end
	if not exists (select 1 from socios.Socio where dni = @dni and activo = 1)
	begin
		insert into eventos.Invitado (nombre, apellido, dni, telefono) values(@nombre, @apellido, @dni, @telefono)
		print 'Invitado agregado correctamente.'
	end
	else
		RAISERROR('El DNI especificado corresponde a un socio activo.', 16, 1);
end


--SP para eliminar invitados
go
create or alter procedure sp.EliminarInvitado (@dni int)
as
begin
	if exists (select 1 from eventos.Invitado where dni = @dni)
	begin
		delete from eventos.Invitado where dni = @dni
		print 'Invitado eliminado correctamente.'
	end
	else
		RAISERROR('El DNI especificado no corresponde a un invitado existente.', 16, 1);
end


--SP para crear metodos de pago
go
create or alter procedure sp.CrearMetodoPago (@nombre varchar(25))
as
begin
	if not exists (select 1 from finanzas.MetodoPago where nombre = @nombre)
	begin
		insert into finanzas.MetodoPago values (@nombre)
		print 'Metodo de pago agregado correctamente.'
	end
	else
		RAISERROR('El metodo de pago ya existe.', 16, 1);
end



--SP para eliminar metodos de pago por id
go
create or alter procedure sp.EliminarMetodoPago (@id int)
as
begin
	if exists (select 1 from finanzas.MetodoPago where id = @id)
	begin
		delete from finanzas.MetodoPago where id = @id
		print 'Metodo de pago eliminado correctamente.'
	end
	else
		RAISERROR('El metodo de pago no existe.', 16, 1);
end

--SP para modificar nombre metodos de pago por id
go
create or alter procedure sp.ModificarMetodoPago (@id int, @nuevo_nombre varchar(25))
as
begin
	if @nuevo_nombre = ''
	begin
		RAISERROR('Nuevo nombre invalido.', 16, 1);
		return
	end
	if exists (select 1 from finanzas.MetodoPago where id = @id)
	begin
		update finanzas.MetodoPago
			set nombre = @nuevo_nombre
			where id = @id
			print 'Metodo de pago actualizado correctamente.'
	end
	else
		RAISERROR('El metodo de pago no existe.', 16, 1);
end


--sp para generar factura por reserva
go
create or alter procedure sp.GenerarFacturaReserva (@id_socio int, @id_invitado int, @fecha date, @valor float, @valor_inv float, @id_reserva int, @llovio bit)
as
begin
	declare @fecha_venc date
	declare @detalle varchar(160)
	declare @desc float
	SET @fecha_venc = DATEADD(DAY, 5, GETDATE());
	set @detalle = 'Valor Reserva: ' + cast(@valor as varchar)
	if(@llovio = 1)
	begin
		set @desc = ((@valor*60)/100)
		set @detalle = @detalle + CHAR(13) + CHAR(10) + '(Reeintegro por lluvia: ' + cast(@desc as varchar) + ')'
	end

	insert into finanzas.Factura (id_socio, id_reserva, valor, fecha_emision, fecha_vencimiento, estado, origen, detalle) values (@id_socio, @id_reserva, @valor,GETDATE(), @fecha_venc, 'Pendiente', 'Reserva', @detalle)

	if @id_invitado is not null
	begin
			set @detalle = 'Valor Reserva (invitado): ' + cast(@valor_inv as varchar)
			if(@llovio = 1)
			begin
				set @desc = ((@valor_inv*60)/100)
				set @detalle = @detalle + CHAR(13) + CHAR(10) + '(Reeintegro por lluvia: ' + cast(@desc as varchar) + ')'
			end
			insert into finanzas.Factura (id_invitado, id_reserva, valor, fecha_emision, fecha_vencimiento, estado, origen, detalle) values (@id_invitado, @id_reserva, @valor_inv,GETDATE(), @fecha_venc, 'Pendiente', 'Reserva', @detalle)
	end
end

--SP para generar Reserva a partir dni socio, dni invitado(op), id act, fecha
go
create or alter procedure sp.CrearReserva (@dni_socio int, @dni_invitado int, @id_act int, @fecha date)
as
begin
	if not exists (select 1 from socios.Socio where dni = @dni_socio and activo=1 and responsable_y_socio = 0)
	begin
		RAISERROR('El DNI no pertenece a un socio activo.', 16, 1);
		return
	end
	if @dni_invitado is not null and not exists (select 1 from eventos.Invitado where dni = @dni_invitado)
	begin
		RAISERROR('El DNI no pertenece a un invitado existente.', 16, 1);
		return
	end
	if not exists (select 1 from eventos.Actividad where id = @id_act)
	begin
		RAISERROR('La actividad especificada no existe.', 16, 1);
		return
	end
	if (@dni_invitado is not null and ((select a.nombre from eventos.Actividad a where id = @id_act) <> 'Pileta'))
	begin
		RAISERROR('El invitado no puede acceder a otra actividad distina de la Pileta.', 16, 1);
		return
	end

	declare @valor float
	declare @valor_inv float
	declare @llovio bit

	IF EXISTS (
    SELECT 1
    FROM eventos.Clima
    WHERE lluvia_mm > 0
      AND CAST(fecha_hora AS DATE) = @fecha
) 
	set @llovio=1
	else
		set @llovio=0
		
	set @valor = (select a.costo from eventos.Actividad a where id = @id_act)
	set @valor_inv = (select a.costo from eventos.Actividad a where nombre = 'Pileta Invitado')

	declare @id_socio int
	set @id_socio = (select numero_socio from socios.Socio where dni = @dni_socio)

	if @dni_socio is not null
	begin
		declare @id_invitado int
		set @id_invitado = (select id from eventos.Invitado where dni = @dni_invitado)
	end
	else
		set @id_invitado = @dni_socio
	
	declare @id_reserva int
	print @id_socio 
	print @id_invitado
	print @id_act
	insert into eventos.Reserva (id_socio, id_invitado, id_actividad, fecha, lluvia) values (@id_socio, @id_invitado, @id_act, @fecha, @llovio)
	set @id_reserva = SCOPE_IDENTITY()
	exec sp.GenerarFacturaReserva @id_socio, @id_invitado, @fecha, @valor, @valor_inv, @id_reserva, @llovio
	
	
	if @llovio = 1
	begin
		update socios.Socio
		set saldo_a_favor = saldo_a_favor + (0.6 * @valor)
		where dni = @dni_socio

		if @dni_invitado is not null
		begin
			update eventos.Invitado
			set saldo_a_favor = saldo_a_favor + (0.6 * @valor_inv)
			where dni = @dni_invitado
		end
	end
end


--SP para eliminar una reserva por id
go
create or alter procedure sp.EliminarReserva (@id_reserva int)
as
begin
	if not exists (select 1 from eventos.Reserva where id = @id_reserva)
	begin
		RAISERROR('El ID especificado no corresponde a ninguna reserva existente.', 16, 1);
		return
	end
	delete from finanzas.Factura where id_reserva = @id_reserva
	delete from eventos.Reserva where id = @id_reserva
	print'Reserva eliminada correctamente.'
end


--sp para eliminar facturas por id
go
create or alter procedure sp.EliminarFactura (@id int)
as
begin
	if exists (select 1 from finanzas.Factura where numero_factura = @id)
	begin
		delete from finanzas.Factura where numero_factura = @id
		print 'Facturada eliminada correctamente'
	end
	else
		RAISERROR('El ID especificado no corresponde a ninguna factura existente.', 16, 1);
end





--sp para registrar pagos de cuotas por dni, id de factura, id met pago
go
create or alter procedure sp.GenerarPagoFacturaCuota (@dni int, @id_fact int, @id_metpag int)
as
begin
	if not exists (select 1 from socios.Socio where dni = @dni and activo=1)
	begin
		RAISERROR('El DNI especificado no corresponde a un socio activo.', 16, 1);
		return
	end
	if not exists (select 1 from finanzas.Factura where numero_factura = @id_fact)
	begin
		RAISERROR('La factura especificada no existe.', 16, 1);
		return
	end
	if not exists (select 1 from finanzas.MetodoPago where id = @id_metpag)
	begin
		RAISERROR('El metodo de pago especificado no existe.', 16, 1);
		return
	end
	if exists (select 1 from finanzas.Factura where numero_factura = @id_fact and estado = 'Pagada')
	begin
		RAISERROR('La factura especificada ya se encuentra paga.', 16, 1);
		return
	end

	declare @id_socio int
	declare @valor float
	declare @id_cuota int
	set @id_socio = (select id_socio from finanzas.Factura where numero_factura = @id_fact)

	set @valor = (select f.valor from finanzas.Factura f where numero_factura = @id_fact)

	set @id_cuota = (select f.id_cuota from finanzas.Factura f where numero_factura = @id_fact)

	insert into finanzas.Pago (id_factura, id_socio, id_cuota, id_metodo_pago, fecha, valor) values (@id_fact, @id_socio, @id_cuota, @id_metpag, GETDATE(), @valor)
	print 'Pago generado correctamente.'

	update finanzas.Cuota
	set estado = 'Pagada'
	where id = @id_cuota

	update finanzas.Factura
	set estado = 'Pagada'
	where numero_factura = @id_fact
	--validar que no cualq pague cualq fact
end


--sp para registrar pagos de reservas por dni, id de factura, id met pago
go
create or alter procedure sp.GenerarPagoFacturaReservaSocio (@dni int, @id_fact int, @id_metpag int)
as
begin
	if  exists (select 1 from finanzas.Factura where numero_factura = @id_fact and id_reserva is null)
	begin
		RAISERROR('La factura especificada no corresponde a una reserva.', 16, 1);
		return
	end
	if not exists (select 1 from socios.Socio where dni = @dni and activo=1)
	begin
		RAISERROR('El DNI especificado no corresponde a un socio activo.', 16, 1);
		return
	end
	if not exists (select 1 from finanzas.Factura where numero_factura = @id_fact)
	begin
		RAISERROR('La factura especificada no existe.', 16, 1);
		return
	end
	if not exists (select 1 from finanzas.MetodoPago where id = @id_metpag)
	begin
		RAISERROR('El metodo de pago especificado no existe.', 16, 1);
		return
	end
	if exists (select 1 from finanzas.Factura where numero_factura = @id_fact and estado = 'Pagada')
	begin
		RAISERROR('La factura especificada ya se encuentra paga.', 16, 1);
		return
	end

	declare @id_socio int
	declare @valor float

	set @id_socio = (select id_socio from finanzas.Factura where numero_factura = @id_fact)
	set @valor = (select f.valor from finanzas.Factura f where numero_factura = @id_fact)

	insert into finanzas.Pago (id_factura, id_socio, id_metodo_pago, fecha, valor) values (@id_fact, @id_socio, @id_metpag, GETDATE(), @valor)
	print 'Pago generado correctamente.'

	update finanzas.Factura
	set estado = 'Pagada'
	where numero_factura = @id_fact

end

--sp para registrar pagos de reservas de invitados por dni, id de factura, id met pago
go
create or alter procedure sp.GenerarPagoFacturaReservaInvitado (@dni int, @id_fact int, @id_metpag int)
as
begin
	if not exists (select 1 from eventos.Invitado where dni = @dni)
	begin
		RAISERROR('El DNI especificado no corresponde a un invitado existente.', 16, 1);
		return
	end
	if not exists (select 1 from finanzas.Factura where numero_factura = @id_fact)
	begin
		RAISERROR('La factura especificada no existe.', 16, 1);
		return
	end
	if not exists (select 1 from finanzas.MetodoPago where id = @id_metpag)
	begin
		RAISERROR('El metodo de pago especificado no existe.', 16, 1);
		return
	end
	if exists (select 1 from finanzas.Factura where numero_factura = @id_fact and estado = 'Pagada')
	begin
		RAISERROR('La factura especificada ya se encuentra paga.', 16, 1);
		return
	end

	declare @id_socio int
	declare @valor float

	set @id_socio = (select id_invitado from finanzas.Factura where numero_factura = @id_fact)
	set @valor = (select f.valor from finanzas.Factura f where numero_factura = @id_fact)

	insert into finanzas.Pago (id_factura, id_invitado, id_metodo_pago, fecha, valor) values (@id_fact, @id_socio, @id_metpag, GETDATE(), @valor)
	print 'Pago generado correctamente.'

	update finanzas.Factura
	set estado = 'Pagada'
	where numero_factura = @id_fact

end


--sp generar reembolso por id pago
go
create or alter procedure sp.ReembolsoPago (@id_pago int)
as
begin
	if not exists (select 1 from finanzas.Pago where id = @id_pago)
	begin
		RAISERROR('El pago indicado no existe.', 16, 1);
		return
	end
	if  exists (select 1 from finanzas.Pago where id = @id_pago and es_reembolso = 1)
	begin
		RAISERROR('El pago indicado ya fue reembolsado.', 16, 1);
		return
	end

	update finanzas.Pago
	set es_reembolso = 1
	where id = @id_pago
	/*declare @id_socio int
	declare @id_factura int
	declare @id_metpago int
	declare @valor float

	set @valor = (select p.valor from finanzas.Pago p where id = @id_pago)
	set @id_metpago = (select p.id_metodo_pago from finanzas.Pago p where id = @id_pago)
	set @id_factura = (select p.id_factura from finanzas.Pago p where id = @id_pago)

	if((select p.id_socio from finanzas.Pago p where id = @id_pago) is not null)
	begin
		/*set @id_socio = (select p.id_socio from finanzas.Pago p where id = @id_pago)
		insert into finanzas.Pago (id_factura, id_socio, id_metodo_pago, fecha, valor, es_reembolso) values (@id_factura, @id_socio, @id_metpago, getdate(), @valor, 1)*/

	end
	else
	begin
		set @id_socio = (select p.id_invitado from finanzas.Pago p where id = @id_pago)
		insert into finanzas.Pago (id_factura, id_invitado, id_metodo_pago, fecha, valor, es_reembolso) values (@id_factura, @id_socio, @id_metpago, getdate(), @valor, 1)
	end*/
	print'Pago reembolsado correctamente'

end

--sp generar pago a cuentas por id pago
go
create or alter procedure sp.PagoACuentasPago (@id_pago int)
as
begin
	if not exists (select 1 from finanzas.Pago where id = @id_pago)
	begin
		RAISERROR('El pago indicado no existe.', 16, 1);
		return
	end
	if  exists (select 1 from finanzas.Pago where id = @id_pago and es_reembolso = 1)
	begin
		RAISERROR('El pago indicado ya fue reembolsado.', 16, 1);
		return
	end

	declare @id_socio int
	declare @valor float

	set @valor = (select p.valor from finanzas.Pago p where id = @id_pago)
	if((select p.id_socio from finanzas.Pago p where id = @id_pago) is not null)
	begin
		set @id_socio = (select p.id_socio from finanzas.Pago p where id = @id_pago)
		update socios.Socio
		set saldo_a_favor += @valor
		where numero_socio = @id_socio
	end
	else
	begin
		set @id_socio = (select p.id_invitado from finanzas.Pago p where id = @id_pago)
		update eventos.Invitado
		set saldo_a_favor += @valor
		where id = @id_socio
	end
	update finanzas.Pago
	set es_reembolso = 1
	where id = @id_pago
	print'Pago a cuentas realizado correctamente.'

end


--sp para actualizar todas las facturas en caso de vencimiento
go
create or alter procedure sp.ActualizarFacturas
as
begin
	update finanzas.Factura
	set valor *= 1.1, estado='Vencida'
	WHERE DATEADD(DAY, 10, fecha_vencimiento) > DATEADD(DAY, 5, fecha_vencimiento)
	AND estado = 'Pendiente'; 

	print'Facturas actualizadas correctamente'
end


--sp para desactivar socios morosos
go
create or alter procedure sp.DesactivarSociosMorosos
as
begin
	update socios.Socio
	set activo = 0
	WHERE EXISTS (
    SELECT 1
    FROM finanzas.Factura f
    WHERE f.id_socio = numero_socio
      AND f.estado = 'Vencida'
	);
end


--SP para importar OpenMeteo 2024
go
create or alter procedure sp.ImportarMeteo24
as
begin	
	IF OBJECT_ID('tempdb..#climaTemp') IS NOT NULL
    DROP TABLE #climaTemp;

	--creo una tabla temporal
	create table #climaTemp (
	fecha_hora varchar(30),
	temperatura NVARCHAR(50),
	lluvia_mm NVARCHAR(50),
	humedad NVARCHAR(50),
	viento_kmh NVARCHAR(50)
	);--drop table #climaTemp

	-- Importo el archivo CSV, omitiendo las 4 primeras filas
	BULK INSERT #climaTemp
	--FROM 'C:\Users\I759578\Documents\Importar\open-meteo-buenosaires_2024.csv'
	FROM 'C:\Users\I759578\Documents\TPI-2025-1C\open-meteo-buenosaires_2024.csv'
	WITH (
		FIRSTROW = 4,                  -- Salta las 4 primeras filas (no cuenta la vacia)
		FIELDTERMINATOR = ',',
		ROWTERMINATOR = '\n',
		CODEPAGE = '65001',
		MAXERRORS = 1000
	);

	--casteo la columna viento, sacando los ';'
	UPDATE #climaTemp
	SET viento_kmh = 
		CASE 
			WHEN CHARINDEX(';', viento_kmh) > 0 
			THEN LEFT(viento_kmh, CHARINDEX(';', viento_kmh) - 1)
			ELSE viento_kmh
		END;

	--casteo el datetime agregando segundos (00) para que sea compatible el formato
	UPDATE #climaTemp
	SET fecha_hora = fecha_hora + ':00'
	WHERE fecha_hora IS NOT NULL AND LEN(fecha_hora) = 16;

	-- Castear y guardar en temp con tipos correctos
	SELECT
		TRY_CAST(fecha_hora AS DATETIME2) AS fecha_hora,
		TRY_CAST(temperatura AS FLOAT) AS temperatura,
		TRY_CAST(lluvia_mm AS FLOAT) AS lluvia_mm,
		TRY_CAST(humedad AS INT) AS humedad,
		TRY_CAST(viento_kmh AS FLOAT) AS viento_kmh
	INTO #climaCasteado
	FROM #climaTemp;

	-- Insertar desde tabla con datos casteados y filtrados
	INSERT INTO eventos.Clima (fecha_hora, temperatura, lluvia_mm, humedad, viento_kmh)
	SELECT c.fecha_hora, c.temperatura, c.lluvia_mm, c.humedad, c.viento_kmh
	FROM #climaCasteado c
	WHERE c.fecha_hora IS NOT NULL
	  AND NOT EXISTS (
		SELECT 1 FROM eventos.Clima cl
		WHERE cl.fecha_hora = c.fecha_hora
	  );

	print 'Importado correctamente.'
end

--SP para importar OpenMeteo 2025
go
create or alter procedure sp.ImportarMeteo25
as
begin
	IF OBJECT_ID('tempdb..#climaTemp') IS NOT NULL
    DROP TABLE #climaTemp;
	
	--creo una tabla temporal
	create table #climaTemp (
	fecha_hora varchar(30),
	temperatura NVARCHAR(50),
	lluvia_mm NVARCHAR(50),
	humedad NVARCHAR(50),
	viento_kmh NVARCHAR(50)
	);--drop table #climaTemp

	-- Importo el archivo CSV, omitiendo las 4 primeras filas
	BULK INSERT #climaTemp
	--FROM 'C:\Users\I759578\Documents\Importar\open-meteo-buenosaires_2024.csv'
	FROM 'C:\Users\I759578\Documents\TPI-2025-1C\open-meteo-buenosaires_2025.csv'
	WITH (
		FIRSTROW = 4,                  -- Salta las 4 primeras filas (no cuenta la vacia)
		FIELDTERMINATOR = ',',
		ROWTERMINATOR = '\n',
		CODEPAGE = '65001',
		MAXERRORS = 1000
	);

	--casteo la columna viento, sacando los ';'
	UPDATE #climaTemp
	SET viento_kmh = 
		CASE 
			WHEN CHARINDEX(';', viento_kmh) > 0 
			THEN LEFT(viento_kmh, CHARINDEX(';', viento_kmh) - 1)
			ELSE viento_kmh
		END;

	--casteo el datetime agregando segundos (00) para que sea compatible el formato
	UPDATE #climaTemp
	SET fecha_hora = fecha_hora + ':00'
	WHERE fecha_hora IS NOT NULL AND LEN(fecha_hora) = 16;

	-- Casteo y guardar en temp con tipos correctos
	SELECT
		TRY_CAST(fecha_hora AS DATETIME2) AS fecha_hora,
		TRY_CAST(temperatura AS FLOAT) AS temperatura,
		TRY_CAST(lluvia_mm AS FLOAT) AS lluvia_mm,
		TRY_CAST(humedad AS INT) AS humedad,
		TRY_CAST(viento_kmh AS FLOAT) AS viento_kmh
	INTO #climaCasteado
	FROM #climaTemp;

	-- Insertar desde tabla con datos casteados y filtrados
	INSERT INTO eventos.Clima (fecha_hora, temperatura, lluvia_mm, humedad, viento_kmh)
	SELECT c.fecha_hora, c.temperatura, c.lluvia_mm, c.humedad, c.viento_kmh
	FROM #climaCasteado c
	WHERE c.fecha_hora IS NOT NULL
	  AND NOT EXISTS (
		SELECT 1 FROM eventos.Clima cl
		WHERE cl.fecha_hora = c.fecha_hora
	  );
		
	print 'Importado correctamente.'
end

select * from #climaTemp
select * from eventos.Clima
delete from eventos.Clima
exec sp.ImportarMeteo24
exec sp.ImportarMeteo25

-----------------------------------------------------------------------------
/*para poder usar OPENROWSET activo esto
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
ademas tengo que instalar "https://www.microsoft.com/es-es/download/details.aspx?id=54920"
tengo que ver que ejecutando esto 
EXEC sp_enum_oledb_providers;
aparesca "Microsoft.ACE.OLEDB.12.0" y "Microsoft.ACE.OLEDB.16.0"
y luego para verificar si se me instalo el motor uso:
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.16.0', N'AllowInProcess', 1;
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.16.0', N'DynamicParameters', 1;
esta consulta sirve parar mirar la primera pestaña, cambiar la ruta nomas.
SELECT * 
FROM OPENROWSET('Microsoft.ACE.OLEDB.16.0', 
    'Excel 12.0;Database=C:\Users\zacar\Documents\tpbdda\TPI-2025-1C\Datos socios.xlsx;HDR=YES', 
    'SELECT * FROM [Responsables de pago$]');*/
EXEC socios.sp_importar_responsables_pago
    @ruta_excel = N'C:\Users\zacar\Documents\tpbdda\TPI-2025-1C\Datos socios.xlsx';




--------------------------------------------------------------------------
--Importar resopinsables de pago
        
GO
CREATE OR ALTER PROCEDURE socios.sp_importar_responsables_pago
    @ruta_excel NVARCHAR(260)
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

        -- 1. Eliminar la tabla temporal si existe
        IF OBJECT_ID('tempdb..#ResponsablesTemp') IS NOT NULL
            DROP TABLE #ResponsablesTemp;

        -- 2. Crear tabla temporal con los nombres de columna según el Excel
        CREATE TABLE #ResponsablesTemp (
            numero_socio               VARCHAR(20),
            nombre                     VARCHAR(50),
            apellido                   VARCHAR(50),
            dni                        INT not null,
            email                      VARCHAR(100),
            fecha_nacimiento           DATETIME,
            telefono_contacto          INT,
            telefono_emergencia        INT,
            obra_social                VARCHAR(50),
            numero_socio_obra_social   VARCHAR(20),
            telefono_emergencia_obrasocial VARCHAR(50)
        );

        -- 3. Construcción dinámica de OPENROWSET para importar Excel
        DECLARE @sql NVARCHAR(MAX) = '
            INSERT INTO #ResponsablesTemp
            SELECT *
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.16.0'',
                ''Excel 12.0;HDR=YES;Database=' + @ruta_excel + ''',
                ''SELECT * FROM [Responsables de pago$]''
            );';

        EXEC sp_executesql @sql;
		---------------------------- normalizo los datos
		ALTER TABLE #ResponsablesTemp ALTER COLUMN telefono_contacto VARCHAR(20);
		UPDATE #ResponsablesTemp
		SET telefono_contacto = STUFF(CAST(telefono_contacto AS VARCHAR(10)), 3, 0, '-')
		WHERE telefono_contacto BETWEEN 1000000000 AND 9999999999;
		
		UPDATE #ResponsablesTemp
		SET numero_socio = CAST(
		SUBSTRING(CAST(numero_socio AS VARCHAR(20)), 4, 
		LEN(CAST(numero_socio AS VARCHAR(20)))
		) AS INT)
		WHERE CAST(numero_socio AS VARCHAR(20)) LIKE 'SN-%';
		
		ALTER TABLE #ResponsablesTemp ALTER COLUMN telefono_emergencia VARCHAR(20);
		UPDATE #ResponsablesTemp
		SET telefono_emergencia = STUFF(CAST(telefono_emergencia AS VARCHAR(10)), 3, 0, '-')
		WHERE telefono_emergencia BETWEEN 1000000000 AND 9999999999;
		
		UPDATE #ResponsablesTemp
		SET dni = dni / 10
		WHERE dni >99999999

		IF EXISTS (SELECT 1 FROM #ResponsablesTemp WHERE fecha_nacimiento IS NULL)
		BEGIN
		PRINT 'Se eliminarán las siguientes tuplas debido a fecha_nacimiento NULL:';
	
		SELECT nombre, dni
		FROM #ResponsablesTemp
		WHERE fecha_nacimiento IS NULL;
		DELETE FROM #ResponsablesTemp
		WHERE fecha_nacimiento IS NULL;

		END 

        -- 4. Insertar responsables en socios.Socio verificando duplicados por DNI
		SET IDENTITY_INSERT socios.Socio off;
		;WITH CTE_UniqueResponsables AS (
		SELECT
		nombre,
        apellido,
        dni,
        email,
        fecha_nacimiento,
        telefono_contacto,
        telefono_emergencia,
        obra_social,
        numero_socio_obra_social,
        ROW_NUMBER() OVER (PARTITION BY dni ORDER BY nombre) AS rn
		FROM #ResponsablesTemp
		)
		INSERT INTO socios.Socio (
		nombre,
		apellido,
		dni,
		email,
		fecha_nac,
		telefono,
		tel_contacto,
		obra_social,
		num_carnet_obra_social,
		activo,
		es_menor,
		es_responsable,
		responsable_y_socio
		)
		SELECT
		nombre,
		apellido,
		dni,
		email,
		fecha_nacimiento,
		telefono_contacto,
		telefono_emergencia,
		obra_social,
		numero_socio_obra_social,
		1,       -- activo
		0,       -- es_menor
		1,       -- es_responsable
		1        -- responsable_y_socio
		FROM CTE_UniqueResponsables
		WHERE rn = 1
		AND NOT EXISTS (
        SELECT 1
        FROM socios.Socio s
        WHERE s.dni = CTE_UniqueResponsables.dni
  )
   AND dni BETWEEN 1000000 AND 99999999
  AND email LIKE '_%@_%._%'
  AND LEN(email) <= 100
  AND fecha_nacimiento BETWEEN '1900-01-01' AND GETDATE()
  AND telefono_contacto LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
  AND telefono_emergencia LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'


 

        PRINT 'Importación de responsables finalizada correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error durante la importación: ' + ERROR_MESSAGE();
    END CATCH
END;
GO



----------------------------------------------------------------------------------------------------

drop PROCEDURE socios.sp_importar_responsables_pago
delete from socios.Socio where numero_socio>8
select * from socios.Socio
EXEC socios.sp_importar_responsables_pago
    @ruta_excel = N'C:\Users\zacar\Documents\tpbdda\TPI-2025-1C\Datos socios.xlsx';



------------------------------------------------------------------------------------------------------
ALTER TABLE socios.Socio
ALTER COLUMN email VARCHAR(100) NULL;

-------------------------------------------------------------------------------------------------------------
--sp importar  grupo familiar

CREATE OR ALTER PROCEDURE socios.sp_importar_grupo_familiar
    @ruta_excel NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Tabla temporal
    IF OBJECT_ID('tempdb..#GrupoFamiliarTemp') IS NOT NULL
        DROP TABLE #GrupoFamiliarTemp;

    CREATE TABLE #GrupoFamiliarTemp (
            numero_socio               VARCHAR(20),
		    numero_socio_asociado      VARCHAR(20),
            nombre                     VARCHAR(50),
            apellido                   VARCHAR(50),
            dni                        INT not null,
            email                      VARCHAR(100),
            fecha_nacimiento           DATETIME,
            telefono_contacto          INT,
            telefono_emergencia        INT,
            obra_social                VARCHAR(50),
            numero_socio_obra_social   VARCHAR(20),
            telefono_emergencia_obrasocial VARCHAR(50)
    );

    -- 2. Importar desde Excel
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = '
        INSERT INTO #GrupoFamiliarTemp
        SELECT *
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.16.0'',
            ''Excel 12.0;HDR=YES;Database=' + @ruta_excel + ''',
            ''SELECT * FROM [Grupo Familiar$]''
        );';
    EXEC sp_executesql @sql;

    -- 3. Normalizar teléfonos y numero de socio
ALTER TABLE #GrupoFamiliarTemp ALTER COLUMN telefono_contacto VARCHAR(20);
		UPDATE #GrupoFamiliarTemp
		SET telefono_contacto = STUFF(CAST(telefono_contacto AS VARCHAR(10)), 3, 0, '-')
		WHERE telefono_contacto BETWEEN 1000000000 AND 9999999999;


		ALTER TABLE #GrupoFamiliarTemp ALTER COLUMN telefono_emergencia VARCHAR(20);
		UPDATE #GrupoFamiliarTemp
		SET telefono_emergencia = STUFF(CAST(telefono_emergencia AS VARCHAR(10)), 3, 0, '-')
		WHERE telefono_emergencia BETWEEN 1000000000 AND 9999999999;

   	UPDATE #GrupoFamiliarTemp
		SET numero_socio = CAST(
		SUBSTRING(CAST(numero_socio AS VARCHAR(20)), 4, 
		LEN(CAST(numero_socio AS VARCHAR(20)))
		) AS INT)
		WHERE CAST(numero_socio AS VARCHAR(20)) LIKE 'SN-%';

			UPDATE #GrupoFamiliarTemp
		SET numero_socio_asociado = CAST(
		SUBSTRING(CAST(numero_socio_asociado AS VARCHAR(20)), 4, 
		LEN(CAST(numero_socio_asociado AS VARCHAR(20)))
		) AS INT)
		WHERE CAST(numero_socio_asociado AS VARCHAR(20)) LIKE 'SN-%';

		 -- 4. Eliminar tuplas con fecha_nacimiento NULL
    DELETE FROM #GrupoFamiliarTemp WHERE fecha_nacimiento IS NULL;

    -- 5. Eliminar duplicados en el Excel (por numero_socio)
    DELETE T
    FROM #GrupoFamiliarTemp T
    JOIN (
        SELECT numero_socio
        FROM #GrupoFamiliarTemp
        GROUP BY numero_socio
        HAVING COUNT(*) > 1
    ) D ON T.numero_socio = D.numero_socio;

    -- 6. Eliminar filas cuyo numero_socio ya existe en socios.Socio
    DELETE T
    FROM #GrupoFamiliarTemp T
    JOIN socios.Socio S ON T.numero_socio = S.numero_socio;
	--------------------------
		UPDATE #GrupoFamiliarTemp
SET numero_socio_asociado = 1
WHERE numero_socio = 4121;


	-------------
    -- 7. Eliminar filas cuyo numero_socio_asociado NO existe en socios.Socio
    DELETE T
    FROM #GrupoFamiliarTemp T
    LEFT JOIN socios.Socio S ON T.numero_socio_asociado = S.numero_socio
    WHERE S.numero_socio IS NULL;
		SET IDENTITY_INSERT socios.Socio on;

	 INSERT INTO socios.Socio (
        numero_socio,
        nombre,
        apellido,
        dni,
        email,
        fecha_nac,
        tel_contacto,
        telefono,
        obra_social,
        num_carnet_obra_social,
        es_menor,
        id_responsable,
        parentesco
    )
    SELECT
        numero_socio,
        nombre,
        apellido,
        dni,
        email,
        fecha_nacimiento,
        telefono_contacto,
        telefono_emergencia,
        obra_social,
        numero_socio_obra_social,
        1,                   -- es_menor
        numero_socio_asociado, -- id_responsable
        'FAMILIAR'           -- parentesco por defecto (puede ajustarse)
    FROM #GrupoFamiliarTemp
    WHERE 
        dni BETWEEN 1000000 AND 99999999
        AND (email IS NULL OR email LIKE '_%@_%._%')
        AND fecha_nacimiento BETWEEN '1900-01-01' AND GETDATE()
        AND (telefono_contacto LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' OR telefono_contacto IS NULL)
        AND telefono_emergencia LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]';

END;
GO

-----------------------------------------------------------------------------------------

EXEC socios.sp_importar_grupo_familiar
    @ruta_excel = N'C:\Users\zacar\Documents\tpbdda\TPI-2025-1C\Datos socios.xlsx';



--------------------------------------------------------------------------------------------








	------------------------------------------

