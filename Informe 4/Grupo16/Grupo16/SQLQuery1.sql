/*
Enunciado
*/

--CREACION DE LA BASE DE DATOS

--use master
--drop database Com5600G16

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
		contrasenia int,
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
		activo bit default 1,
		responsable_y_socio bit default 0,
		parentesco varchar(15),
		id_familiar int references socios.Socio(numero_socio),
		membresia_id int references socios.Membresia(id),
		usuario_id int references socios.Usuario(id)
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
		telefono varchar(20) not null check (telefono like '[0-9][0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'), --verifica que sea formato xx-xxxx-xxxx
	);
END;

------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'finanzas' AND TABLE_NAME = 'Cuota'
)
BEGIN
    create table finanzas.Cuota (
		id int,
		id_socio int,
		valor float not null,
		fecha date not null,
		estado varchar(10) not null check (estado in('Pendiente', 'Pagada')),
		primary key(id, id_socio),
		foreign key (id_socio) references socios.Socio(numero_socio)
	);
END;

------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'finanzas' AND TABLE_NAME = 'Factura'
)
BEGIN
    create table finanzas.Factura (
		numero_factura int check (numero_factura like '[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
		id_cuota int,
		id_socio int,
		valor float not null,
		fecha_emision date not null,
		fecha_vencimiento date not null,
		estado varchar(10) not null check (estado in ('Pendiente', 'Pagada', 'Vencida')),
		detalle varchar(100) not null,
		primary key(numero_factura, id_cuota, id_socio),
		foreign key (id_cuota, id_socio) references finanzas.Cuota(id, id_socio)
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
		id int,
		id_factura int,
		id_socio int,
		id_cuota int,
		id_metodo_pago int,
		fecha date not null,
		valor float not null,
		primary key (id, id_factura, id_socio, id_cuota, id_metodo_pago),
		foreign key (id_factura, id_socio, id_cuota) references finanzas.Factura (numero_factura, id_cuota, id_socio),
		foreign key (id_metodo_pago) references finanzas.MetodoPago (id)
	);
END;


IF NOT EXISTS (
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

------------------------------------------------------------------------------




