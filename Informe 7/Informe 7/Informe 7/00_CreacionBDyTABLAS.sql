/*
Enunciado Informe 6:
Reporte 1
Reporte de los socios morosos, que hayan incumplido en más de dos oportunidades dado un
rango de fechas a ingresar. El reporte debe contener los siguientes datos:
Nombre del reporte: Morosos Recurrentes
Período: rango de fechas
Nro de socio
Nombre y apellido.
Mes incumplido
Ordenados de Mayor a menor por ranking de morosidad
El mismo debe ser desarrollado utilizando Windows Function.
Reporte 2
Reporte acumulado mensual de ingresos por actividad deportiva al momento en que se saca
el reporte tomando como inicio enero.
Reporte 3
Reporte de la cantidad de socios que han realizado alguna actividad de forma alternada
(inasistencias) por categoría de socios y actividad, ordenado según cantidad de inasistencias
ordenadas de mayor a menor.
Reporte 4
Reporte que contenga a los socios que no han asistido a alguna clase de la actividad que
realizan. El reporte debe contener: Nombre, Apellido, edad, categoría y la actividad

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
		rol varchar(15) not null check (rol in ('Socio', 'Administrador', 'Responsable')),
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
		costo float not null,
		fecha_vigencia date not null
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
		numero_socio int PRIMARY KEY,
		nombre varchar(50) not null,
		apellido varchar(50) not null,
		dni int not null unique check (dni between 1000000 and 99999999),
		email varchar(100) null check (email like '_%@_%._%'), --verifica que: tenga al menos un carácter antes de la @ / Tenga al menos un carácter entre la @ y el . / Tenga al menos un carácter después del .
		fecha_nac date not null check (fecha_nac >= '1900-01-01' and fecha_nac <= GETDATE()), --que sea mayor a 1900 y menor que fecha actual
		telefono varchar(20) check (telefono like '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'), --verifica que sea formato xx-xxxxxxxx
		tel_contacto varchar(20) check (tel_contacto like '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'), --verifica que sea formato xx-xxxxxxxx,
		obra_social varchar(60),
		num_carnet_obra_social varchar(30),
		activo bit not null default 1,
		es_menor bit not null default 0,
		es_responsable bit not null default 0,
		responsable_y_socio bit not null default 0,
		es_empleado bit not null default 0,
		parentesco varchar(15),
		id_responsable int references socios.Socio(numero_socio),
		membresia_id int references socios.Membresia(id),
		usuario_id int references socios.Usuario(id),
		saldo_a_favor float default 0,
		dni_cifrado VARBINARY(256),
		email_cifrado VARBINARY(256),
		telefono_cifrado VARBINARY(256)
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
		costo float not null,
		fecha_vigencia date not null
	);
END;

------------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'eventos' AND TABLE_NAME = 'Profesor'
)
BEGIN
    create table eventos.Profesor (
		id int identity primary key,
		nombre varchar(50) not null
	);
END;

------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'finanzas' AND TABLE_NAME = 'TarifasAcceso'
)
CREATE TABLE finanzas.TarifasAcceso (
    id INT IDENTITY PRIMARY KEY,
    concepto VARCHAR(30) NOT NULL,      --'Valor del día', 'Valor de temporada', 'Valor del Mes'
    grupo_edad VARCHAR(30) NOT NULL,    -- 'Adultos', 'Menores de 12 años'
    valor_socio float NULL,				-- Socio , Invitado
    valor_invitado FLOAT null,        
    fecha_vigencia DATE NOT NULL,
);

--drop table finanzas.TarifasAcceso
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
--tabla relacion Socio-Profesor-Actividad

IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'eventos' AND TABLE_NAME = 'Clase'
)
BEGIN
    CREATE TABLE eventos.Clase (
        id_socio INT NOT NULL,
        id_actividad INT NOT NULL,
		id_profesor int not null,
		fecha date not null,
		asistencia char(2) check (asistencia in ('P', 'A', 'J')),
        PRIMARY KEY (id_socio, id_actividad, fecha),
        FOREIGN KEY (id_socio) REFERENCES socios.Socio(numero_socio),
        FOREIGN KEY (id_actividad) REFERENCES eventos.Actividad(id),
		foreign key (id_profesor) references eventos.Profesor(id)
    );
END;

--drop table eventos.Clase
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
		periodo VARCHAR(10) not null,
		estado varchar(10) not null check (estado in('Pendiente', 'Pagada')),
		primary key(id, id_socio),
		foreign key (id_socio) references socios.Socio(numero_socio),
		foreign key (id_responsable) references socios.Socio(numero_socio)
	);
END;

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
    WHERE TABLE_SCHEMA = 'eventos' AND TABLE_NAME = 'Clima'
)
BEGIN
		CREATE TABLE eventos.Clima (
		fecha_hora varchar(30) primary key not null,
		temperatura FLOAT,
		lluvia_mm FLOAT,
		humedad INT,
		viento_kmh VARCHAR(20)
		);
END;

--drop table eventos.Clima
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
		fecha_vencimiento_dos date,
		estado varchar(10) not null check (estado in ('Pendiente', 'Pagada', 'Vencida 1', 'Vencida 2')),
		detalle varchar(160) not null,
		origen varchar(15) not null,
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
		id int identity(1,1) primary key,
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
		id bigint,
		id_factura int,
		id_socio int,
		id_invitado int,
		id_cuota int,
		id_metodo_pago int,
		fecha date not null,
		valor float not null,
		reembolsado bit default 0,
		primary key (id, id_factura, id_metodo_pago),
		foreign key (id_factura) references finanzas.Factura (numero_factura),
		foreign key (id_cuota, id_socio) references finanzas.Cuota(id, id_socio),
		foreign key (id_invitado) references eventos.Invitado (id),
		foreign key (id_metodo_pago) references finanzas.MetodoPago (id)
	);
END;

------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'finanzas' AND TABLE_NAME = 'Moroso'
)
begin
	create table finanzas.Moroso (
		numero_socio int,
		id_factura int,
		primary key (numero_socio, id_factura),
		foreign key (numero_socio) references socios.Socio(numero_socio),
		foreign key (id_factura) references finanzas.Factura(numero_factura),
	);
end