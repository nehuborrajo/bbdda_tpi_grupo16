/*
Enunciado Informe 5:
Archivos indicados en Miel.
Se requiere que importe toda la informaci�n antes mencionada a la base de datos:
� Genere los objetos necesarios (store procedures, funciones, etc.) para importar los
archivos antes mencionados. Tenga en cuenta que cada mes se recibir�n archivos de
novedades con la misma estructura, pero datos nuevos para agregar a cada maestro.
� Considere este comportamiento al generar el c�digo. Debe admitir la importaci�n de
novedades peri�dicamente sin eliminar los datos ya cargados y sin generar
duplicados.
� Cada maestro debe importarse con un SP distinto. No se aceptar�n scripts que
realicen tareas por fuera de un SP.
� La estructura/esquema de las tablas a generar ser� decisi�n suya. Puede que deba
realizar procesos de transformaci�n sobre los maestros recibidos para adaptarlos a la
estructura requerida. Estas adaptaciones deber�n hacerla en la DB y no en los
archivos provistos.
� Los archivos CSV/JSON no deben modificarse. En caso de que haya datos mal
cargados, incompletos, err�neos, etc., deber� contemplarlo y realizar las correcciones
en el fuente SQL. (Ser�a una excepci�n si el archivo est� malformado y no es posible
interpretarlo como JSON o CSV, pero los hemos verificado cuidadosamente).
� Tener en cuenta que para la ampliaci�n del software no existen datos; se deben
preparar los datos de prueba necesarios para cumplimentar los requisitos planteados.
� El c�digo fuente no debe incluir referencias hardcodeadas a nombres o ubicaciones
de archivo. Esto debe permitirse ser provisto por par�metro en la invocaci�n. En el
c�digo de ejemplo el grupo decidir� d�nde se ubicar�an los archivos. Esto debe
aparecer en comentarios del m�dulo.
� El uso de SQL din�mico no est� exigido en forma expl�cita� pero puede que
encuentre que es la �nica forma de resolver algunos puntos. No abuse del SQL
din�mico, deber� justificar su uso siempre.
� Respecto a los informes XML: no se espera que produzcan un archivo nuevo en el
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

-- TESTING

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
exec sp.ImportarMeteo24				@ruta_excel = N'C:\TPI-2025-1C\open-meteo-buenosaires_2024.csv';
exec sp.ImportarMeteo25				@ruta_excel = N'C:\TPI-2025-1C\open-meteo-buenosaires_2025.csv';

select * from eventos.Clima

-- Importo membresias, actividades y tarifas de acceso
exec sp.importar_valores_membresia	@ruta_excel = N'C:\TPI-2025-1C\Datos socios.xlsx';
select * from socios.Membresia

exec sp.importar_valores_actividad	@ruta_excel = N'C:\TPI-2025-1C\Datos socios.xlsx';
select * from eventos.Actividad

exec sp.importar_tarifas_acceso		@ruta_excel = N'C:\TPI-2025-1C\Datos socios.xlsx';
select * from finanzas.TarifasAcceso

-- Importo socios responsables
-- No inserta el 4085 por DNI duplicado y el 4111 por fecha de nacimiento invalida

exec sp.importar_responsables_pago	@ruta_excel = N'C:\TPI-2025-1C\Datos socios.xlsx';
select * from socios.Socio

-- Importo menores (grupo familiar)
-- No importa 4122, 4123, 4126, 4128 y 4131 por fecha nac invalida / ser mayor de edad

exec sp.importar_grupo_familiar		@ruta_excel = N'C:\TPI-2025-1C\Datos socios.xlsx';
select * from socios.Socio where es_menor = 1

-- Importo pagos
-- No se importan aquellos pagos pertenecientes a socios no inscriptos

exec sp.importar_pago_cuotas		@ruta_excel = N'C:\TPI-2025-1C\Datos socios.xlsx';
select * from finanzas.Pago

-- Importo presentismo de las clases
-- Se maneja la validacion del tipo de presentismo

exec sp.importar_presentismo_actividades	@ruta_excel = N'C:\TPI-2025-1C\Datos socios.xlsx';
select * from eventos.Clase

