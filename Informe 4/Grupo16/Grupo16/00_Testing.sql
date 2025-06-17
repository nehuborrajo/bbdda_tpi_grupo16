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

-- TESTING

--IMPORTS

-- Importo membresias, actividades y tarifas de acceso
exec sp.importar_valores_membresia	@ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';
exec sp.importar_valores_actividad	@ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';
exec sp.importar_tarifas_acceso		@ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';

-- Importo socios responsables
exec sp.importar_responsables_pago	@ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';

-- Importo menores (grupo familiar)
exec sp.importar_grupo_familiar		@ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';

-- Importo pagos
exec sp.importar_pago_cuotas		@ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';


-- MEMBRESIAS --
--Admite (nombre, valor)
--No admite duplicados por nombre

--Primer prueba, ingresamos las 3
exec sp.InsertarMembresia 'Menor', 20500
exec sp.InsertarMembresia 'Cadete', 25000
exec sp.InsertarMembresia 'Mayor', 30000

--Al intentar ingresar una de ellas nuevamente, dira que ya existe y no se podra generar
exec sp.InsertarMembresia 'Menor', 20500

--Ahora probamos modificar sus valores
--Admite (ID y nuevo valor)
--Vamos con un llamado valido
exec sp.ModificarValorMembresia 1, 10000

--Dara error si el id no corresponde a una membresia existente o si el valor nuevo es < 1

--Ejemplo de id inexistente
exec sp.ModificarValorMembresia 4, 10000
--Ejemplo de valor < 1
exec sp.ModificarValorMembresia 1, 0

--Ahora probamos eliminarlas
--Admite (ID)
--Vamos con un llamado valido
exec sp.EliminarMembresia 1

--Dara error si el id no corresponde a una membresia existente
exec sp.EliminarMembresia 5

--Volvemos a insertar 'Menor'
exec sp.InsertarMembresia 'Menor', 20500


-- ACTIVIDADES --
--Probamos insertando actividades
--Admite (nombre, valor)
--No admite duplicado por nombre

--Primer prueba, ingresamos algunas
exec sp.InsertarActividad 'Futbol', 7000
exec sp.InsertarActividad 'Futsal', 5600
exec sp.InsertarActividad 'Pileta', 10000
exec sp.InsertarActividad 'Pileta Invitado', 15000

--Si intento ingresar una de ellas nuevamente dara error
exec sp.InsertarActividad 'Futbol', 7000

--Ahora probamos con modificar sus valores
--Admite (ID, valor)
--Vamos con un llamado valido
exec sp.ModificarValorActividad 3, 8000

--Dara error si el id no corresponde a una actividad existente o si el valor nuevo es < 1

--Ejemplo de id inexistente
exec sp.ModificarValorActividad 5, 10000
--Ejemplo de valor < 1
exec sp.ModificarValorActividad 1, 0

--Ahora probamos eliminarlas
--Admite (ID)
--Vamos con un llamado valido
exec sp.EliminarActividad 1

--Dara error si el id no corresponde a una membresia existente
exec sp.EliminarActividad 5


--Vuelvo a insertar futbol
exec sp.InsertarActividad 'Futbol', 7000


-- METODOS DE PAGO --
--Probamos insertando metodos de pago
--Admite (nombre)
--No admite duplicado por nombre
select * from finanzas.MetodoPago
--Primer prueba, ingresamos algunos
exec sp.CrearMetodoPago 'efectivo'
exec sp.CrearMetodoPago 'Visa'
exec sp.CrearMetodoPago 'MasterCard'

--Si intento ingresar una de ellos nuevamente dara error
exec sp.CrearMetodoPago 'Mercado Pago'

--Ahora probamos con modificar sus nombres
--Admite (ID, nuevo_nombre)
--Vamos con un llamado valido
exec sp.ModificarMetodoPago 1, 'Mercado Pago 2'

--Dara error si el id no corresponde a un metodo de pago existente o si enviamos un nombre vacio

--Ejemplo de ID inexistente
exec sp.ModificarMetodoPago 4, 'Mercado Pago 2'
--Ejemplo de nombre vacio
exec sp.ModificarMetodoPago 2, ' '

