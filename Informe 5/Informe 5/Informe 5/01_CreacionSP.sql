/*
Enunciado Informe 5:
Archivos indicados en Miel.
Se requiere que importe toda la información antes mencionada a la base de datos:
• Genere los objetos necesarios (store procedures, funciones, etc.) para importar los
archivos antes mencionados. Tenga en cuenta que cada mes se recibirán archivos de
novedades con la misma estructura, pero datos nuevos para agregar a cada maestro.
• Considere este comportamiento al generar el código. Debe admitir la importación de
novedades periódicamente sin eliminar los datos ya cargados y sin generar
duplicados.
• Cada maestro debe importarse con un SP distinto. No se aceptarán scripts que
realicen tareas por fuera de un SP.
• La estructura/esquema de las tablas a generar será decisión suya. Puede que deba
realizar procesos de transformación sobre los maestros recibidos para adaptarlos a la
estructura requerida. Estas adaptaciones deberán hacerla en la DB y no en los
archivos provistos.
• Los archivos CSV/JSON no deben modificarse. En caso de que haya datos mal
cargados, incompletos, erróneos, etc., deberá contemplarlo y realizar las correcciones
en el fuente SQL. (Sería una excepción si el archivo está malformado y no es posible
interpretarlo como JSON o CSV, pero los hemos verificado cuidadosamente).
• Tener en cuenta que para la ampliación del software no existen datos; se deben
preparar los datos de prueba necesarios para cumplimentar los requisitos planteados.
• El código fuente no debe incluir referencias hardcodeadas a nombres o ubicaciones
de archivo. Esto debe permitirse ser provisto por parámetro en la invocación. En el
código de ejemplo el grupo decidirá dónde se ubicarían los archivos. Esto debe
aparecer en comentarios del módulo.
• El uso de SQL dinámico no está exigido en forma explícita… pero puede que
encuentre que es la única forma de resolver algunos puntos. No abuse del SQL
dinámico, deberá justificar su uso siempre.
• Respecto a los informes XML: no se espera que produzcan un archivo nuevo en el
filesystem, basta con que el resultado de la consulta sea XML.

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
create or alter procedure sp.InsertarMembresia (@nombre varchar(15), @precio float, @fecha_vig date)
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
create or alter procedure sp.InsertarActividad (@nombre varchar(30), @precio float, @fecha_vig date)
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
create or alter procedure sp.InscribirSocioActividad (@num_socio int, @id_activ int)
as
begin
	if exists (select 1 from eventos.Actividad where id = @id_activ)
	begin
		if exists (select 1 from socios.Socio where numero_socio = @num_socio and activo = 1)
		begin
			DECLARE @es_responsable BIT
			DECLARE @responsable_y_socio BIT

			SELECT 
				@es_responsable = es_responsable,
				@responsable_y_socio = responsable_y_socio
			FROM socios.Socio
			WHERE numero_socio = @num_socio;

			if @es_responsable = 0 or (@es_responsable = 1 and @responsable_y_socio = 1)
			begin
				insert into eventos.SocioActividad values (@num_socio, @id_activ)
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
create or alter procedure sp.PagoACuentasPago (@id_pago int)
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
	set reembolsado = 1
	where id = @id_pago
	print'Pago a cuentas realizado correctamente.'

end


--sp para actualizar todas las facturas en caso de vencimiento segun fecha por parametro
go
create or alter procedure sp.ActualizarFacturas (@fecha_hoy date)
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
create or alter procedure sp.ActualizarMorosos
as
begin
	delete from finanzas.Moroso

	insert into finanzas.Moroso (numero_socio, id_factura)
	select id_socio, numero_factura from finanzas.Factura where estado = 'Vencida 2'

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

/*select * from #climaTemp
select * from eventos.Clima
delete from eventos.Clima
exec sp.ImportarMeteo24
exec sp.ImportarMeteo25*/

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
CREATE OR ALTER PROCEDURE sp.importar_responsables_pago
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

		--declare @ruta_excel nvarchar(260) = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';
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

		--select * from socios.Socio
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
						exec sp.CrearUsuarioNuevo @dni, 'Responsable', @id_usuario = @usuario_id output
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

