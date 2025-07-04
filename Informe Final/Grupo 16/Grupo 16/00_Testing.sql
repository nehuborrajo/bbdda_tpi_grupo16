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

-- TESTING


-- MEMBRESIAS --
--Admite (nombre, valor)
--No admite duplicados por nombre

--Primer prueba, ingresamos las 3
exec socios.InsertarMembresia 'Menor', 20500, '2026-06-26'
exec socios.InsertarMembresia 'Cadete', 25000, '2026-06-26'
exec socios.InsertarMembresia 'Mayor', 30000, '2026-06-26'

--Al intentar ingresar una de ellas nuevamente, dira que ya existe y no se podra generar
exec socios.InsertarMembresia 'Menor', 20500, '2026-06-26'

--Ahora probamos modificar sus valores
--Admite (ID y nuevo valor)
--Vamos con un llamado valido
exec socios.ModificarValorMembresia 1, 10000

--Dara error si el id no corresponde a una membresia existente o si el valor nuevo es < 1

--Ejemplo de id inexistente
exec socios.ModificarValorMembresia 4, 10000
--Ejemplo de valor < 1
exec socios.ModificarValorMembresia 1, 0

--Ahora probamos eliminarlas
--Admite (ID)
--Vamos con un llamado valido
exec socios.EliminarMembresia 1

--Dara error si el id no corresponde a una membresia existente
exec socios.EliminarMembresia 5

--Volvemos a insertar 'Menor'
exec socios.InsertarMembresia 'Menor', 20500, '2026-06-26'


-- ACTIVIDADES --
--Probamos insertando actividades
--Admite (nombre, valor)
--No admite duplicado por nombre

--Primer prueba, ingresamos algunas
exec eventos.InsertarActividad 'Futbol', 7000, '2026-06-26'
exec eventos.InsertarActividad 'Futsal', 5600, '2026-06-26'
exec eventos.InsertarActividad 'Pileta', 10000, '2026-06-26'
exec eventos.InsertarActividad 'Pileta Invitado', 15000, '2026-06-26'

--Si intento ingresar una de ellas nuevamente dara error
exec eventos.InsertarActividad 'Futbol', 7000, '2026-06-26'

--Ahora probamos con modificar sus valores
--Admite (ID, valor)
--Vamos con un llamado valido
exec eventos.ModificarValorActividad 3, 8000

--Dara error si el id no corresponde a una actividad existente o si el valor nuevo es < 1

--Ejemplo de id inexistente
exec eventos.ModificarValorActividad 5, 10000
--Ejemplo de valor < 1
exec eventos.ModificarValorActividad 1, 0

--Ahora probamos eliminarlas
--Admite (ID)
--Vamos con un llamado valido
exec eventos.EliminarActividad 1

--Dara error si el id no corresponde a una membresia existente
exec eventos.EliminarActividad 5


--Vuelvo a insertar futbol
exec eventos.InsertarActividad 'Futbol', 7000, '2026-06-26'


-- METODOS DE PAGO --
--Probamos insertando metodos de pago
--Admite (nombre)
--No admite duplicado por nombre
select * from finanzas.MetodoPago
--Primer prueba, ingresamos algunos
exec finanzas.CrearMetodoPago 'efectivo'
exec finanzas.CrearMetodoPago 'Visa'
exec finanzas.CrearMetodoPago 'MasterCard'

--Si intento ingresar una de ellos nuevamente dara error
exec finanzas.CrearMetodoPago 'Mercado Pago'

--Ahora probamos con modificar sus nombres
--Admite (ID, nuevo_nombre)
--Vamos con un llamado valido
exec finanzas.ModificarMetodoPago 1, 'Mercado Pago 2'

--Dara error si el id no corresponde a un metodo de pago existente o si enviamos un nombre vacio

--Ejemplo de ID inexistente
exec finanzas.ModificarMetodoPago 4, 'Mercado Pago 2'
--Ejemplo de nombre vacio
exec finanzas.ModificarMetodoPago 2, ' '

--Ahora probamos eliminarls
--Admite (ID)
--Vamos con un llamado valido
exec finanzas.EliminarMetodoPago 2

--Dara error si el id no corresponde a un metodo de pago existente
exec finanzas.EliminarMetodoPago 6




-- INVITADOS --
--Probamos insertando invitados
--Admite (nombre, apellido, dni, telefono)
--No admite duplicados por dni ni dni's de socios