--Ahora probamos eliminarls
--Admite (ID)
--Vamos con un llamado valido
exec sp.EliminarMetodoPago 2

--Dara error si el id no corresponde a un metodo de pago existente
exec sp.EliminarMetodoPago 6




-- INVITADOS --
--Probamos insertando invitados
--Admite (nombre, apellido, dni, telefono)
--No admite duplicados por dni ni dni's de socios

--Primera prueba, insertamos algunos
exec sp.CrearInvitado 'Iker', 'Muniain', 95478123, '11-54781265'
exec sp.CrearInvitado 'Andres', 'Vombergar', 34561238, '11-31928843'
exec sp.CrearInvitado 'Miguel Angel', 'Russo', 15647896, '11-44752526'

--Si ingresamos un DNI nuevamente dara error (lo mismo si incluyeramos el DNI de un socio registrado)
exec sp.CrearInvitado 'Malcom', 'Braida', 15647896, '11-54896321'


--Ahora probamos eliminandolos
--Admite (dni)
--Vamos con un llamado valido
exec sp.EliminarInvitado 34561238

--Dara error si el dni no pertenece a ningun invitado registrado
exec sp.EliminarInvitado 34561238



-- SOCIOS --
--Probamos insertando socios (Inscripcion Individual)
--Admite (nombre, apellido, dni, email, fecha_nac, telefono, obra_social, num_carnet_obra_social)
--No admite duplicados dentro de la tabla socios. Si se inscribe un invitado, se borrara de la tabla Invitado

--Primera prueba, insertamos algunos
exec sp.InsertarSocio 4121, 'Nehuen', 'Borrajo', 45581523, 'nehuborrajo004@gmail.com', '2004-03-04','11-31928843', '11-31928843', 'Swiss Medical', '0800-555-444' --fecha formato 'AAAA-MM-DD'
exec sp.InsertarSocio 'Lionel', 'Messi', 32456893, 'messi@gmail.com', '1985-06-19','11-24153689', NULL, NULL, NULL --fecha formato 'AAAA-MM-DD'
exec sp.InsertarSocio 'Cristiano', 'Ronaldo', 30245789, 'cristiano@gmail.com', '1983-03-23','11-24178956', NULL, 'Galeno Oro', '0800-500-200' --fecha formato 'AAAA-MM-DD'

--Dara error si insertamos un DNI ya existente
exec sp.InsertarSocio 'Nehuen', 'Borrajo', 45581523, 'nehuborrajo004@gmail.com', '2004-03-04','11-31928843', '11-31928843', 'Swiss Medical', '0800-555-444' --fecha formato 'AAAA-MM-DD'

--Tambien verifica que la persona sea mayor de edad, por lo contario indicara que es menor y no dejara terminar la operacion
exec sp.InsertarSocio 'Thiago', 'Messi', 55689741, 'thiago@gmail.com', '2014-03-04','11-31928843', '11-31928843', NULL, NULL --fecha formato 'AAAA-MM-DD'


--A un socio se lo puede activar/desactivar (borrado logico)
--Ambos admiten (dni)

--Probemos desactivando uno
exec sp.DesactivarSocio 45581523
--Dara error si el socio ya se encuentra desactivado
exec sp.DesactivarSocio 45581523
--O si no existe
exec sp.DesactivarSocio 40000000


--Por otro lado, podemos volver a activarlos
exec sp.ActivarSocio 45581523
--Dara error si el socio ya se encuentra activo
exec sp.ActivarSocio 45581523
--O si no existe
exec sp.ActivarSocio 40000000


--Para casos de socios inactivos, se pueden llegar a eliminar (borrado fisico)
--Admite (dni)
--Se utiliza para socios recien creados, ya que con el tiempo eliminarlos puede traer problemas de integridad de datos
--No admite dni's inexistentes o dni de socios activos

--Vamos con un caso valido
exec sp.EliminarSocio 30245789

--Si probamos eliminarlo nuevamente, dara error ya que el ya dni no pertenece a un socio existente
exec sp.EliminarSocio 30245789


