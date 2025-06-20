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
	Zacarias, Franco Hernan (DNI 46422064)
*/

--use master
use Com5600G16
go

-- TESTING

-- Primero importaremos los datos de prueba

-- IMPORTS

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
exec sp.ImportarMeteo24
exec sp.ImportarMeteo25

select * from eventos.Clima

-- Importo membresias, actividades y tarifas de acceso
exec sp.importar_valores_membresia	@ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';
select * from socios.Membresia

exec sp.importar_valores_actividad	@ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';
select * from eventos.Actividad

exec sp.importar_tarifas_acceso		@ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';
select * from finanzas.TarifasAcceso

-- Importo socios responsables
-- No inserta el 4085 por DNI duplicado y el 4111 por fecha de nacimiento invalida

exec sp.importar_responsables_pago	@ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';
select * from socios.Socio

-- Importo menores (grupo familiar)
-- No importa 4122, 4123, 4126, 4128 y 4131 por fecha nac invalida / ser mayor de edad

exec sp.importar_grupo_familiar		@ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';
select * from socios.Socio where es_menor = 1

-- Importo pagos
-- No se importan aquellos pagos pertenecientes a socios no inscriptos

exec sp.importar_pago_cuotas		@ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';
select * from finanzas.Pago

-- Importo presentismo de las clases

exec sp.importar_presentismo_actividades	@ruta_excel = N'C:\Users\I759578\Desktop\Facu\BD II\TPI-2025-1C\Datos socios.xlsx';
select * from eventos.Clase



-- REPORTES

-- Ahora pasamos con el testing de cada reporte

-- Informe 1

-- Debemos pasarle por parametro dos fechas para utilizar de rango (fecha inicio, fecha fin)
-- Se utiliza de referencia la fecha de emision de la factura

-- Primero generamos morosos
update finanzas.Factura
set estado = 'Vencida 2'
where fecha_vencimiento_dos = '2024-01-15' and fecha_vencimiento_dos = '2024-02-16'

-- Compruebo que las facturas mencionadas ahora figuran como vencidas en segunda ocasion
select * from finanzas.Factura

exec sp.ActualizarMorosos


select m.numero_socio, m.id_factura, f.fecha_emision from finanzas.Moroso m
join finanzas.Factura f on f.numero_factura = id_factura

-- Ahora llamo al informe
exec sp.VerMorososPorRango '2024-01-01', '2024-05-01'
exec sp.VerMorososPorRango '2024-01-01', '2024-02-01'

-- O uno fuera de rango (devolvera vacio)
exec sp.VerMorososPorRango '2025-01-01', '2025-05-01'


-- Informe 2

-- Toma como fecha inicio enero del año actual (con getdate())
-- Discrimina por actividad y periodo (mes del año)

exec sp.VerAcumuladoMensualPorActividad


-- Informe 3

-- Muestra cantidad de inasistencias a clases, ordenadas de mayor a menor
-- Discrimina por categoria y actividad

exec sp.VerInasistenciasPorCategoriaYActividad


-- Informe 4

-- Muestra aquellos socios sin presentes a sus actividades asociadas

exec sp.VerSociosSinAsistencias