----------------------------------------------------------------------------------------------------

/*
EXEC sp.importar_responsables_pago @ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';


select * from socios.Socio where es_menor = 0
select * from socios.Socio
select * from socios.Usuario

delete from socios.Usuario
delete from socios.Socio
*/



-------------------------------------------------------------------------------------------------------------
--sp importar  grupo familiar
go
CREATE OR ALTER PROCEDURE sp.importar_grupo_familiar
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
    --declare @ruta_excel nvarchar(260) = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';
	DECLARE @sql NVARCHAR(MAX);
    SET @sql = '
        INSERT INTO #GrupoFamiliarTemp
        SELECT *
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.16.0'',
            ''Excel 12.0;HDR=YES; IMEX=1;Database=' + @ruta_excel + ''',
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
	select * FROM #GrupoFamiliarTemp WHERE fecha_nacimiento IS NULL or DATEDIFF(YEAR, fecha_nacimiento, GETDATE()) > 18;

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
				PRINT 'Insertando socio número ' + CAST(@num_socio AS VARCHAR)
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
						/*and dni BETWEEN 1000000 AND 99999999
						AND (email IS NULL OR email LIKE '_%@_%._%')
						AND fecha_nacimiento BETWEEN '1900-01-01' AND GETDATE()
						AND (telefono_contacto LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' OR telefono_contacto IS NULL)
						AND telefono_emergencia LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' or telefono_emergencia is null*/
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
/*

select * from socios.Socio
select * from socios.Socio where es_menor = 1
select * from socios.Socio where es_menor = 0
EXEC sp.importar_grupo_familiar @ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';

delete from socios.Socio where es_menor = 1
delete from socios.Socio
delete from eventos.Clase
delete from eventos.SocioActividad

*/
-----------------------------------------------------------------------------------------

--sp para generar cuotas por importacion
go
create or alter procedure sp.GenerarCuotaImportacion @num_socio int, @fecha datetime, @valor float, @id_cuota int output
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
create or alter procedure sp.GenerarFacturaCuotaImportacion @cuota_id int, @num_socio int, @valor float, @fecha datetime, @id_factura int output
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
CREATE OR ALTER PROCEDURE sp.importar_pago_cuotas
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
            valor                      float,
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
	declare @valor float
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
					exec sp.CrearMetodoPago @medio_pago_nombre
					set @medio_pago_id = (select id from finanzas.MetodoPago where nombre = @medio_pago_nombre)
				end
				
				select
					@fecha = p.fecha,
					@valor = p.valor,						
					@num_socio = p.numero_socio_resp
				from #PagosTemp p
				where numero_pago = @num_pago	

				exec sp.GenerarCuotaImportacion @num_socio, @fecha, @valor, @id_cuota = @cuota_id output
				exec sp.GenerarFacturaCuotaImportacion @cuota_id, @num_socio, @valor, @fecha, @id_factura = @factura_id output

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
/*
exec sp.importar_pago_cuotas @ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx'

select * from socios.Socio
select * from finanzas.Cuota order by id_socio
select * from finanzas.Factura
select * from finanzas.Pago

delete from socios.Socio
delete from socios.Usuario
delete from finanzas.Cuota
delete from finanzas.Factura
delete from finanzas.Pago

exec sp.importar_responsables_pago @ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios - copia.xlsx'

SELECT * FROM socios.Socio WHERE numero_socio = 4121;
DELETE FROM socios.Socio WHERE numero_socio = 4121;
*/
-----------------------------------------------------------------------------------------

--sp para importar valores de actividades