--Ahora iremos con las inscripciones familiares
--Admite (nombre_a, apellido_a, dni_a, email_a, fecha_nac_a, telefono_a, parentesco, nombre_m, apellido_m, dni_m, fecha_nac_m, ob_soc_m, num_ob_soc_m)
--donde _a es de adulto y _m de menor
--A la hora de anotar al menor, el email sera autocoompletando por el del responsbale, al igual que el telefono de contacto
--Veriica que la edad del menor sea realmente -18 y que no se encuentre su dni en el sistema

--Probamos insertando algunos
exec sp.InsertarSocioFamiliar 'Andrea', 'Vazquez', 26372890, 'andre@gmail.com', '1977-08-28','11-31928843', 'Madre', 'Diamela', 'Franco', 44689742, '2015-05-31', NULL, NULL
exec sp.InsertarSocioFamiliar 'Andrea', 'Vazquez', 26372890, 'andre@gmail.com', '1977-08-28','11-31928843', 'Madre', 'Andres', 'Franco', 43215698, '2015-05-31', NULL, NULL
exec sp.InsertarSocioFamiliar 'Lionel', 'Messi', 32456893, 'messi@gmail.com', '1985-06-19','11-24153689', 'Padre', 'Thiago', 'Messi', 51247896, '2015-05-31', NULL, NULL
exec sp.InsertarSocioFamiliar 'Lionel', 'Messi', 32456893, 'messi@gmail.com', '1985-06-19','11-24153689', 'Padre', 'Ciro', 'Messi', 53214875, '2015-05-31', NULL, NULL


--A los menores les activa automaticamente el campo es_menor, mientras que a los responsables el campo es_responsable
--Si el responsable ya estaba inscripto como socio, le activa el socio_y_responsable
--A los menores les agrega en el campo id_responsable el numero de socio de su responsable

--Tambien podemos asociar directamente a aquellos responsables que son solo eso
--Admite (dni)
--Vamos con un caso valido
exec sp.AsociarResponsable 26372890

--Si el DNI pertenece a alguien ya asociado dara error
exec sp.AsociarResponsable 32456893
--o si el DNI es inexistente
exec sp.AsociarResponsable 40000000

--Tambien podemos desasociar responsables (que necesitan seguir estando activos porque son responsables de otro/s menor/es)
--Admite (dni)
--Vamos con un caso valido
exec sp.DesasociarResponsable 32456893

--Si el DNI pertenece a alguien ya desasociado dara error
exec sp.DesasociarResponsable 32456893
--o si el DNI es inexistente
exec sp.DesasociarResponsable 40000000


--Tambien se pueden generar usuarios para aquellos socios que no tienen por algun motivo
--Los inscriptos se les genera uno automaticamente (nombre y contraseña = dni, la fecha de vigencia de la contraseña es de un año)
--En el caso de las inscripciones familiares, se genera usuario para el responsable unicamente
--Admite (dni, rol)

--Comencemos eliminado el usuario de algun socio
--Permite eliminar unicamente a aquellos socios inactivos
--Admite (dni)

--Vamos con un caso valido
exec sp.DesactivarSocio 45581523
exec sp.EliminarUsuario 45581523

--Dara error si el socio se encuentra activo
exec sp.EliminarUsuario 32456893
--O si es un DNI inexistente
exec sp.EliminarUsuario 40000000


--Ahora probemos creando usuario nuevo
--Verifica que sea un usuario activo que no tenga asociado un usuario

--Vamos con un caso valido
exec sp.ActivarSocio 45581523
exec sp.CrearUsuarioSocio 45581523, 'Socio'

--Dara error si el socio ya tiene usuario o esta inactivo
exec sp.CrearUsuarioSocio 45581523, 'Socio'
--O si el DNI no existe
exec sp.CrearUsuarioSocio 40000000, 'Socio'
--O si el rol es distinto de Socio o Administrador (error de CK)
exec sp.ActivarSocio 45581523
exec sp.DesactivarSocio 45581523
exec sp.EliminarUsuario 45581523
exec sp.ActivarSocio 45581523
exec sp.CrearUsuarioSocio 45581523, 'AAA'

--Por ultimo, podemos actualizar la contraseña del usuario, actualizando asi tambien un año mas su vigencia
--Admite (dni, nueva_contra)

