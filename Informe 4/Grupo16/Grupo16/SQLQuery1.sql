/*
Enunciado
*/

--CREACION DE LA BASE DE DATOS

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
    SELECT * FROM sys.schemas WHERE name = 'eventos'
)
BEGIN
    EXEC('CREATE SCHEMA socios');
END;
-----------------------------------------------------------
IF NOT EXISTS (
    SELECT * FROM sys.schemas WHERE name = 'eventos'
)
BEGIN
    EXEC('CREATE SCHEMA finanzas');
END;


--CREACION DE TABLAS

IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'socios' AND TABLE_NAME = 'Socio'
)
BEGIN
    create table socios.Socio (
		numero_socio int IDENTITY PRIMARY KEY,
		nombre varchar(50),
		apellido varchar(50),
		dni int unique,
		email varchar(40),
		fecha_nac date,
		telefono varchar(20),
		tel_contacto varchar(20),
		obra_social varchar(30),
		num_carnet_obra_social varchar(30),
		activo bit default 1,
		responsable_socio bit default 0,
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
    WHERE TABLE_SCHEMA = 'socios' AND TABLE_NAME = 'Membresia'
)
BEGIN
    create table socios.Membresia (
		id int identity primary key,
		nombre varchar(6),
		costo float
	);
END;

--drop table socios.Membresia
------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'socios' AND TABLE_NAME = 'Usuario'
)
BEGIN
    create table socios.Usuario (
		id int identity primary key,
		nombre_usuario int,
		contrasenia int,
		rol varchar(15),
		fecha_vigencia_contra date
	);
END;
 
 --drop table socios.Usuario
------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'eventos' AND TABLE_NAME = 'Actividad'
)
BEGIN
    create table eventos.Actividad (
		id int identity primary key,
		nombre varchar(30),
		costo float
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
		nombre varchar(50),
		apellido varchar(50),
		dni int,
		telefono varchar(20)
	);
END;

------------------------------------------------------------------------------

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
		fecha date,
		lluvia bit default 0
		primary key (id, id_invitado, id_socio),
		foreign key (id_socio) references socios.Socio(numero_socio),
		foreign key (id_invitado) references eventos.Invitado(id),
		foreign key (id_factura, id_cuota, id_socio) references finanzas.Factura(numero_factura, id_cuota, id_socio)
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
		valor float,
		fecha date,
		estado varchar(10),
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
		numero_factura int,
		id_cuota int,
		id_socio int,
		valor float,
		fecha_emision date,
		fecha_vencimiento date,
		estado varchar(10),
		detalle varchar(100),
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
		nombre varchar(25)
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
		fecha date,
		valor float,
		primary key (id, id_factura, id_socio, id_cuota, id_metodo_pago),
		foreign key (id_factura, id_socio, id_cuota) references finanzas.Factura (numero_factura, id_cuota, id_socio),
		foreign key (id_metodo_pago) references finanzas.MetodoPago (id)
	);
END;