--Primera prueba, insertamos algunos
exec eventos.CrearInvitado 'Iker', 'Muniain', 95478123, '11-54781265'
exec eventos.CrearInvitado 'Andres', 'Vombergar', 34561238, '11-31928843'
exec eventos.CrearInvitado 'Johan', 'Romaña', 15647896, '11-44752526'

select * from eventos.Invitado

--Si ingresamos un DNI nuevamente dara error (lo mismo si incluyeramos el DNI de un socio registrado)
exec eventos.CrearInvitado 'Malcom', 'Braida', 15647896, '11-54896321'


--Ahora probamos eliminandolos
--Admite (dni)
--Vamos con un llamado valido
exec eventos.EliminarInvitado 15647896

--Dara error si el dni no pertenece a ningun invitado registrado
exec eventos.EliminarInvitado 15647896



-- SOCIOS --
--Probamos insertando socios (Inscripcion Individual)
--Admite (nombre, apellido, dni, email, fecha_nac, telefono, obra_social, num_carnet_obra_social)
--No admite duplicados dentro de la tabla socios. Si se inscribe un invitado, se borrara de la tabla Invitado
select * from socios.Usuario
--Primera prueba, insertamos algunos
exec socios.InsertarSocio 'Nehuen', 'Borrajo', 45581523, 'nehuborrajo004@gmail.com', '2004-03-04','11-31928843', '11-31928843', 'Swiss Medical', '0800-555-444' --fecha formato 'AAAA-MM-DD'
exec socios.InsertarSocio 'Lionel', 'Messi', 32456893, 'messi@gmail.com', '1985-06-19','11-24153689', NULL, NULL, NULL --fecha formato 'AAAA-MM-DD'
exec socios.InsertarSocio 'Cristiano', 'Ronaldo', 30245789, 'cristiano@gmail.com', '1983-03-23','11-24178956', NULL, 'Galeno Oro', '0800-500-200' --fecha formato 'AAAA-MM-DD'

--Dara error si insertamos un DNI ya existente
exec socios.InsertarSocio 'Nehuen', 'Borrajo', 45581523, 'nehuborrajo004@gmail.com', '2004-03-04','11-31928843', '11-31928843', 'Swiss Medical', '0800-555-444' --fecha formato 'AAAA-MM-DD'

--Tambien verifica que la persona sea mayor de edad, por lo contario indicara que es menor y no dejara terminar la operacion
exec socios.InsertarSocio 'Thiago', 'Messi', 55689741, 'thiago@gmail.com', '2014-03-04','11-31928843', '11-31928843', NULL, NULL --fecha formato 'AAAA-MM-DD'


--A un socio se lo puede activar/desactivar (borrado logico)
--Ambos admiten (dni)

--Probemos desactivando uno
exec socios.DesactivarSocio 45581523
--Dara error si el socio ya se encuentra desactivado
exec socios.DesactivarSocio 45581523
--O si no existe
exec socios.DesactivarSocio 40000000


--Por otro lado, podemos volver a activarlos
exec socios.ActivarSocio 45581523
--Dara error si el socio ya se encuentra activo
exec socios.ActivarSocio 45581523
--O si no existe
exec socios.ActivarSocio 40000000


--Para casos de socios inactivos, se pueden llegar a eliminar (borrado fisico)
--Admite (dni)
--Se utiliza para socios recien creados, ya que con el tiempo eliminarlos puede traer problemas de integridad de datos
--No admite dni's inexistentes o dni de socios activos

--Vamos con un caso valido
exec socios.EliminarSocio 30245789

--Si probamos eliminarlo nuevamente, dara error ya que el ya dni no pertenece a un socio existente
exec socios.EliminarSocio 30245789


--Ahora iremos con las inscripciones familiares
--Admite (nombre_a, apellido_a, dni_a, email_a, fecha_nac_a, telefono_a, parentesco, nombre_m, apellido_m, dni_m, fecha_nac_m, ob_soc_m, num_ob_soc_m)
--donde _a es de adulto y _m de menor
--A la hora de anotar al menor, el email sera autocoompletando por el del responsbale, al igual que el telefono de contacto
--Veriica que la edad del menor sea realmente -18 y que no se encuentre su dni en el sistema

