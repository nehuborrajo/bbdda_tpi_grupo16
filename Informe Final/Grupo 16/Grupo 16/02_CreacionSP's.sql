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

--CREACION DE SP's--

--SP para crear usuario a partir de un nuevo dni de socio
go
create or alter procedure socios.CrearUsuarioNuevo (@dni int, @rol varchar(15), @id_usuario int output)
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


--SP PARA INSERTAR SOCIOS (Inscripcion Individual)
go
create or alter procedure socios.InsertarSocio (@nombre varchar(50), @apellido varchar(50), @dni int, @email varchar(40), @fecha_nac date, @telefono varchar(20), @tel_contacto varchar(20), @obra_social varchar(30), @num_carnet_obra_social varchar(30))
as
begin
begin try
	begin transaction
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
		rollback;
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

	declare @numero_socio int 
	if not exists (select 1 from socios.Socio)
		set @numero_socio = 1000;
	else
	set @numero_socio = (select max(numero_socio) from socios.Socio)+1
	exec socios.CrearUsuarioNuevo @dni, 'Socio', @id_usuario = @usuario_id output

	insert into socios.Socio (numero_socio, nombre, apellido, dni, email, fecha_nac, telefono, tel_contacto, obra_social, num_carnet_obra_social, membresia_id, usuario_id)
	values (@numero_socio, @nombre, @apellido, @dni, @email, @fecha_nac, @telefono, @tel_contacto, @obra_social,
	@num_carnet_obra_social, @categoria, @usuario_id)

	if exists (select 1 from eventos.Invitado where dni = @dni)
	begin
		delete from eventos.Invitado where dni = @dni
	end
	PRINT 'Socio agregado correctamente.';
	end
	else
	begin
		RAISERROR('El DNI pertenece a un socio ya existente o el numero de socio ya se encuentra en uso.', 16, 1);
		rollback
		return
	end

	commit
end try
begin catch
	IF @@TRANCOUNT > 0
            ROLLBACK;
	DECLARE @MensajeError NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@MensajeError, 16, 1);
END CATCH

end

--SP para crear nuevo usuario a socio existente
go
create or alter procedure socios.CrearUsuarioSocio (@dni int, @rol varchar(20))
as
begin
begin try
	begin transaction
	if (@rol not in('Socio', 'Administrador'))
	begin
		RAISERROR('Rol invalido.', 16, 1);
		rollback
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
		begin
			RAISERROR('El DNI pertenece a un socio con usuario.', 16, 1);
			rollback
			return;
		end
	end
	else
	begin
		RAISERROR('El DNI no pertenece a un socio activo o ya tiene un usuario asociado.', 16, 1);
		rollback
		return
	end
	commit;
end try
begin catch
	DECLARE @MensajeError NVARCHAR(4000) = ERROR_MESSAGE();
end catch
end

--SP PARA INSERTAR Grupo Familiar (Inscripcion Familiar)
go
create or alter procedure socios.InsertarSocioFamiliar (@nombre varchar(50), @apellido varchar(50), @dni int, @email varchar(40), @fecha_nac date, @telefono varchar(20), @parentesco varchar(15),
@nombre_menor varchar(50), @apellido_menor varchar(50), @dni_menor int, @fecha_nac_menor date, @obra_social varchar(30), @num_carnet_obra_social varchar(30))
as
begin
begin try
	begin transaction
	declare @usuario_id int
	declare @familiar_id int
	if not exists (select 1 from socios.Usuario where nombre_usuario = @dni)
	begin
		exec socios.CrearUsuarioNuevo @dni, 'Socio', @id_usuario = @usuario_id output
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

			SET @familiar_id = (select numero_socio from socios.Socio where dni = @dni)
			declare @id_menor int = (select max(numero_socio)+1 from socios.Socio)
			insert into socios.Socio (numero_socio, nombre, apellido, dni, email, fecha_nac, tel_contacto, obra_social, num_carnet_obra_social, es_menor, membresia_id) values (@id_menor ,@nombre_menor, @apellido_menor, @dni_menor, @email, @fecha_nac_menor, @telefono, @obra_social, @num_carnet_obra_social, 1, @membresia)
			if not exists (select 1 from socios.Socio where dni = @dni)
			begin
				SET @familiar_id = (select max(numero_socio)+1 from socios.Socio)
				insert into socios.Socio (numero_socio ,nombre, apellido, dni, email, fecha_nac, telefono, es_responsable, parentesco, usuario_id) values (@familiar_id, @nombre, @apellido, @dni, @email, @fecha_nac, @telefono, 1, @parentesco, @usuario_id)
				--SET @familiar_id = (select numero_socio from socios.Socio where dni = @dni)
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
		begin
			RAISERROR('El DNI del menor ya se encuentra en el sistema.', 16, 1);
			rollback;
			return;
		end
	end
	else
	begin
		RAISERROR('Error. El "menor" a asociar ya es mayor de edad.', 16, 1);
		rollback;
		return
	end
	commit
end try
begin catch 
	DECLARE @MensajeError NVARCHAR(4000) = ERROR_MESSAGE();
end catch

end

--SP para asociar Responsable por DNI
go
create or alter procedure socios.AsociarResponsable (@dni int)
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
create or alter procedure socios.DesasociarResponsable (@dni int)
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
create or alter procedure socios.DesactivarSocio (@dni int)
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
create or alter procedure socios.EliminarSocio (@dni int)
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
create or alter procedure socios.ActivarSocio (@dni int)
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
create or alter procedure socios.InsertarMembresia (@nombre varchar(15), @precio decimal(10,2), @fecha_vig date)
as
begin
	IF NOT EXISTS (SELECT 1 FROM socios.Membresia WHERE nombre = @nombre) --verificamos que no exista ya una membresia con ese nombre
	begin
		
		insert into socios.Membresia values (@nombre, @precio, @fecha_vig)
		PRINT 'Membresia insertada correctamente.';
	end
	else
		RAISERROR('La membresia especificada ya existe.', 16, 1);
end

--SP para modificar los valores de las membresias
go
create or alter procedure socios.ModificarValorMembresia (@id int, @nuevo_precio decimal(10,2))
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
create or alter procedure socios.EliminarMembresia (@id int)
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
create or alter procedure eventos.InsertarActividad (@nombre varchar(30), @precio decimal(10,2), @fecha_vig date)
as
begin
	IF NOT EXISTS (SELECT 1 FROM eventos.Actividad WHERE nombre = @nombre)
	begin
		 
		insert into eventos.Actividad values (@nombre, @precio, @fecha_vig)
		PRINT 'Actividad insertada correctamente.';
	end
	else
		RAISERROR('La actividad especificada ya existe.', 16, 1);