--Vamos con un caso valido
exec sp.ActualizarContraseniaUsuario 32456893, 'MessiGoat'

--Dara error si el dni no esta asociado a ningun usuario
exec sp.ActualizarContraseniaUsuario 40000000, 'MessiGoat'
--O si la contraseña es menor a 8 digitos
exec sp.ActualizarContraseniaUsuario 32456893, 'Goat'




-- SOCIO_ACTIVIDAD --
--Ahora vamos a inscribir a los socios a actividades
--Admite (dni, id_actividad)

--Vamos con algunos casos validos
exec sp.AsociarResponsable 32456893
exec sp.ActivarSocio 45581523
exec sp.InscribirSocioActividad 45581523, 5
exec sp.InscribirSocioActividad 45581523, 2
exec sp.InscribirSocioActividad 32456893, 5

--Fallara si indicamos socios inactivos
exec sp.InscribirSocioActividad 46254589, 5
--DNIs invalidos
exec sp.InscribirSocioActividad 40000000, 5
--O si la actividad no existe
exec sp.InscribirSocioActividad 40000000, 0


--Tambien podemos eliminar un socio de una actividad
--Admite (dni, id_actividad)

--Vamos con algunos casos validos
exec sp.EliminarSocioActividad 45581523, 5

--Fallara si indicamos DNIs invalidos/inexistentes
exec sp.EliminarSocioActividad 40000000, 1
--Si el socio no realiza esa actividad
exec sp.EliminarSocioActividad 45581523, 5
--Si la actividad no existe
exec sp.EliminarSocioActividad 45581523, 0
--O si el socio no realiza ninguna actividad
exec sp.EliminarSocioActividad 26372890, 2


exec sp.InscribirSocioActividad 45581523, 5




-- RESERVAS --
--Se pueden generar reservas por parte de los socios, opcionalmente agregando invitados
--Los invitados unicamente pueden acceder a la pileta via reservas (con su precio correspondiente)
--Cada reserva genera una factura, tanto para el socio como para el invitado si lo hubiese
--Si esa jornada llovio, se suma en sus saldos_a_favor el 60% de reeintegro

--Vamos a crear unas reservas validas
--Admite (dni_socio, dni_invitado, id_actividad, fecha, llovio), donde llovio es 0=NO / 1=SI
exec sp.CrearReserva 45581523, NULL, 3, '2025-05-23', 0
exec sp.CrearReserva 45581523, 95478123, 3, '2025-05-23', 1
--Gracias a este ultimo ejemplo, se genero un pago a cuentas para el socio y el invitado, debido a que llovio

--Fallara si se indica un invitado y la actividad no es la pileta
exec sp.CrearReserva 45581523, 95478123, 4, '2025-05-23', 1
--Si el DNI no pertenece a un socio activo
exec sp.CrearReserva 46254589, 95478123, 4, '2025-05-23', 1
--O invitado existente
exec sp.CrearReserva 45581523, 9547812, 4, '2025-05-23', 1
--Si la actividad no existe
exec sp.CrearReserva 45581523, 95478123, 0, '2025-05-23', 1

--Tambien se puede eliminar una reserva por ID
--Esto eliminara las facturas generadas por dicha reserva
exec sp.EliminarReserva 1

--Fallara si el ID no pertenece a ninguna reserva existente
exec sp.EliminarReserva 1





-- CUOTAS --
--Ahora vamos con la generacion de las cuotas
--Las cuotas suman el valor de la membresia + cada actividad que realice el socio
--Respeta los descuentos mencionados en la consigna
--Admite (dni, periodo), donde el periodo tiene formayo MM-AAAA

--Vamos con unos casos validos
exec sp.GenerarCuotaSocio 45581523, '05-2025'
exec sp.GenerarCuotaSocio 32456893, '05-2025'

--Fallara si un dni es inexistente/invalido = no pertenece a socio activo
exec sp.GenerarCuotaSocio 40000000, '05-2025'
--Falla si pertenece a responsable no socio
exec sp.DesasociarResponsable 26372890
exec sp.GenerarCuotaSocio 26372890, '05-2025'
--O si ya existe una cuota generada para ese dni en ese periodo
exec sp.GenerarCuotaSocio 32456893, '05-2025'


