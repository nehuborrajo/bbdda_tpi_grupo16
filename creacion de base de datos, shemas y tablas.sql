
--------------------------------------------------------------------------------
--                       CREACIÓN Y SELECCIÓN DE BASE DE DATOS
--------------------------------------------------------------------------------

CREATE DATABASE [Com5600G16];
GO
use [Com5600G16]
go

--------------------------------------------------------------------------------
--                            ESTRUCTURA DE ESQUEMAS
--------------------------------------------------------------------------------
/*
socios
 ├── Socio         -- Información de los socios registrados
 ├── Membresia     -- Detalles sobre las membresías
 └── Invitado      -- Registro de invitados asociados a socios
 └── Usuario

actividades
 └── Actividad     -- Detalles de las actividades organizadas

finanzas
 ├── Factura       -- Registro de facturación generada
 ├── Cuota         -- Información de cuotas asignadas a socios
 ├── Pago          -- Detalle de pagos realizados
 └── Metodo_Pago   -- Métodos disponibles para pagos

 eventos
 └── Evento        -- Gestión y organización de eventos realizados
 */
--------------------------------------------------------------------------------
--Organización clara y modular que facilita la gestión, seguridad y mantenimiento
---------------------------------------------------------------------------------
-- Código para crear los esquemas:

CREATE SCHEMA [socios];
GO

CREATE SCHEMA [actividades];
GO

CREATE SCHEMA [finanzas];
GO