end

--SP para modificar los valores de las Actividades
go
create or alter procedure eventos.ModificarValorActividad (@id int, @nuevo_precio decimal(10,2))
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
create or alter procedure eventos.EliminarActividad (@id int)
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
create or alter procedure socios.ActualizarContraseniaUsuario (@dni int, @nueva_contra varchar(20))
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
create or alter procedure socios.EliminarUsuario (@dni int)
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
create or alter procedure eventos.InscribirSocioActividad (@dni int, @id_activ int)
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
create or alter procedure eventos.EliminarSocioActividad (@dni int, @id_activ int)
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
create or alter procedure finanzas.GenerarFacturaCuota (@id_cuota int, @descAct bit, @descMemb bit, @acumAct decimal(10,2), @acumMem decimal(10,2))
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
	declare @valor decimal(10,2)
	declare @fecha_venc date
	declare @detalleAct varchar(80)
	declare @detalleMem varchar(80)
	declare @detalle varchar(160)
	declare @desc decimal(10,2)

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
	declare @fecha_venc2 date = DATEADD(DAY, 10, GETDATE());

	insert into finanzas.Factura (id_cuota, id_socio, valor, fecha_emision, fecha_vencimiento, fecha_vencimiento_dos, estado, origen, detalle) values (@id_cuota, @id_socio, @valor, GETDATE(), @fecha_venc, @fecha_venc2, 'Pendiente', 'Cuota', @detalle)
	print 'Factura generada correctamente'
end

--sp para crear cuota socio a partir de las actividades	
go
create or alter procedure finanzas.GenerarCuotaSocio (@dni int, @periodo varchar(10))
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
			declare @acum_act decimal(10,2)
			declare @acum_mem decimal(10,2)
			declare @acum decimal(10,2)
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
			exec finanzas.GenerarFacturaCuota @id_cuota, @tieneDescActividad, @tieneDescMembresia, @acum_act, @acum_mem
			print 'Cuota generada correctamente.'
		end
		else if (@es_responsable = 0 and @id_fami is not null)
		begin
			declare @fecha2 date
			--declare @periodo2 varchar(10)
			declare @acum_act2 decimal(10,2)
			declare @acum_mem2 decimal(10,2)
			declare @acum2 decimal(10,2)

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
			exec finanzas.GenerarFacturaCuota @id_cuota, @tieneDescActividad, @tieneDescMembresia, @acum_act2, @acum_mem2
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
create or alter procedure finanzas.EliminarCuota (@id_cuota int)
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
create or alter procedure eventos.CrearInvitado (@nombre varchar(50), @apellido varchar(50), @dni int, @telefono varchar(20))
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
create or alter procedure eventos.EliminarInvitado (@dni int)
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
create or alter procedure finanzas.CrearMetodoPago (@nombre varchar(25))
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
create or alter procedure finanzas.EliminarMetodoPago (@id int)
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
create or alter procedure finanzas.ModificarMetodoPago (@id int, @nuevo_nombre varchar(25))
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
create or alter procedure finanzas.GenerarFacturaReserva (@id_socio int, @id_invitado int, @fecha date, @valor decimal(10,2), @valor_inv decimal(10,2), @id_reserva int, @llovio bit)
as
begin
	declare @fecha_venc date
	declare @detalle varchar(160) = 'Valor Reserva: ' + cast(@valor as varchar)
	print 'hola'
	declare @desc decimal(10,2)
	SET @fecha_venc = DATEADD(DAY, 5, GETDATE());
	declare @fecha_venc2 date = DATEADD(DAY, 10, GETDATE());
	if(@llovio = 1)
	begin
		set @desc = ((@valor*60)/100)
		set @detalle = @detalle + CHAR(13) + CHAR(10) + '(Reeintegro por lluvia: ' + cast(@desc as varchar) + ')'
	end
	
	insert into finanzas.Factura (id_socio, id_reserva, valor, fecha_emision, fecha_vencimiento, fecha_vencimiento_dos, estado, detalle, origen) values (@id_socio, @id_reserva, @valor,GETDATE(), @fecha_venc, @fecha_venc2, 'Pendiente', @detalle, 'Reserva')
	if @id_invitado is not null
	begin
			set @detalle = 'Valor Reserva (invitado): ' + cast(@valor_inv as varchar)
			if(@llovio = 1)
			begin
				set @desc = ((@valor_inv*60)/100)
				set @detalle = @detalle + CHAR(13) + CHAR(10) + '(Reeintegro por lluvia: ' + cast(@desc as varchar) + ')'
			end
			insert into finanzas.Factura (id_invitado, id_reserva, valor, fecha_emision, fecha_vencimiento, fecha_vencimiento_dos, estado, origen, detalle) values (@id_invitado, @id_reserva, @valor_inv,GETDATE(), @fecha_venc, @fecha_venc2, 'Pendiente', 'Reserva', @detalle)
	end
end

