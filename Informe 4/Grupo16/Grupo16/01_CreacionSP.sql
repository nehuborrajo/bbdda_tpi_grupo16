/*
Enunciado Informe 4:
Luego de decidirse por un motor de base de datos relacional, lleg� el momento de generar la
base de datos. En esta oportunidad utilizar�n SQL Server.
Deber� instalar el DMBS y documentar el proceso. No incluya capturas de pantalla. Detalle
las configuraciones aplicadas (ubicaci�n de archivos, memoria asignada, seguridad, puertos,
etc.) en un documento como el que le entregar�a al DBA.
Cree la base de datos, entidades y relaciones. Incluya restricciones y claves. Deber� entregar
un archivo .sql con el script completo de creaci�n (debe funcionar si se lo ejecuta �tal cual� es
entregado en una sola ejecuci�n). Incluya comentarios para indicar qu� hace cada m�dulo
de c�digo.
Genere store procedures para manejar la inserci�n, modificado, borrado (si corresponde,
tambi�n debe decidir si determinadas entidades solo admitir�n borrado l�gico) de cada tabla.
Los nombres de los store procedures NO deben comenzar con �SP�.
Algunas operaciones implicar�n store procedures que involucran varias tablas, uso de
transacciones, etc. Puede que incluso realicen ciertas operaciones mediante varios SPs.
Aseg�rense de que los comentarios que acompa�en al c�digo lo expliquen.
Genere esquemas para organizar de forma l�gica los componentes del sistema y aplique esto
en la creaci�n de objetos. NO use el esquema �dbo�.
Todos los SP creados deben estar acompa�ados de juegos de prueba. Se espera que
realicen validaciones b�sicas en los SP (p/e cantidad mayor a cero, CUIT v�lido, etc.) y que
en los juegos de prueba demuestren la correcta aplicaci�n de las validaciones.
Las pruebas deben realizarse en un script separado, donde con comentarios se indique en
cada caso el resultado esperado
El archivo .sql con el script debe incluir comentarios donde consten este enunciado, la fecha
de entrega, n�mero de grupo, nombre de la materia, nombres y DNI de los alumnos.
Entregar todo en un zip (observar las pautas para nomenclatura antes expuestas) mediante
la secci�n de pr�cticas de MIEL. Solo uno de los miembros del grupo debe hacer la entrega.

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
	-- Ajustar edad si a�n no cumpli� a�os este a�o
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
			-- Ajustar edad si a�n no cumpli� a�os este a�o
			IF (DATEADD(YEAR, @edad, @fecha_nac_menor) > GETDATE())
				SET @edad = @edad - 1;
			-- Asignar categor�a seg�n la edad
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
        RAISERROR('La membres�a especificada no existe.', 16, 1);
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
		RAISERROR('La contrase�a ingresada es invalida.', 16, 1);
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
create or alter procedure sp.GenerarFacturaCuota (@id_cuota int)
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

	SELECT 
			@id_socio = id_socio,
			@valor = valor
		FROM finanzas.Cuota
		WHERE id = @id_cuota

	set @fecha_venc = DATEADD(DAY, 5, GETDATE());

	insert into finanzas.Factura (id_cuota, id_socio, valor, fecha_emision, fecha_vencimiento, estado, detalle) values (@id_cuota, @id_socio, @valor, GETDATE(), @fecha_venc, 'Pendiente', 'Cuota')
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
			end

			set @acum = @acum_act + @acum_mem

			insert into finanzas.Cuota (id_socio, id_responsable, valor, fecha, periodo, estado) values (@id_socio, NULL, @acum, @fecha, @periodo, 'Pendiente')
			set @id_cuota = SCOPE_IDENTITY()
			exec sp.GenerarFacturaCuota @id_cuota
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
				end
			end
			else
			begin
				set @acum_act2 =  0
			end

			set @acum_mem2 = (select m.costo from socios.Membresia m where id = @id_mem)
			set @acum_mem2  *= 0.85
			set @acum2 = @acum_act2 + @acum_mem2
			

			insert into finanzas.Cuota values (@id_socio, @id_fami, @acum2, @fecha2, @periodo, 'Pendiente')		
			
			set @id_cuota = SCOPE_IDENTITY()
			exec sp.GenerarFacturaCuota @id_cuota
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
create or alter procedure sp.GenerarFacturaReserva (@id_socio int, @id_invitado int, @fecha date, @valor float, @valor_inv float, @id_reserva int)
as
begin
	declare @fecha_venc date
	SET @fecha_venc = DATEADD(DAY, 5, GETDATE());
	insert into finanzas.Factura (id_socio, id_reserva, valor, fecha_emision, fecha_vencimiento, estado, detalle) values (@id_socio, @id_reserva, @valor,GETDATE(), @fecha_venc, 'Pendiente', 'Reserva')

	if @id_invitado is not null
			insert into finanzas.Factura (id_invitado, id_reserva, valor, fecha_emision, fecha_vencimiento, estado, detalle) values (@id_invitado, @id_reserva, @valor_inv,GETDATE(), @fecha_venc, 'Pendiente', 'Reserva')

end

--SP para generar Reserva a partir dni socio, dni invitado(op), id act, fecha y si llovio (1/0)
go
create or alter procedure sp.CrearReserva (@dni_socio int, @dni_invitado int, @id_act int, @fecha date, @llovio bit)
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
	exec sp.GenerarFacturaReserva @id_socio, @id_invitado, @fecha, @valor, @valor_inv, @id_reserva
	
	
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