--Probamos insertando algunos
exec socios.InsertarSocioFamiliar 'Andrea', 'Vazquez', 26372890, 'andre@gmail.com', '1977-08-28','11-31928843', 'Madre', 'Diamela', 'Franco', 44689745, '2015-05-31', NULL, NULL
exec socios.InsertarSocioFamiliar 'Andrea', 'Vazquez', 26372890, 'andre@gmail.com', '1977-08-28','11-31928843', 'Madre', 'Andres', 'Franco', 43215698, '2015-05-31', NULL, NULL
exec socios.InsertarSocioFamiliar 'Lionel', 'Messi', 32456893, 'messi@gmail.com', '1985-06-19','11-24153689', 'Padre', 'Thiago', 'Messi', 51247896, '2015-05-31', NULL, NULL
exec socios.InsertarSocioFamiliar 'Lionel', 'Messi', 32456893, 'messi@gmail.com', '1985-06-19','11-24153689', 'Padre', 'Ciro', 'Messi', 53214875, '2015-05-31', NULL, NULL
select * from socios.Socio

--A los menores les activa automaticamente el campo es_menor, mientras que a los responsables el campo es_responsable
--Si el responsable ya estaba inscripto como socio, le activa el socio_y_responsable
--A los menores les agrega en el campo id_responsable el numero de socio de su responsable

--Tambien podemos asociar directamente a aquellos responsables que son solo eso
--Admite (dni)
--Vamos con un caso valido
exec socios.AsociarResponsable 26372890

--Si el DNI pertenece a alguien ya asociado dara error
exec socios.AsociarResponsable 32456893
--o si el DNI es inexistente
exec socios.AsociarResponsable 40000000

--Tambien podemos desasociar responsables (que necesitan seguir estando activos porque son responsables de otro/s menor/es)
--Admite (dni)
--Vamos con un caso valido
exec socios.DesasociarResponsable 26372890

--Si el DNI pertenece a alguien ya desasociado dara error
exec socios.DesasociarResponsable 26372890
--o si el DNI es inexistente
exec socios.DesasociarResponsable 40000000


--Tambien se pueden generar usuarios para aquellos socios que no tienen por algun motivo
--Los inscriptos se les genera uno automaticamente (nombre y contraseña = dni, la fecha de vigencia de la contraseña es de un año)
--En el caso de las inscripciones familiares, se genera usuario para el responsable unicamente
--Admite (dni, rol)

--Comencemos eliminado el usuario de algun socio
--Permite eliminar unicamente a aquellos socios inactivos
--Admite (dni)

--Vamos con un caso valido
exec socios.DesactivarSocio 45581523
exec socios.EliminarUsuario 45581523

--Dara error si el socio se encuentra activo
exec socios.EliminarUsuario 32456893
--O si es un DNI inexistente
exec socios.EliminarUsuario 40000000


--Ahora probemos creando usuario nuevo
--Verifica que sea un usuario activo que no tenga asociado un usuario

--Vamos con un caso valido
exec socios.ActivarSocio 45581523
exec socios.CrearUsuarioSocio 45581523, 'Socio'

--Dara error si el socio ya tiene usuario o esta inactivo
exec socios.CrearUsuarioSocio 45581523, 'Socio'
--O si el DNI no existe
exec socios.CrearUsuarioSocio 40000000, 'Socio'
--O si el rol es distinto de Socio o Administrador (error de CK)
exec socios.ActivarSocio 45581523
exec socios.DesactivarSocio 45581523
exec socios.EliminarUsuario 45581523
exec socios.ActivarSocio 45581523
exec socios.CrearUsuarioSocio 45581523, 'AAA'

--Por ultimo, podemos actualizar la contraseña del usuario, actualizando asi tambien un año mas su vigencia
--Admite (dni, nueva_contra)

--Vamos con un caso valido
exec socios.ActualizarContraseniaUsuario 32456893, 'MessiGoat'

--Dara error si el dni no esta asociado a ningun usuario
exec socios.ActualizarContraseniaUsuario 40000000, 'MessiGoat'
--O si la contraseña es menor a 8 digitos
exec socios.ActualizarContraseniaUsuario 32456893, 'Goat'




-- SOCIO_ACTIVIDAD --
--Ahora vamos a inscribir a los socios a actividades
--Admite (dni, id_actividad)

--Vamos con algunos casos validos
exec socios.AsociarResponsable 26372890
exec socios.ActivarSocio 45581523

exec eventos.InscribirSocioActividad 45581523, 5
exec eventos.InscribirSocioActividad 45581523, 2
exec eventos.InscribirSocioActividad 32456893, 5