--SP para generar Reserva a partir dni socio, dni invitado(op), id act, fecha
go
create or alter procedure eventos.CrearReserva (@dni_socio int, @dni_invitado int, @id_act int, @fecha date)
as
begin
	print 'hola'
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
	print 'hola'
	declare @valor decimal(10,2)
	declare @valor_inv decimal(10,2)
	declare @llovio bit = 0

	IF EXISTS (
    SELECT 1
    FROM eventos.Clima
    WHERE lluvia_mm > 0
      AND CAST(fecha_hora AS DATE) = @fecha
) 
	set @llovio=1
	
		
	set @valor = (select a.costo from eventos.Actividad a where id = @id_act)
	set @valor_inv = (select a.costo from eventos.Actividad a where nombre = 'Pileta Invitado')

	declare @id_socio int
	set @id_socio = (select numero_socio from socios.Socio where dni = @dni_socio)

	declare @id_invitado int
	if @dni_socio is not null
	begin	
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
	exec finanzas.GenerarFacturaReserva @id_socio, @id_invitado, @fecha, @valor, @valor_inv, @id_reserva, @llovio
	
	
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
create or alter procedure eventos.EliminarReserva (@id_reserva int)
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
create or alter procedure finanzas.EliminarFactura (@id int)
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
create or alter procedure finanzas.GenerarPagoFacturaCuota (@dni int, @id_fact int, @id_metpag int)
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
	declare @valor decimal(10,2)
	declare @id_cuota int
	set @id_socio = (select id_socio from finanzas.Factura where numero_factura = @id_fact)

	set @valor = (select f.valor from finanzas.Factura f where numero_factura = @id_fact)

	set @id_cuota = (select f.id_cuota from finanzas.Factura f where numero_factura = @id_fact)

	declare @id_pago int = (select max(id)+1 from finanzas.Pago)

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
create or alter procedure finanzas.GenerarPagoFacturaReservaSocio (@dni int, @id_fact int, @id_metpag int)
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
	declare @valor decimal(10,2)

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
create or alter procedure finanzas.GenerarPagoFacturaReservaInvitado (@dni int, @id_fact int, @id_metpag int)
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
	declare @valor decimal(10,2)

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
create or alter procedure finanzas.ReembolsoPago (@id_pago int)
as
begin
	if not exists (select 1 from finanzas.Pago where id = @id_pago)
	begin
		RAISERROR('El pago indicado no existe.', 16, 1);
		return
	end
	if  exists (select 1 from finanzas.Pago where id = @id_pago and reembolsado = 1)
	begin
		RAISERROR('El pago indicado ya fue reembolsado.', 16, 1);
		return
	end

	update finanzas.Pago
	set reembolsado = 1
	where id = @id_pago

	print'Pago reembolsado correctamente'

end

--sp generar pago a cuentas por id pago
go
create or alter procedure finanzas.PagoACuentasPago (@id_pago int)
as
begin
	if not exists (select 1 from finanzas.Pago where id = @id_pago)
	begin
		RAISERROR('El pago indicado no existe.', 16, 1);
		return
	end
	if  exists (select 1 from finanzas.Pago where id = @id_pago and reembolsado = 1)
	begin
		RAISERROR('El pago indicado ya fue reembolsado.', 16, 1);
		return
	end

	declare @id_socio int
	declare @valor decimal(10,2)

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
	set reembolsado = 1
	where id = @id_pago
	print'Pago a cuentas realizado correctamente.'

end

--sp para actualizar todas las facturas en caso de vencimiento segun fecha por parametro
go
create or alter procedure finanzas.ActualizarFacturas (@fecha_hoy date)
as
begin

	update finanzas.Factura
	set valor *= 1.1, estado='Vencida 1'
	WHERE @fecha_hoy > fecha_vencimiento -- DATEADD(DAY, 10, fecha_vencimiento) > DATEADD(DAY, 5, fecha_vencimiento)
	AND estado = 'Pendiente'; 
	
	update finanzas.Factura
	set estado='Vencida 2'
	WHERE @fecha_hoy > fecha_vencimiento_dos --DATEADD(DAY, 10, fecha_vencimiento) > DATEADD(DAY, 5, fecha_vencimiento)
	AND estado = 'Vencida 1'; 

	print'Facturas actualizadas correctamente'
end


-- sp para actualizar socios morosos
go
create or alter procedure finanzas.ActualizarMorosos
as
begin
	delete from finanzas.Moroso

	insert into finanzas.Moroso (numero_socio, id_factura)
	select id_socio, numero_factura from finanzas.Factura where estado = 'Vencida 2'

end

--sp para desactivar socios morosos
go
create or alter procedure finanzas.DesactivarSociosMorosos
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





----------------------------------------------------------------------------

-- IMPORTS

----------------------------------------------------------------------------

--SP para crear profesor
go
create or alter procedure eventos.CrearProfesor (@nombre varchar(50))
as
begin
	insert into eventos.Profesor (nombre) values (@nombre)
end

--SP para eliminar profesor por ID
go
create or alter procedure eventos.EliminarProfesor (@id int)
as
begin
	if exists (select 1 from eventos.Profesor where id = @id)
		delete from eventos.Profesor where id = @id
	else
		RAISERROR('El ID no existe.', 16, 1);
end


--SP para importar OpenMeteo 2024
go
create or alter procedure eventos.ImportarMeteo24 (@ruta_excel varchar(260))
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
	DECLARE @sql NVARCHAR(MAX) = '
	BULK INSERT #climaTemp
	FROM ''' + @ruta_excel + '''
	WITH (
		FIELDTERMINATOR = '','',
		ROWTERMINATOR = ''\n'',
		FIRSTROW = 4
	);'
	EXEC sp_executesql @sql;

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
		TRY_CAST(temperatura AS decimal(10,2)) AS temperatura,
		TRY_CAST(lluvia_mm AS decimal(10,2)) AS lluvia_mm,
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
create or alter procedure eventos.ImportarMeteo25 (@ruta_excel varchar(260))
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
	DECLARE @sql NVARCHAR(MAX) = '
	BULK INSERT #climaTemp
	FROM ''' + @ruta_excel + '''
	WITH (
		FIELDTERMINATOR = '','',
		ROWTERMINATOR = ''\n'',
		FIRSTROW = 4
	);'
	EXEC sp_executesql @sql;
	
	
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
		TRY_CAST(temperatura AS decimal(10,2)) AS temperatura,
		TRY_CAST(lluvia_mm AS decimal(10,2)) AS lluvia_mm,
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


-----------------------------------------------------------------------------
/*para poder usar OPENROWSET activo esto
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
ademas tengo que instalar "https://www.microsoft.com/es-es/download/details.aspx?id=54920"
tengo que ver que ejecutando esto 
EXEC sp_enum_oledb_providers;
aparezca "Microsoft.ACE.OLEDB.12.0" y "Microsoft.ACE.OLEDB.16.0"
y luego para verificar si se me instalo el motor uso:
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.16.0', N'AllowInProcess', 1;
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.16.0', N'DynamicParameters', 1;
*/

--------------------------------------------------------------------------

--Importar resopinsables de pago
        