CREATE SCHEMA [eventos];
GO
--------------------------------------------------------------------------------
-- Tabla: socios.Socio
--------------------------------------------------------------------------------
CREATE TABLE socios.Socio (
    [numero_socio] INT IDENTITY PRIMARY KEY,
    [nombre] VARCHAR(50) NOT NULL,
    [apellido] VARCHAR(50) NOT NULL,
    [dni] INT NOT NULL UNIQUE CHECK (dni BETWEEN 1000000 AND 99999999),
    [email] VARCHAR(40) NOT NULL CHECK (email LIKE '_%@_%._%'), -- validación simple de email
    [fecha_nac] DATE NOT NULL CHECK (fecha_nac >= '1900-01-01' AND fecha_nac <= GETDATE()),
    [telefono] VARCHAR(20) CHECK (telefono LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    [tel_contacto] VARCHAR(20) CHECK (tel_contacto LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    [obra_social] VARCHAR(30),
    [num_carnet_obra_social] VARCHAR(30),
    [activo] BIT DEFAULT 1,
    [responsable] BIT DEFAULT 0,
    [parentesco] VARCHAR(15),
    --id_familiar INT NULL, este no hace falta, filtras numero de socio y q parentesco este en  1 o 0             ATENCION Y ES UNICO
    membresia_id INT NULL,
    usuario_id INT NULL,
    CONSTRAINT FK_Socio_Membresia 
		FOREIGN KEY (membresia_id) REFERENCES socios.Membresia(id),
    CONSTRAINT   
		FOREIGN KEY (usuario_id) REFERENCES socios.Usuario(id)
);
--------------------------------------------------------------------------------
-- Tabla: socios.Actividad
--------------------------------------------------------------------------------
CREATE TABLE socios.Membresia (
	[id] INT IDENTITY PRIMARY KEY,
	[nombre] VARCHAR(25)  NOT NULL,
	[costo] FLOAT  NOT NULL
	);
--------------------------------------------------------------------------------
-- Tabla: socios.Usuario
--------------------------------------------------------------------------------
CREATE TABLE socios.Usuario (
	[id] INT IDENTITY PRIMARY KEY,
	[nombre_usuario] INT,
	[contrasenia] INT,
	[rol] VARCHAR(15) NOT NULL CHECK ([rol] in ('Socio', 'Administrador')),
	[fecha_vigencia_contra] date
	);
--------------------------------------------------------------------------------
-- Tabla: socios.Actividad 
--------------------------------------------------------------------------------
CREATE TABLE socios.Actividad (
    [id] INT IDENTITY PRIMARY KEY,
    [nombre] VARCHAR(50) NOT NULL,
    --[descripcion] VARCHAR(255),	   esto se me ocurrio pero tengo q reveer lo del der de mas arriba
    --[fecha_inicio] DATE NOT NULL,
    --[fecha_fin] DATE,
    [costo] DECIMAL(10, 2) NOT NULL,
);
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Tabla: socios.Socio_Actividad  (TABLA GENERADA DE REL N A N)
--------------------------------------------------------------------------------
CREATE TABLE socios.Socio_Actividad (
    [socio_id] INT NOT NULL,
    [actividad_id] INT NOT NULL,
    [fecha_inscripcion] DATE NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (socio_id, actividad_id),
    CONSTRAINT FK_Socio_Actividad_Socio 
        FOREIGN KEY (socio_id) REFERENCES socios.Socio(numero_socio),
    CONSTRAINT FK_Socio_Actividad_Actividad 
        FOREIGN KEY (actividad_id) REFERENCES socios.Actividad(id)
);
---
--------------------------------------------------------------------------------
-- Tabla: finanzas.Cuota 
--------------------------------------------------------------------------------
CREATE TABLE finanzas.Cuota (
    [id] INT IDENTITY PRIMARY KEY,
    [socio_id] INT NOT NULL,
    [monto] DECIMAL(10, 2) NOT NULL,
    [fecha_emision] DATE NOT NULL DEFAULT GETDATE(),
    [fecha_vencimiento] DATE NOT NULL,
    [fecha_pago] DATE NULL,
    [estado] VARCHAR(15) NOT NULL CHECK (estado IN ('Pendiente', 'Pagada', 'Vencida')),
    [detalle] VARCHAR(255),
    [actividad_id] INT NULL,
    [membresia_id] INT NULL,
    CONSTRAINT FK_Cuota_Socio
        FOREIGN KEY (socio_id) REFERENCES socios.Socio(numero_socio),
    CONSTRAINT FK_Cuota_Actividad
        FOREIGN KEY (actividad_id) REFERENCES socios.Actividad(id),
    CONSTRAINT FK_Cuota_Membresia
        FOREIGN KEY (membresia_id) REFERENCES socios.Membresia(id)
);
--------------------------------------------------------------------------------
-- Tabla: finanzas.Factura 
--------------------------------------------------------------------------------
CREATE TABLE finanzas.Factura (
    ID_Factura SERIAL PRIMARY KEY, -- Identificador único de la factura
    Fecha_Generacion DATE NOT NULL DEFAULT CURRENT_DATE, -- Fecha en la que se generó la factura
    Fecha_Vencimiento DATE NOT NULL, -- Fecha límite para el pago
    Monto_Total DECIMAL(10, 2) NOT NULL, -- Monto total a pagar
    Estado VARCHAR(20) NOT NULL CHECK (Estado IN ('Pagada', 'Pendiente', 'Anulada')), -- Estado de la factura
    ID_Cuota INT, -- Relación con Cuota (opcional)
    ID_Pago INT, -- Relación con Pago (opcional)
    ID_Reserva INT, -- Relación con Reserva (opcional)
    FOREIGN KEY (ID_Cuota) REFERENCES finanzas.Cuota(ID_Cuota), -- Relación con Cuota
    FOREIGN KEY (ID_Pago) REFERENCES finanzas.Pago(ID_Pago), -- Relación con Pago
    FOREIGN KEY (ID_Reserva) REFERENCES actividades.Reserva(ID_Reserva) -- Relación con Reserva
);
--Factura: N a 1 (un pago pertenece a una única factura).
--------------------------------------------------------------------------------
-- Tabla: finanzas.invitado tengo dudas aqui quen de las 3 entidades se lleva la pk y si queda asi 
---------------------------------------------------------------------------------
CREATE TABLE invitado (
    ID_Socio INT NOT NULL, -- Relación con la tabla Socio
    ID_Factura INT NOT NULL, -- Relación con la tabla Factura
    ID_Invitado INT NOT NULL, -- Relación con la tabla Invitado
    Uso_Pileta BOOLEAN NOT NULL DEFAULT FALSE, -- Indica si el invitado usó la pileta
    Llovio BOOLEAN NOT NULL DEFAULT FALSE, -- Indica si hubo lluvia para aplicar un descuento
    PRIMARY KEY (ID_Socio, ID_Factura, ID_Invitado), -- Clave primaria compuesta
    FOREIGN KEY (ID_Socio) REFERENCES socios.Socio(ID_Socio), -- Clave foránea hacia Socio
    FOREIGN KEY (ID_Factura) REFERENCES finanzas.Factura(ID_Factura), -- Clave foránea hacia Factura
    FOREIGN KEY (ID_Invitado) REFERENCES socios.Invitado(ID_Invitado) -- Clave foránea hacia Invitado
);
---------------------------------------------------------------------------------