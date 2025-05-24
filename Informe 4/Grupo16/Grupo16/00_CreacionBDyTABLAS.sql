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

--CREACION DE LA BASE DE DATOS

--use master
--drop database Com5600G16

--Primero creo la base de datos, luego ejecuto todo
IF NOT EXISTS (
    SELECT name FROM sys.databases WHERE name = 'Com5600G16'
)
BEGIN
    CREATE DATABASE Com5600G16;
END;

use Com5600G16
go

--CREACION DE LOS ESQUEMAS A UTILIZAR

IF NOT EXISTS (
    SELECT * FROM sys.schemas WHERE name = 'eventos'
)
BEGIN
    EXEC('CREATE SCHEMA eventos');
END;
-----------------------------------------------------------
IF NOT EXISTS (
    SELECT * FROM sys.schemas WHERE name = 'socios'
)
BEGIN
    EXEC('CREATE SCHEMA socios');
END;
-----------------------------------------------------------
IF NOT EXISTS (
    SELECT * FROM sys.schemas WHERE name = 'finanzas'
)
BEGIN
    EXEC('CREATE SCHEMA finanzas');
END;


--CREACION DE TABLAS

IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'socios' AND TABLE_NAME = 'Usuario'
)
BEGIN
    create table socios.Usuario (
		id int identity primary key,
		nombre_usuario int,
		contrasenia varchar(20),
		rol varchar(15) not null check (rol in ('Socio', 'Administrador')),
		fecha_vigencia_contra date
	);
END;
 
 --drop table socios.Usuario
------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'socios' AND TABLE_NAME = 'Membresia'
)
BEGIN
    create table socios.Membresia (
		id int identity primary key,
		nombre varchar(6) not null,
		costo float not null
	);
END;

--drop table socios.Membresia
------------------------------------------------------------------------------


IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'socios' AND TABLE_NAME = 'Socio'
)
BEGIN
    create table socios.Socio (
		numero_socio int IDENTITY PRIMARY KEY,
		nombre varchar(50) not null,
		apellido varchar(50) not null,
		dni int not null unique check (dni between 1000000 and 99999999),
		email varchar(40) not null check (email like '_%@_%._%'), --verifica que: tenga al menos un carácter antes de la @ / Tenga al menos un carácter entre la @ y el . / Tenga al menos un carácter después del .
		fecha_nac date not null check (fecha_nac >= '1900-01-01' and fecha_nac <= GETDATE()), --que sea mayor a 1900 y menor que fecha actual
		telefono varchar(20) check (telefono like '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'), --verifica que sea formato xx-xxxxxxxx
		tel_contacto varchar(20) check (tel_contacto like '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'), --verifica que sea formato xx-xxxxxxxx,
		obra_social varchar(30),
		num_carnet_obra_social varchar(30),
		activo bit not null default 1,
		es_menor bit not null default 0,
		es_responsable bit not null default 0,
		responsable_y_socio bit not null default 0,
		parentesco varchar(15),
		id_responsable int references socios.Socio(numero_socio),
		membresia_id int references socios.Membresia(id),
		usuario_id int references socios.Usuario(id),
		saldo_a_favor float default 0,
	);
END;


--drop table socios.Socio
------------------------------------------------------------------------------


IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'eventos' AND TABLE_NAME = 'Actividad'
)
BEGIN
    create table eventos.Actividad (
		id int identity primary key,
		nombre varchar(30) not null,
		costo float not null
	);
END;

------------------------------------------------------------------------------

--tabla de relacion entre socio y actividad
IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'eventos' AND TABLE_NAME = 'SocioActividad'
)
BEGIN
    CREATE TABLE eventos.SocioActividad (
        id_socio INT NOT NULL,
        id_actividad INT NOT NULL,
        PRIMARY KEY (id_socio, id_actividad),
        FOREIGN KEY (id_socio) REFERENCES socios.Socio(numero_socio),
        FOREIGN KEY (id_actividad) REFERENCES eventos.Actividad(id)
    );