GO
CREATE OR ALTER PROCEDURE socios.importar_responsables_pago
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

		--declare @ruta_excel nvarchar(260) = N'C:\TPI-2025-1C\Datos socios.xlsx';
	   -- 3. Construcción dinámica de OPENROWSET para importar Excel
		DECLARE @sql NVARCHAR(MAX);
		SET @sql = '
			INSERT INTO #ResponsablesTemp
			SELECT *
			FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.16.0'',
				''Excel 12.0;HDR=YES; IMEX=1;Database=' + @ruta_excel + ''',
				''SELECT * FROM [Responsables de Pago$]''
			);';
		EXEC sp_executesql @sql;

		--select * from #ResponsablesTemp
		---------------------------- normalizo los datos
		--casteo telefonos de contacto
		ALTER TABLE #ResponsablesTemp ALTER COLUMN telefono_contacto VARCHAR(20);
		UPDATE #ResponsablesTemp
		SET telefono_contacto = STUFF(CAST(telefono_contacto AS VARCHAR(10)), 3, 0, '-')
		WHERE telefono_contacto BETWEEN 1000000000 AND 9999999999;
		
		--casteo nmero de socio (dejo solo el numero)
		UPDATE #ResponsablesTemp
		SET numero_socio = CAST(
		SUBSTRING(CAST(numero_socio AS VARCHAR(20)), 4, 
		LEN(CAST(numero_socio AS VARCHAR(20)))
		) AS INT)
		WHERE CAST(numero_socio AS VARCHAR(20)) LIKE 'SN-%';
		
		--casteo telefonos de emergencia
		ALTER TABLE #ResponsablesTemp ALTER COLUMN telefono_emergencia VARCHAR(20);
		UPDATE #ResponsablesTemp
		SET telefono_emergencia = STUFF(CAST(telefono_emergencia AS VARCHAR(10)), 3, 0, '-')
		WHERE telefono_emergencia BETWEEN 1000000000 AND 9999999999;
		
		--casteo dni's (ajusto a maximo 8 digitos)
		UPDATE #ResponsablesTemp
		SET dni = dni / 10
		WHERE dni >99999999

		--no dejo insertar aquellas tuplas con fecha de nac null o menor a 18 años
	
		/*SELECT nombre, dni
		FROM #ResponsablesTemp
		WHERE fecha_nacimiento IS NULL
		or DATEDIFF(YEAR, fecha_nacimiento, GETDATE()) < 18;;*/
		DELETE FROM #ResponsablesTemp
		WHERE fecha_nacimiento IS NULL
		or DATEDIFF(YEAR, fecha_nacimiento, GETDATE()) < 18; 

		
        -- 4. Insertar responsables en socios.Socio verificando duplicados por DNI

		--utilizo una tabla temporal nueva con numero de fila asignado
		WITH ResponsablesNumerados AS (
		SELECT 
			ROW_NUMBER() OVER (ORDER BY numero_socio) AS fila,
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
			telefono_emergencia_obrasocial
		FROM #ResponsablesTemp
		)
		SELECT * INTO #ResponsablesTempOrdenados FROM ResponsablesNumerados;
		--select * from #ResponsablesTempOrdenados
		
		DECLARE @fila_max INT = (SELECT MAX(fila) FROM #ResponsablesTempOrdenados)
		DECLARE @i INT = 1
		declare @dni int
		declare @usuario_id int
		declare @membresia int = (select id from socios.Membresia where nombre = 'Mayor')
		declare @num_socio int

		while @i <= @fila_max
		begin
			select @num_socio = numero_socio, @dni = dni from #ResponsablesTempOrdenados where fila = @i
			if ((not exists (select 1 from socios.Socio where numero_socio = @num_socio)) and not exists (select 1 from socios.Socio where dni = @dni))
			begin
					if not exists (select 1 from socios.Usuario where nombre_usuario = @dni)
						exec socios.CrearUsuarioNuevo @dni, 'Responsable', @id_usuario = @usuario_id output
					set @usuario_id = (select id from socios.Usuario where nombre_usuario = @dni)
						
					INSERT INTO socios.Socio (
						numero_socio,
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
						responsable_y_socio,
						membresia_id,
						usuario_id
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
						1,       -- activo
						0,       -- es_menor
						1,       -- es_responsable
						1,        -- responsable_y_socio
						@membresia,
						@usuario_id
					FROM #ResponsablesTemp
					WHERE
						numero_socio = @num_socio
						AND dni BETWEEN 1000000 AND 99999999
						AND email LIKE '_%@_%._%'
						AND LEN(email) <= 100
						AND fecha_nacimiento BETWEEN '1900-01-01' AND GETDATE()
						AND telefono_contacto LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
						AND telefono_emergencia LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'		
			end
			else
				PRINT 'Numero de socio ' + CAST(@num_socio AS VARCHAR) + ' o DNI ' + CAST(@dni AS VARCHAR) + ' ya existente.'
			set @i += 1
		end	
		
		PRINT 'Importación de responsables finalizada correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error durante la importación: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- No inserta el 4085 por DNI duplicado y el 4111 por fecha de nacimiento invalida

-------------------------------------------------------------------------------------------------------------
--sp importar  grupo familiar
go
CREATE OR ALTER PROCEDURE socios.importar_grupo_familiar
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
            numero_socio_obra_social   VARCHAR(30),
            telefono_emergencia_obrasocial VARCHAR(50)
    );

    -- 2. Importar desde Excel
    --declare @ruta_excel nvarchar(260) = N'C:\TPI-2025-1C\Datos socios.xlsx';
	DECLARE @sql NVARCHAR(MAX);
    SET @sql = '
        INSERT INTO #GrupoFamiliarTemp
        SELECT *
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.16.0'',
            ''Excel 12.0 Xml;HDR=YES; IMEX=1;Database=' + REPLACE(@ruta_excel, '''', '''''') + N''',
            ''SELECT * FROM [Grupo Familiar$]''
        );';
    EXEC sp_executesql @sql;

	--select * from #GrupoFamiliarTemp
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

	-- 4. Eliminar tuplas con fecha_nacimiento NULL o mayores de 18
    DELETE FROM #GrupoFamiliarTemp WHERE fecha_nacimiento IS NULL or DATEDIFF(YEAR, fecha_nacimiento, GETDATE()) > 18;
	--select * FROM #GrupoFamiliarTemp WHERE fecha_nacimiento IS NULL or DATEDIFF(YEAR, fecha_nacimiento, GETDATE()) > 18;

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

	-------------
    -- 7. Eliminar filas cuyo numero_socio_asociado NO existe en socios.Socio
    DELETE T
    FROM #GrupoFamiliarTemp T
    LEFT JOIN socios.Socio S ON T.numero_socio_asociado = S.numero_socio
    WHERE S.numero_socio IS NULL;
	--SET IDENTITY_INSERT socios.Socio on;

	WITH FamiliarNumerados AS (
		SELECT 
			ROW_NUMBER() OVER (ORDER BY numero_socio) AS fila,
			numero_socio,
			numero_socio_asociado,
			nombre,
			apellido,
			dni,
			email,
			fecha_nacimiento,
			telefono_contacto,
			telefono_emergencia,
			obra_social,
			numero_socio_obra_social,
			telefono_emergencia_obrasocial
		FROM #GrupoFamiliarTemp
		)
		SELECT * INTO #GrupoFamiliarTempOrd FROM FamiliarNumerados;
	--select * from #GrupoFamiliarTempOrd

    declare	@fecha_nacimiento DATETIME
	declare @edad int
	declare @membresia int
	declare @num_socio int
	declare @num_socio_resp int
	declare @dni int

	DECLARE @fila_max INT = (SELECT MAX(fila) FROM #GrupoFamiliarTempOrd);
	DECLARE @i INT = 1

	while @i <= @fila_max
	begin
		select @num_socio = numero_socio, @dni = dni, @num_socio_resp = numero_socio_asociado from #GrupoFamiliarTempOrd where fila = @i
		if ((not exists (select 1 from socios.Socio where numero_socio = @num_socio)) and not exists (select 1 from socios.Socio where dni = @dni))
		begin
			if exists (select 1 from socios.Socio where numero_socio = @num_socio_resp)
			begin
				--copio el valor de la fecha de nac
				select @fecha_nacimiento = fecha_nacimiento from #GrupoFamiliarTempOrd where fila = @i

				-- Calcular edad exacta
				SET @edad = DATEDIFF(YEAR, @fecha_nacimiento, GETDATE());
				-- Ajustar edad si aún no cumplió años este año
				IF (DATEADD(YEAR, @edad, @fecha_nacimiento) > GETDATE())
				SET @edad = @edad - 1;
				-- Asignar categoría según la edad
				SET @membresia = CASE 
				WHEN @edad <= 12 THEN (select id from socios.Membresia where nombre = 'Menor')
				WHEN @edad BETWEEN 13 AND 17 THEN (select id from socios.Membresia where nombre = 'Cadete')
				ELSE (select id from socios.Membresia where nombre = 'Mayor')
				end
				--print @membresia

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
					parentesco,
					membresia_id
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
						1,							-- es_menor
						numero_socio_asociado,		-- id_responsable
						'Familiar',					-- parentesco por defecto (puede ajustarse)
						@membresia
					FROM #GrupoFamiliarTemp
					WHERE 
						numero_socio = @num_socio
			end
			else
				print 'Numero de socio responsable ' + CAST(@num_socio_resp AS VARCHAR) + ' inexistente.'	
		end
		else
			PRINT 'Numero de socio ' + CAST(@num_socio AS VARCHAR) + ' o DNI ' + CAST(@dni AS VARCHAR) + ' ya existente.'
		set @i += 1
	end
END
GO

-----------------------------------------------------------------------------------------

--sp para generar cuotas por importacion
go
create or alter procedure finanzas.GenerarCuotaImportacion @num_socio int, @fecha datetime, @valor decimal(10,2), @id_cuota int output
as
begin
	--seteo @fecha como el primer dia del mes
	set @fecha = DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)
	declare @periodo VARCHAR(7) = FORMAT(@fecha, 'MM-yyyy')
	
	insert into finanzas.Cuota (id_socio, valor, fecha, periodo, estado) values (@num_socio, @valor, @fecha, @periodo, 'Pagada')
	set @id_cuota = SCOPE_IDENTITY()