--Fallara si indicamos socios inactivos
exec eventos.InscribirSocioActividad 46254589, 5
--DNIs invalidos
exec eventos.InscribirSocioActividad 40000000, 5
--O si la actividad no existe
exec eventos.InscribirSocioActividad 40000000, 0


--Tambien podemos eliminar un socio de una actividad
--Admite (dni, id_actividad)

--Vamos con algunos casos validos
exec eventos.EliminarSocioActividad 45581523, 5

--Fallara si indicamos DNIs invalidos/inexistentes
exec eventos.EliminarSocioActividad 40000000, 1
--Si el socio no realiza esa actividad
exec eventos.EliminarSocioActividad 45581523, 5
--Si la actividad no existe
exec eventos.EliminarSocioActividad 45581523, 0
--O si el socio no realiza ninguna actividad
exec eventos.EliminarSocioActividad 26372890, 2


exec eventos.InscribirSocioActividad 45581523, 5




-- RESERVAS --
--Se pueden generar reservas por parte de los socios, opcionalmente agregando invitados
--Los invitados unicamente pueden acceder a la pileta via reservas (con su precio correspondiente)
--Cada reserva genera una factura, tanto para el socio como para el invitado si lo hubiese
--Si esa jornada llovio, se suma en sus saldos_a_favor el 60% de reeintegro

--Vamos a crear unas reservas validas
--Admite (dni_socio, dni_invitado, id_actividad, fecha, llovio), donde llovio es 0=NO / 1=SI
exec eventos.CrearReserva 45581523, NULL, 3, '2025-05-23'
exec eventos.CrearReserva 45581523, 95478123, 3, '2025-05-23'
select * from eventos.Reserva
select * from finanzas.Factura
--Gracias a este ultimo ejemplo, se genero un pago a cuentas para el socio y el invitado, debido a que llovio

--Fallara si se indica un invitado y la actividad no es la pileta
exec eventos.CrearReserva 45581523, 95478123, 4, '2025-05-23'
--Si el DNI no pertenece a un socio activo
exec eventos.CrearReserva 46254589, 95478123, 4, '2025-05-23'
--O invitado existente
exec eventos.CrearReserva 45581523, 9547812, 4, '2025-05-23'
--Si la actividad no existe
exec eventos.CrearReserva 45581523, 95478123, 0, '2025-05-23'

--Tambien se puede eliminar una reserva por ID
--Esto eliminara las facturas generadas por dicha reserva
exec eventos.EliminarReserva 1

--Fallara si el ID no pertenece a ninguna reserva existente
exec eventos.EliminarReserva 1





-- CUOTAS --
--Ahora vamos con la generacion de las cuotas
--Las cuotas suman el valor de la membresia + cada actividad que realice el socio
--Respeta los descuentos mencionados en la consigna
--Admite (dni, periodo), donde el periodo tiene formayo MM-AAAA

--Vamos con unos casos validos
exec finanzas.GenerarCuotaSocio 45581523, '05-2025'
exec finanzas.GenerarCuotaSocio 32456893, '05-2025'

--Fallara si un dni es inexistente/invalido = no pertenece a socio activo
exec finanzas.GenerarCuotaSocio 40000000, '05-2025'
--Falla si pertenece a responsable no socio
exec socios.DesasociarResponsable 26372890
exec finanzas.GenerarCuotaSocio 26372890, '05-2025'
--O si ya existe una cuota generada para ese dni en ese periodo
exec finanzas.GenerarCuotaSocio 32456893, '05-2025'


--Tambien se pueden eliminar cuotas (idealmente el uso es para cuotas que no hayan registrado pagos)
--Admite (id_cuota)
select * from finanzas.Cuota
--Probamos un caso valido
exec finanzas.EliminarCuota 1417

--Fallara si la cuota no existe
exec finanzas.EliminarCuota 1500

select * from finanzas.Cuota

-- FACTURAS --
--Cada cuota genera una factura asociada
--sp.GenerarFacturaCuota
--Su proposito es de uso interno en el sp.GenerarCuotaSocio

--En el caso de las reservas, existe sp.GenerarFacturaReserva
--Admite (id_socio, id_invitado, fecha, valor, valor_invitado, id_reserva)
--Es llamada cuando se genera una reserva

--Tambien se puede eliminar una factura
--Admite (id_factura)
--Probamos un caso valido
exec finanzas.EliminarFactura 1438