--Tambien se pueden eliminar cuotas (idealmente el uso es para cuotas que no hayan registrado pagos)
--Admite (id_cuota)

--Probamos un caso valido
exec sp.EliminarCuota 1

--Fallara si la cuota no existe
exec sp.EliminarCuota 11

select * from finanzas.Cuota

-- FACTURAS --
--Cada cuota genera una factura asociada
--sp.GenerarFacturaCuota
--Su proposito es de uso interno en el sp.GenerarCuotaSocio, sin embargo se lo puede invocar indicando el id de la cuota

--Fallara si la cuota no existe
exec sp.GenerarFacturaCuota 111
--O si la cuota ya tiene una factura asociada
exec sp.GenerarFacturaCuota 2

--En el caso de las reservas, existe sp.GenerarFacturaReserva
--Admite (id_socio, id_invitado, fecha, valor, valor_invitado, id_reserva)
--Es llamada cuando se genera una reserva

--Tambien se puede eliminar una factura
--Admite (id_factura)
--Probamos un caso valido
exec sp.EliminarFactura 2

--Fallara si el ID no esta asociado a ninguna cuota
exec sp.EliminarFactura 0

select * from finanzas.Factura



-- PAGOS --
--Se pueden generar pagos para las facturas existente
--Pondran como 'Pagada' a la factura asociada

--Para pagos de cuota
--Admite (dni, id_factura, id_metodo_pago)
--Probamos un caso valido
exec sp.GenerarPagoFacturaCuota 45581523, 5, 3

--Dara error si el dni no pertenece a un socio existente/activo
exec sp.GenerarPagoFacturaCuota 45501523, 5, 3
--Si la factura no existe
exec sp.GenerarPagoFacturaCuota 45581523, 10, 3
--Si el metodo de pago no existe
exec sp.GenerarPagoFacturaCuota 45581523, 5, 10
--O si la factura ya se encuentra paga
exec sp.GenerarPagoFacturaCuota 45581523, 5, 3


--Luego tenemos para generar pagos de las facturas asociadas a reservas
--Admite (dni, id_factura, @id_metodo_pago)
--Probamos un caso valido
exec sp.GenerarPagoFacturaReservaSocio 45581523, 3, 3

--Puede fallar si el DNI es inexistente o socio no activo
exec sp.GenerarPagoFacturaReservaSocio 45582523, 3, 3
--Si la factura no existe
exec sp.GenerarPagoFacturaReservaSocio 45581523, 9, 3
--Si el metodo de pago no existe
exec sp.GenerarPagoFacturaReservaSocio 45581523, 3, 10
--Si la factura ya se encuentra paga
exec sp.GenerarPagoFacturaReservaSocio 45581523, 3, 3
--O si la factura no corresponde a una reserva
exec sp.GenerarPagoFacturaReservaSocio 45581523, 5, 3

--Luego ocurrira lo mismo pero con invitados
--sp.GenerarPagoFacturaReservaInvitado




-- REEMBOLSOS --
--Se pueden generar reembolsos de pagos generados
--Se los reconoce con un 1 en el campo es_reembolso (actualiza la instancia)
--Admite (id_pago)

--Vamos con un ejemplo valido
exec sp.ReembolsoPago 1

--Falla si el pago no existe
exec sp.ReembolsoPago 10
--O si el pago ya fue reembolsado
exec sp.ReembolsoPago 1

select * from finanzas.Pago



-- PAGO A CUENTAS --
--Se genera un pago a cuentas (saldo a favor)
--Acepta (id_pago) 
--Vamos con un ejemplo valido

exec sp.GenerarCuotaSocio 45581523, '05-2025'
exec sp.GenerarPagoFacturaCuota 45581523, 7, 3
exec sp.PagoACuentasPago 6

--Puede fallar si el pago no existe
exec sp.PagoACuentasPago 15
--O si ya se encuentra reembolsado
exec sp.PagoACuentasPago 6


--Actualizar valores de facturas vencidas
exec sp.ActualizarFacturas

--Desactivar socios morosos
exec sp.DesactivarSociosMorosos

exec sp.ImportarMeteo24

select * from eventos.Clima