go
create or alter procedure sp.importar_valores_actividad @ruta_excel NVARCHAR(260)
as
begin
	begin try
		-- 1. Tabla temporal
		IF OBJECT_ID('tempdb..#ValoresActTemp') IS NOT NULL
			DROP TABLE #ValoresActTemp;

		CREATE TABLE #ValoresActTemp (
				nombre_activ varchar(30),
				valor float,
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
		declare @valor float
		declare @fecha_vig date

		while @i <= @fila_max
		begin
			select @actividad = nombre_activ, @valor = valor, @fecha_vig = fecha_vig from #ValoresActTempOrdenados where fila = @i
			if exists (select 1 from eventos.Actividad where nombre = @actividad)
			begin
				update eventos.Actividad
				set costo = @valor, fecha_vigencia = @fecha_vig
				where nombre = @actividad
			end
			else
				exec sp.InsertarActividad @actividad, @valor, @fecha_vig
			set @i += 1
		end

	end try
	BEGIN CATCH
        PRINT 'Error durante la importación: ' + ERROR_MESSAGE();
    END CATCH
end

------------------------------------------------------------------------------
/*
exec sp.importar_valores_actividad @ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx'
select * from eventos.Actividad
*/

-----------------------------------------------------------------------------------------

--sp para importar valores de membresias

go
create or alter procedure sp.importar_valores_membresia @ruta_excel NVARCHAR(260)
as
begin
	begin try
		-- 1. Tabla temporal
		IF OBJECT_ID('tempdb..#ValoresTemp') IS NOT NULL
			DROP TABLE #ValoresTemp;

		CREATE TABLE #ValoresTemp (
				nombre_memb varchar(15),
				valor float,
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
		declare @valor float
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
				exec sp.InsertarMembresia @membresia, @valor, @fecha_vig
			set @i += 1
		end

	end try
	BEGIN CATCH
        PRINT 'Error durante la importación: ' + ERROR_MESSAGE();
    END CATCH
end

------------------------------------------------------------------------------
/*
exec sp.importar_valores_membresia @ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx'
select * from socios.Membresia
delete from socios.Membresia
*/
------------------------------------------------------------------------------

--sp para importar valores de acceso

go
create or alter procedure sp.importar_tarifas_acceso @ruta_excel varchar(260)
as
begin
	begin try
		-- 1. Tabla temporal
		IF OBJECT_ID('tempdb..#ValoresTemp') IS NOT NULL
			DROP TABLE #ValoresTemp;

		CREATE TABLE #ValoresTemp (
				concepto varchar(30),
				grupo_edad varchar(30),
				valor_socio float,
				valor_invit float,
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
/*
exec sp.importar_tarifas_acceso @ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx'
select * from finanzas.TarifasAcceso
delete from finanzas.TarifasAcceso
*/
------------------------------------------------------------------------------

--sp para importar presentismo clases

go
create or alter procedure sp.importar_presentismo_actividades (@ruta_excel NVARCHAR(260))
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
					exec sp.CrearProfesor @profesor
				
				if @asistencia = 'PP' 
					set @asistencia = 'P'
				if @asistencia = 'AA' 
					set @asistencia = 'A'
				if @asistencia = 'JJ' 
					set @asistencia = 'J'
				
				if not exists (select 1 from eventos.Actividad where nombre = @actividad)
					exec sp.importar_valores_actividad @ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx'
				set @id_activ = (select id from eventos.Actividad where nombre = @actividad)
				set @id_prof = (select id from eventos.Profesor where nombre = @profesor)

				if not exists(select 1 from eventos.SocioActividad where id_socio = @num_socio and id_actividad = @id_activ)
					exec sp.InscribirSocioActividad @num_socio, @id_activ
					
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

-----------------------------------------------------------------------------------------
/*
exec sp.importar_presentismo_actividades @ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx'

select * from eventos.Clase
select * from eventos.Profesor
select * from eventos.Actividad

select * from eventos.SocioActividad

delete from eventos.Clase
*/