end
go

-------------------------------------------------------------------------------------------

--sp para generar facturas a partir de cuotas generadas por importacion
go
create or alter procedure finanzas.GenerarFacturaCuotaImportacion @cuota_id int, @num_socio int, @valor decimal(10,2), @fecha datetime, @id_factura int output
as
begin
	declare @fecha_vencim datetime = DATEADD(DAY, 5, @fecha);
	declare @fecha_vencim2 date = DATEADD(DAY, 5, @fecha_vencim);
	declare @detalle  varchar(100) = 'Cuota: ' + cast(@valor as varchar) 

	insert into finanzas.Factura (id_cuota, id_socio, valor, fecha_emision, fecha_vencimiento, fecha_vencimiento_dos, estado, detalle, origen)
	values (@cuota_id, @num_socio, @valor, @fecha, @fecha_vencim, @fecha_vencim2, 'Pagada',@detalle, 'Cuota')
	set @id_factura = SCOPE_IDENTITY()
end


--------------------------------------------------------------------------------------------

--sp pago cuotas
go
CREATE OR ALTER PROCEDURE finanzas.importar_pago_cuotas
    @ruta_excel NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Tabla temporal
    IF OBJECT_ID('tempdb..#PagosTemp') IS NOT NULL
        DROP TABLE #PagosTemp;
	IF OBJECT_ID('tempdb..#PagosTemp') IS NOT NULL
        DROP TABLE #PagosTempOrdenados;

    CREATE TABLE #PagosTemp (
            numero_pago				   bigint,
			fecha					   DATETIME,
		    numero_socio_resp		   VARCHAR(20),
            valor                      decimal(10,2),                --saar float
            medio_pago				   varchar(25)
    );

    -- 2. Importar desde Excel
    --declare @ruta_excel NVARCHAR(260) = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx'
	DECLARE @sql NVARCHAR(MAX);
    SET @sql = '
        INSERT INTO #PagosTemp
        SELECT *
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.16.0'',
            ''Excel 12.0;HDR=YES; IMEX=1;Database=' + @ruta_excel + ''',
            ''SELECT * FROM [pago cuotas$]''
        );';
    EXEC sp_executesql @sql;
	--select * from #PagosTemp

    -- Normalizar numero de socio
   		UPDATE #PagosTemp
		SET numero_socio_resp = CAST(
		SUBSTRING(CAST(numero_socio_resp AS VARCHAR(20)), 4, 
		LEN(CAST(numero_socio_resp AS VARCHAR(20)))
		) AS INT)
		WHERE CAST(numero_socio_resp AS VARCHAR(20)) LIKE 'SN-%';

    -- Eliminar duplicados en el Excel (por numero_pago)
    DELETE T
    FROM #PagosTemp T
    JOIN (
        SELECT numero_pago
        FROM #PagosTemp
        GROUP BY numero_pago
        HAVING COUNT(*) > 1
    ) D ON T.numero_pago = D.numero_pago;

    -- Eliminar filas cuyo numero_socio no existe en socios.Socio
    DELETE T
    FROM #PagosTemp T
    LEFT JOIN socios.Socio S ON T.numero_socio_resp = S.numero_socio
	WHERE S.numero_socio IS NULL;

	----------------------------------------------------------
	--utilizo una tabla temporal nueva con numero de fila asignado
	WITH PagosNumerados AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY numero_pago) AS fila,
        numero_pago,
        fecha,
        numero_socio_resp,
        valor,
        medio_pago
    FROM #PagosTemp
	)
	SELECT * INTO #PagosTempOrdenados FROM PagosNumerados;

	-----------------------------------------------------------
	declare @max_fila int = (select max(fila) from #PagosTempOrdenados)
	declare @min_fila int = (select min(fila) from #PagosTempOrdenados)

	declare @num_pago bigint
	declare @num_socio int
	declare @fecha datetime
	declare @cuota_id int
	declare @factura_id int
	declare @valor decimal(10,2)
	declare @medio_pago_nombre varchar(30)
	declare @medio_pago_id int


	while @min_fila <= @max_fila
	begin
		select @num_pago = numero_pago from #PagosTempOrdenados where fila = @min_fila
		if exists (select 1 from #PagosTemp where numero_pago = @num_pago)
		begin
			if not exists (select 1 from finanzas.Pago where id = @num_pago)
			begin
				select @medio_pago_nombre = medio_pago from #PagosTemp where numero_pago = @num_pago
				set @medio_pago_id = (select id from finanzas.MetodoPago where nombre = @medio_pago_nombre)
				if (@medio_pago_id is null)
				begin
					exec finanzas.CrearMetodoPago @medio_pago_nombre
					set @medio_pago_id = (select id from finanzas.MetodoPago where nombre = @medio_pago_nombre)
				end
				
				select
					@fecha = p.fecha,
					@valor = p.valor,						
					@num_socio = p.numero_socio_resp
				from #PagosTemp p
				where numero_pago = @num_pago	

				exec finanzas.GenerarCuotaImportacion @num_socio, @fecha, @valor, @id_cuota = @cuota_id output
				exec finanzas.GenerarFacturaCuotaImportacion @cuota_id, @num_socio, @valor, @fecha, @id_factura = @factura_id output

				insert into finanzas.Pago(id, id_cuota, id_factura, id_socio, id_metodo_pago, fecha, valor)
				values (@num_pago, @cuota_id, @factura_id, @num_socio, @medio_pago_id, @fecha, @valor)

				print 'Pago ' + cast(@num_pago as varchar) + ' registrado correctamente.'
				
				
			end
			else
				print 'El numero de pago ya existe registrado: ' + cast(@num_pago as varchar)
		end
		else
			print 'El numero de pago no existe en #PagosTemp: ' + cast(@num_pago as varchar)
		set @min_fila += 1
	end

END;
GO

-----------------------------------------------------------------------------------------

--sp para importar valores de actividades

go
create or alter procedure eventos.importar_valores_actividad @ruta_excel NVARCHAR(260)
as
begin
	begin try
		-- 1. Tabla temporal
		IF OBJECT_ID('tempdb..#ValoresActTemp') IS NOT NULL
			DROP TABLE #ValoresActTemp;

		CREATE TABLE #ValoresActTemp (
				nombre_activ varchar(30),
				valor decimal(10,2),
				fecha_vig date,
		);

		-- 2. Importar desde Excel
		--declare @ruta_excel NVARCHAR(260) = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx'
		DECLARE @sql NVARCHAR(MAX);
		SET @sql = '
			INSERT INTO #ValoresActTemp
			SELECT *
			FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.16.0'',
				''Excel 12.0;HDR=YES; IMEX=1;Database=' + @ruta_excel + ''',
				''SELECT * FROM [Tarifas$B2:D8]''
			);';
		EXEC sp_executesql @sql;
		--select * from #ValoresActTemp

		WITH ValoresActNumerados AS (
		SELECT 
			ROW_NUMBER() OVER (ORDER BY nombre_activ) AS fila,
			nombre_activ,
			valor,
			fecha_vig
		FROM #ValoresActTemp
		)
		SELECT * INTO #ValoresActTempOrdenados FROM ValoresActNumerados;

		declare @i int = 1
		declare @fila_max int = (select MAX(fila) from #ValoresActTempOrdenados)

		declare @actividad varchar(30)
		declare @valor decimal(10,2)
		declare @fecha_vig date

		while @i <= @fila_max
		begin
			select @actividad = nombre_activ, @valor = valor, @fecha_vig = fecha_vig from #ValoresActTempOrdenados where fila = @i
			if (@actividad like 'Ajed%')
				set @actividad = 'Ajedrez'
			if exists (select 1 from eventos.Actividad where nombre = @actividad)
			begin
				update eventos.Actividad
				set costo = @valor, fecha_vigencia = @fecha_vig
				where nombre = @actividad
			end
			else
				exec eventos.InsertarActividad @actividad, @valor, @fecha_vig
			set @i += 1
		end

	end try
	BEGIN CATCH
        PRINT 'Error durante la importación: ' + ERROR_MESSAGE();
    END CATCH
end


-----------------------------------------------------------------------------------------

--sp para importar valores de membresias

go
create or alter procedure socios.importar_valores_membresia @ruta_excel NVARCHAR(260)
as
begin
	begin try
		-- 1. Tabla temporal
		IF OBJECT_ID('tempdb..#ValoresTemp') IS NOT NULL
			DROP TABLE #ValoresTemp;

		CREATE TABLE #ValoresTemp (
				nombre_memb varchar(15),
				valor decimal(10,2),
				fecha_vig date,
		);

		-- 2. Importar desde Excel
		--declare @ruta_excel NVARCHAR(260) = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx'
		DECLARE @sql NVARCHAR(MAX);
		SET @sql = '
			INSERT INTO #ValoresTemp
			SELECT *
			FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.16.0'',
				''Excel 12.0;HDR=YES; IMEX=1;Database=' + @ruta_excel + ''',
				''SELECT * FROM [Tarifas$B10:D13]''
			);';
		EXEC sp_executesql @sql;
		--select * from #ValoresTemp

		WITH ValoresNumerados AS (
		SELECT 
			ROW_NUMBER() OVER (ORDER BY nombre_memb) AS fila,
			nombre_memb,
			valor,
			fecha_vig
		FROM #ValoresTemp
		)
		SELECT * INTO #ValoresTempOrdenados FROM ValoresNumerados;
		--select * from #ValoresTempOrdenados

		declare @i int = 1
		declare @fila_max int = (select MAX(fila) from #ValoresTempOrdenados)

		declare @membresia varchar(15)
		declare @valor decimal(10,2)
		declare @fecha_vig date

		while @i <= @fila_max
		begin
			select @membresia = nombre_memb, @valor = valor, @fecha_vig = fecha_vig from #ValoresTempOrdenados where fila = @i
			if exists (select 1 from socios.Membresia where nombre = @membresia)
			begin
				update socios.Membresia
				set costo = @valor, fecha_vigencia = @fecha_vig
				where nombre = @membresia
			end
			else
				exec socios.InsertarMembresia @membresia, @valor, @fecha_vig
			set @i += 1
		end

	end try
	BEGIN CATCH
        PRINT 'Error durante la importación: ' + ERROR_MESSAGE();
    END CATCH
end


------------------------------------------------------------------------------

--sp para importar valores de acceso

go
create or alter procedure finanzas.importar_tarifas_acceso @ruta_excel varchar(260)
as
begin
	begin try
		-- 1. Tabla temporal
		IF OBJECT_ID('tempdb..#ValoresTemp') IS NOT NULL
			DROP TABLE #ValoresTemp;

		CREATE TABLE #ValoresTemp (
				concepto varchar(30),
				grupo_edad varchar(30),
				valor_socio decimal(10,2),
				valor_invit decimal(10,2),
				fecha_vig date,
			);

		-- 2. Importar desde Excel
		--declare @ruta_excel NVARCHAR(260) = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx'
		DECLARE @sql NVARCHAR(MAX);
		SET @sql = '
			INSERT INTO #ValoresTemp
			SELECT *
			FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.16.0'',
				''Excel 12.0;HDR=NO; IMEX=1;Database=' + @ruta_excel + ''',
				''SELECT * FROM [Tarifas$B17:F22]''
			);';
		EXEC sp_executesql @sql;
		--select * from #ValoresTemp

		;WITH DatosLimpios AS (
			SELECT
				ISNULL(concepto, LAG(concepto) OVER (ORDER BY fila)) AS concepto,
				grupo_edad,
				valor_socio,
				valor_invit,
				fecha_vig
			FROM (
				SELECT *,
					   ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS fila
				FROM #ValoresTemp
			) AS t
		)
		MERGE finanzas.TarifasAcceso AS destino
		USING DatosLimpios AS origen
		ON destino.concepto = origen.concepto
		   AND destino.grupo_edad = origen.grupo_edad
		   AND destino.fecha_vigencia = origen.fecha_vig
		WHEN MATCHED THEN
			UPDATE SET 
				destino.valor_socio = origen.valor_socio,
				destino.valor_invitado = origen.valor_invit
		WHEN NOT MATCHED THEN
			INSERT (concepto, grupo_edad, valor_socio, valor_invitado, fecha_vigencia)
			VALUES (origen.concepto, origen.grupo_edad, origen.valor_socio, origen.valor_invit, origen.fecha_vig);

	end try
	BEGIN CATCH
        PRINT 'Error durante la importación: ' + ERROR_MESSAGE();
    END CATCH