--Fallara si el ID no esta asociado a ninguna cuota
exec finanzas.EliminarFactura 0

select * from finanzas.Factura



-- PAGOS --
--Se pueden generar pagos para las facturas existente
--Pondran como 'Pagada' a la factura asociada

--Para pagos de cuota
--Admite (dni, id_factura, id_metodo_pago)
--Probamos un caso valido
exec finanzas.GenerarPagoFacturaCuota 45581523, 5, 1

--Dara error si el dni no pertenece a un socio existente/activo
exec finanzas.GenerarPagoFacturaCuota 45501523, 5, 3
--Si la factura no existe
exec finanzas.GenerarPagoFacturaCuota 45581523, 10, 3
--Si el metodo de pago no existe
exec finanzas.GenerarPagoFacturaCuota 45581523, 5, 10
--O si la factura ya se encuentra paga
exec finanzas.GenerarPagoFacturaCuota 45581523, 5, 1


--Luego tenemos para generar pagos de las facturas asociadas a reservas
--Admite (dni, id_factura, @id_metodo_pago)
--Probamos un caso valido
exec finanzas.GenerarPagoFacturaReservaSocio 45581523, 3, 3

--Puede fallar si el DNI es inexistente o socio no activo
exec finanzas.GenerarPagoFacturaReservaSocio 45582523, 3, 3
--Si la factura no existe
exec finanzas.GenerarPagoFacturaReservaSocio 45581523, 9, 3
--Si el metodo de pago no existe
exec finanzas.GenerarPagoFacturaReservaSocio 45581523, 3, 10
--Si la factura ya se encuentra paga
exec finanzas.GenerarPagoFacturaReservaSocio 45581523, 3, 3
--O si la factura no corresponde a una reserva
exec finanzas.GenerarPagoFacturaReservaSocio 45581523, 5, 3

--Luego ocurrira lo mismo pero con invitados
--sp.GenerarPagoFacturaReservaInvitado




-- REEMBOLSOS --
--Se pueden generar reembolsos de pagos generados
--Se los reconoce con un 1 en el campo es_reembolso (actualiza la instancia)
--Admite (id_pago)

--Vamos con un ejemplo valido
exec finanzas.ReembolsoPago 1

--Falla si el pago no existe
exec finanzas.ReembolsoPago 10
--O si el pago ya fue reembolsado
exec finanzas.ReembolsoPago 1

select * from finanzas.Pago



-- PAGO A CUENTAS --
--Se genera un pago a cuentas (saldo a favor)
--Acepta (id_pago) 
--Vamos con un ejemplo valido

exec finanzas.GenerarCuotaSocio 45581523, '05-2025'
exec finanzas.GenerarPagoFacturaCuota 45581523, 7, 3
--Puede fallar si el pago no existe
exec finanzas.PagoACuentasPago 15
--O si ya se encuentra reembolsado
exec finanzas.PagoACuentasPago 6


--Actualizar valores de facturas vencidas
exec finanzas.ActualizarFacturas '2026-02-01'

--Desactivar socios morosos
exec finanzas.DesactivarSociosMorosos



----------------------------------------------------------------------------

-- IMPORTS

----------------------------------------------------------------------------

/*
Para poder usar OPENROWSET activo:
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;

Ademas tengo que instalar "https://www.microsoft.com/es-es/download/details.aspx?id=54920"

Tengo que ver que ejecutando esto 
EXEC sp_enum_oledb_providers;
Y que aparezca "Microsoft.ACE.OLEDB.12.0" y "Microsoft.ACE.OLEDB.16.0"

Luego para verificar si se me instalo el motor uso:
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.16.0', N'AllowInProcess', 1;
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.16.0', N'DynamicParameters', 1;
*/

-- Notar que en ningun caso se duplican filas al importar nuevamente

-- Importo archivos de meteorologia
exec eventos.ImportarMeteo24				@ruta_excel = N'C:\TPI-2025-1C\open-meteo-buenosaires_2024.csv';
exec eventos.ImportarMeteo25				@ruta_excel = N'C:\TPI-2025-1C\open-meteo-buenosaires_2025.csv';

select * from eventos.Clima

-- Importo membresias, actividades y tarifas de acceso
exec socios.importar_valores_membresia	@ruta_excel = N'C:\TPI-2025-1C\Datos socios.xlsx';
select * from socios.Membresia

exec eventos.importar_valores_actividad	@ruta_excel = N'C:\TPI-2025-1C\Datos socios.xlsx';
select * from eventos.Actividad