END;

------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'eventos' AND TABLE_NAME = 'Invitado'
)
BEGIN
    create table eventos.Invitado (
		id int identity primary key,
		nombre varchar(50) not null,
		apellido varchar(50) not null,
		dni int not null unique check (dni between 1000000 and 99999999),
		telefono varchar(20) not null check (telefono like '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'), --verifica que sea formato xx-xxxx-xxxx
		saldo_a_favor float default 0,
	);
END;


------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'finanzas' AND TABLE_NAME = 'Cuota'
)
BEGIN
    create table finanzas.Cuota (
		id int identity,
		id_socio int,
		id_responsable int null,
		valor float not null,
		fecha date not null,
		periodo date not null,
		estado varchar(10) not null check (estado in('Pendiente', 'Pagada')),
		primary key(id, id_socio),
		foreign key (id_socio) references socios.Socio(numero_socio),
		foreign key (id_responsable) references socios.Socio(numero_socio)
	);
END;

ALTER TABLE finanzas.Cuota
ALTER COLUMN periodo VARCHAR(10);

--drop table finanzas.Cuota
------------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'eventos' AND TABLE_NAME = 'Reserva'
)
BEGIN
    create table eventos.Reserva ( --relacion
		id int identity,
		id_invitado int null,
		id_socio int not null,
		id_actividad int not null,
		fecha date not null,
		lluvia bit default 0
		primary key (id),
		foreign key (id_socio) references socios.Socio(numero_socio),
		foreign key (id_invitado) references eventos.Invitado(id),
		foreign key (id_actividad) references eventos.Actividad(id)
	);
END;

------------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'finanzas' AND TABLE_NAME = 'Factura'
)
BEGIN
    create table finanzas.Factura (
		numero_factura int identity primary key,
		id_cuota int null,
		id_socio int null,
		id_invitado int null,
		id_reserva int null,
		valor float not null,
		fecha_emision date not null,
		fecha_vencimiento date not null,
		estado varchar(10) not null check (estado in ('Pendiente', 'Pagada', 'Vencida')),
		detalle varchar(15) not null,
		--primary key(numero_factura),
		foreign key (id_cuota, id_socio) references finanzas.Cuota(id, id_socio),
		foreign key (id_invitado) references eventos.Invitado (id),
		foreign key (id_reserva) references eventos.Reserva(id)
	);
END;

------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'finanzas' AND TABLE_NAME = 'MetodoPago'
)
BEGIN
    create table finanzas.MetodoPago (
		id int identity primary key,
		nombre varchar(25) not null
	);
END;

------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'finanzas' AND TABLE_NAME = 'Pago'
)
BEGIN
    create table finanzas.Pago (
		id int identity,
		id_factura int,
		id_socio int,
		id_invitado int,
		id_cuota int,
		id_metodo_pago int,
		fecha date not null,
		valor float not null,
		es_reembolso bit default 0,
		primary key (id, id_factura, id_metodo_pago),
		foreign key (id_factura) references finanzas.Factura (numero_factura),
		foreign key (id_cuota, id_socio) references finanzas.Cuota(id, id_socio),
		foreign key (id_invitado) references eventos.Invitado (id),
		foreign key (id_metodo_pago) references finanzas.MetodoPago (id)
	);
END;


/*IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'eventos' AND TABLE_NAME = 'Reserva'
)
BEGIN
    create table eventos.Reserva ( --relacion
		id int,
		id_invitado int,
		id_socio int,
		id_factura int,
		id_cuota int null,
		fecha date not null,
		lluvia bit default 0
		primary key (id, id_invitado, id_socio),
		foreign key (id_socio) references socios.Socio(numero_socio),
		foreign key (id_invitado) references eventos.Invitado(id),
		foreign key (id_factura, id_cuota, id_socio) references finanzas.Factura(numero_factura, id_cuota, id_socio)
	);
END;
*/
------------------------------------------------------------------------------