end


------------------------------------------------------------------------------

--sp para importar presentismo clases

go
create or alter procedure eventos.importar_presentismo_actividades (@ruta_excel NVARCHAR(260))
as
begin
	 begin try
		--Tabla temporal
		IF OBJECT_ID('tempdb..#ClaseTemp') IS NOT NULL
			DROP TABLE #ClaseTemp;

		CREATE TABLE #ClaseTemp (
				num_socio varchar(8),
				actividad varchar(30),
				fecha date,
				asistencia char(2),
				profesor varchar(50),
			)

		-- 2. Importar desde Excel
		--declare @ruta_excel NVARCHAR(260) = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx'
		DECLARE @sql NVARCHAR(MAX);
		SET @sql = '
			INSERT INTO #ClaseTemp (num_socio, actividad, fecha, asistencia, profesor)
			SELECT [Nro de Socio], [Actividad], [fecha de asistencia], [Asistencia], [Profesor]
			FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.16.0'',
				''Excel 12.0;HDR=YES; IMEX=1;Database=' + @ruta_excel + ''',
				''SELECT * FROM [presentismo_actividades$]''
			);';

		EXEC sp_executesql @sql;
		--select * from #ClaseTemp
		
		-- Normalizar numero de socio
   		UPDATE #ClaseTemp
		SET num_socio = CAST(
		SUBSTRING(CAST(num_socio AS VARCHAR(20)), 4, 
		LEN(CAST(num_socio AS VARCHAR(20)))
		) AS INT)
		WHERE CAST(num_socio AS VARCHAR(20)) LIKE 'SN-%';

		----------------------------------------------------------
		--utilizo una tabla temporal nueva con numero de fila asignado
		WITH ClasesNumeradas AS (
		SELECT 
			ROW_NUMBER() OVER (ORDER BY num_socio) AS fila,
			num_socio,
			actividad,
			fecha,
			asistencia,
			profesor
		FROM #ClaseTemp
		)
		SELECT * INTO #ClaseTempOrdenadas FROM ClasesNumeradas;
		
		--select * from #ClaseTempOrdenadas

		declare @i int = 1
		declare @fila_max int = (select max(fila) from #ClaseTempOrdenadas)
		declare @num_socio int
		declare @fecha date
		declare @asistencia char(2)
		declare @actividad varchar(30)
		declare @id_activ int
		declare @profesor varchar(50)
		declare @id_prof int

		while @i <= @fila_max
		begin
			select @num_socio = num_socio from #ClaseTempOrdenadas where fila = @i
			if exists (select 1 from socios.Socio where numero_socio = @num_socio)
			begin
				select @actividad = actividad, @profesor = profesor, @fecha = fecha, @asistencia = asistencia from #ClaseTempOrdenadas where fila = @i
				if not exists (select 1 from eventos.Profesor where nombre = @profesor)
					exec eventos.CrearProfesor @profesor
				
				if @asistencia = 'PP' 
					set @asistencia = 'P'
				if @asistencia = 'AA' 
					set @asistencia = 'A'
				if @asistencia = 'JJ' 
					set @asistencia = 'J'
				
				if not exists (select 1 from eventos.Actividad where nombre = @actividad)
					exec eventos.importar_valores_actividad @ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx'
				set @id_activ = (select id from eventos.Actividad where nombre = @actividad)
				set @id_prof = (select id from eventos.Profesor where nombre = @profesor)

				if not exists(select 1 from eventos.SocioActividad where id_socio = @num_socio and id_actividad = @id_activ)
					exec eventos.InscribirSocioActividad @num_socio, @id_activ
					
				if not exists (select 1 from eventos.Clase where id_socio = @num_socio and id_actividad = @id_activ and fecha = @fecha)
					insert into eventos.Clase values (@num_socio, @id_activ, @id_prof, @fecha, @asistencia)
			end
			else
				print 'Error. Socio ' + cast(@num_socio as varchar) + ' inexistente.'
			set @i += 1		
		end
		PRINT 'Importación finalizada correctamente.';
	end try
	BEGIN CATCH
        PRINT 'Error durante la importación: ' + ERROR_MESSAGE();
	END CATCH
end





----------------------------------------------------------------------------

-- REPORTES

----------------------------------------------------------------------------

-- INFORME 1	

-- sp para ver socios morosos en un rango de fechas
go
create or alter procedure finanzas.VerMorososPorRango (@fecha_ini date, @fecha_fin date)
as
begin

	-- socios morosos en mas de una factura
	;with FacturasVencidasMorosos as (
	select numero_socio, count(*) as facturas_vencidas
	from finanzas.Moroso m	
	join finanzas.Factura f  on f.numero_factura = m.id_factura
	group by numero_socio
	having count(*) > 0 )
	select @fecha_ini as fecha_inicial, @fecha_fin as fecha_final,fm.numero_socio, s.nombre, s.apellido, c.periodo as mes_incumplido ,dense_rank() over(order by facturas_vencidas desc) as Ranking 
	from FacturasVencidasMorosos fm
	join socios.Socio s on s.numero_socio = fm.numero_socio
	join finanzas.Cuota c on c.id_socio = fm.numero_socio 
	JOIN finanzas.Factura f ON f.id_cuota = c.id	
	where f.fecha_emision >= @fecha_ini and f.fecha_emision <= @fecha_fin and f.estado = 'Vencida 2'


end

-----------------------------------------------------------------------------------------

-- INFORME 2

go
create or alter procedure finanzas.VerAcumuladoMensualPorActividad
as
begin
	
	declare @periodo_fin varchar(8) = FORMAT(getdate(), 'MM-yyyy')
	--print @periodo_fin
	declare @periodo_ini varchar(8) = FORMAT(getdate(), '01-yyyy')
	--print @periodo_ini
	
	;with ClaseFormateada as (
		select distinct c.id_socio, c.id_actividad, c.id_profesor, FORMAT(c.fecha, 'MM-yyyy') AS periodo, a.costo as valor_activ
		from eventos.Clase c
		join eventos.Actividad a on a.id = c.id_actividad
	)
	select id_actividad, periodo, sum(valor_activ) as TotalPorMes  
	from ClaseFormateada
	group by id_actividad, periodo
	having periodo >= @periodo_ini and periodo <= @periodo_fin
	order by id_actividad, periodo

end


-----------------------------------------------------------------------------------------

-- INFORME 3

go
create or alter procedure eventos.VerInasistenciasPorCategoriaYActividad
as
begin
	
	select  m.nombre as Categoria, a.nombre as Actividad, count(*) as Cantidad_Inasistencias
	from eventos.Clase c
	join socios.Socio s on s.numero_socio = c.id_socio
	join socios.Membresia m on m.id = s.membresia_id
	join eventos.Actividad a on a.id = id_actividad
	where asistencia = 'A'
	group by m.nombre, a.nombre
	order by Cantidad_Inasistencias desc

end


-----------------------------------------------------------------------------------------

-- INFORME 4

go
create or alter procedure eventos.VerSociosSinAsistencias
as
begin
	
	select s.nombre, s.apellido, 
		DATEDIFF(YEAR, s.fecha_nac, GETDATE()) 
		- CASE 
			WHEN MONTH(s.fecha_nac) > MONTH(GETDATE()) 
				 OR (MONTH(s.fecha_nac) = MONTH(GETDATE()) AND DAY(s.fecha_nac) > DAY(GETDATE()))
			THEN 1 ELSE 0 
		  END AS edad,
		  m.nombre as categoria, a.nombre as actividad
	from (
		-- socios sin presentes
		select id_socio
		from eventos.Clase
		except
		select c.id_socio
		from eventos.Clase c
		where asistencia in ('P')) aa
	join socios.Socio s on id_socio = s.numero_socio
	join eventos.SocioActividad sa on sa.id_socio = s.numero_socio
	join socios.Membresia m on m.id = s.membresia_id
	join eventos.Actividad a on a.id = sa.id_actividad

end





----------------------------------------------------------------------------

-- SEGURIDAD

----------------------------------------------------------------------------


-- sp para cifrar el dni, email y telefono de los empleados de la tabla Socio
go
create or alter procedure socios.EncriptarDatosEmpleados
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
create or alter procedure socios.VerDesencriptaDatosEmpleados
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
create or alter procedure socios.VerDesencriptadoDatosEmpleado @dni int
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
create or alter procedure socios.InsertarEmpleadoEncriptado (@nombre varchar(50), @apellido varchar(50), @dni int, @email varchar(100), @fecha_nac date, @telefono varchar(20))
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
		exec socios.CrearUsuarioNuevo @dni, 'Administrador', @id_usuario = @usuario_id output

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
create or alter procedure socios.InsertarEmpleado (@nombre varchar(50), @apellido varchar(50), @dni int, @email varchar(100), @fecha_nac date, @telefono varchar(20))
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
		exec socios.CrearUsuarioNuevo @dni, 'Administrador', @id_usuario = @usuario_id output

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