exec finanzas.importar_tarifas_acceso		@ruta_excel = N'C:\TPI-2025-1C\Datos socios.xlsx';
select * from finanzas.TarifasAcceso

-- Importo socios responsables
-- No inserta el 4085 por DNI duplicado y el 4111 por fecha de nacimiento invalida

exec socios.importar_responsables_pago	@ruta_excel = N'C:\TPI-2025-1C\Datos socios.xlsx';
select * from socios.Socio

-- Importo menores (grupo familiar)
-- No importa 4122, 4123, 4126, 4128 y 4131 por fecha nac invalida / ser mayor de edad

exec socios.importar_grupo_familiar		@ruta_excel = N'C:\TPI-2025-1C\Datos socios.xlsx';
select * from socios.Socio where es_menor = 1

-- Importo pagos
-- No se importan aquellos pagos pertenecientes a socios no inscriptos

exec finanzas.importar_pago_cuotas		@ruta_excel = N'C:\TPI-2025-1C\Datos socios.xlsx';
select * from finanzas.Pago

-- Importo presentismo de las clases
-- Se maneja la validacion del tipo de presentismo

exec eventos.importar_presentismo_actividades	@ruta_excel = N'C:\TPI-2025-1C\Datos socios.xlsx';
select * from eventos.Clase




----------------------------------------------------------------------------

-- REPORTES

----------------------------------------------------------------------------


-- Ahora pasamos con el testing de cada reporte

-- Informe 1

-- Debemos pasarle por parametro dos fechas para utilizar de rango (fecha inicio, fecha fin)
-- Se utiliza de referencia la fecha de emision de la factura

-- Primero generamos morosos
update finanzas.Factura
set estado = 'Vencida 2'
where fecha_vencimiento_dos in('2024-01-15', '2024-02-16')

-- Compruebo que las facturas mencionadas ahora figuran como vencidas en segunda ocasion
select * from finanzas.Factura

exec finanzas.ActualizarMorosos


select m.numero_socio, m.id_factura, f.fecha_emision from finanzas.Moroso m
join finanzas.Factura f on f.numero_factura = id_factura

-- Ahora llamo al informe
exec finanzas.VerMorososPorRango '2024-01-01', '2024-05-01'
exec finanzas.VerMorososPorRango '2024-01-01', '2024-02-01'

-- O uno fuera de rango (devolvera vacio)
exec finanzas.VerMorososPorRango '2025-01-01', '2025-05-01'


-- Informe 2

-- Toma como fecha inicio enero del año actual (con getdate())
-- Discrimina por actividad y periodo (mes del año)

exec finanzas.VerAcumuladoMensualPorActividad


-- Informe 3

-- Muestra cantidad de inasistencias a clases, ordenadas de mayor a menor
-- Discrimina por categoria y actividad

exec eventos.VerInasistenciasPorCategoriaYActividad


-- Informe 4

-- Muestra aquellos socios sin presentes a sus actividades asociadas

exec eventos.VerSociosSinAsistencias






----------------------------------------------------------------------------

-- SEGURIDAD

----------------------------------------------------------------------------

-- Comenzamos insertando empleados 

exec socios.InsertarEmpleado 'Lionel', 'Messi', 20156478, 'messi@gmail.com', '2020-04-03', '11-22554488'
exec socios.InsertarEmpleado 'Pipi', 'Romagnoli', 27541235, 'pipi@gmail.com', '2020-04-03', '11-33224468'

select * from socios.Socio

-- Ahora puedo encriptar los datos de todos los empleados (chequea aquellos que tienen un usuario con rol 'Administrador' --> Empleado)
-- Completara las columnas de email_cifrado, dni_cifrado y telefono_cifrado

exec socios.EncriptarDatosEmpleados

select * from socios.Socio

-- Ahora podes ver desencriptados los datos de todos los empleados

exec socios.VerDesencriptaDatosEmpleados

-- O podes verlo desencriptado por dni

exec socios.VerDesencriptadoDatosEmpleado 20156478

-- Si seleccionas un DNI no existente devuelve error

exec socios.VerDesencriptadoDatosEmpleado 30156478


-- Tambien podes directamente insertar un empleado ya cifrado

exec socios.InsertarEmpleadoEncriptado 'Nehuen', 'Borrajo', 55581523, 'nehu@gmail.com', '2020-04-03', '11-33224568'

select * from socios.Socio

