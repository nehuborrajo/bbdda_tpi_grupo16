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

-----------------------------------------------------------------------------------------

-- INFORME 1	

-- sp para ver socios morosos en un rango de fechas
go
create or alter procedure sp.VerMorososPorRango (@fecha_ini date, @fecha_fin date)
as
begin

	-- socios morosos en mas de una factura
	;with FacturasVencidasMorosos as (
	select numero_socio, count(*) as facturas_vencidas
	from finanzas.Moroso m	
	join finanzas.Factura f  on f.numero_factura = m.id_factura
	group by numero_socio
	having count(*) > 0 )
	select fm.numero_socio, s.nombre, s.apellido, c.periodo, f.fecha_emision,dense_rank() over(order by facturas_vencidas desc) as Ranking 
	from FacturasVencidasMorosos fm
	join socios.Socio s on s.numero_socio = fm.numero_socio
	join finanzas.Cuota c on c.id_socio = fm.numero_socio 
	JOIN finanzas.Factura f ON f.id_cuota = c.id	
	where f.fecha_emision >= @fecha_ini and f.fecha_emision <= @fecha_fin and f.estado = 'Vencida 2'


end

-----------------------------------------------------------------------------------------

-- INFORME 2

go
create or alter procedure sp.VerAcumuladoMensualPorActividad
as
begin
	
	declare @periodo_fin varchar(8) = FORMAT(getdate(), 'MM-yyyy')
	--print @periodo_fin
	declare @periodo_ini varchar(8) = FORMAT(getdate(), '01-yyyy')
	--print @periodo_ini
	
	;with ClaseFormateada as (
		select distinct c.id_socio, c.id_actividad, c.id_profesor, FORMAT(c.fecha, 'MM-yyyy') AS periodo, a.costo as valor_activ
		from eventos.Clase c
		join eventos.Actividad a on a.id = c.id_actividad
	)
	select id_actividad, periodo, sum(valor_activ) as TotalPorMes  
	from ClaseFormateada
	group by id_actividad, periodo
	having periodo >= @periodo_ini and periodo <= @periodo_fin
	order by id_actividad, periodo

end


/*	
exec sp.VerAcumuladoMensualPorActividad
select * from eventos.Clase
*/


-----------------------------------------------------------------------------------------

-- INFORME 3

go
create or alter procedure sp.VerInasistenciasPorCategoriaYActividad
as
begin
	
	select  m.nombre as Categoria, a.nombre as Actividad, count(*) as Cantidad_Inasistencias
	from eventos.Clase c
	join socios.Socio s on s.numero_socio = c.id_socio
	join socios.Membresia m on m.id = s.membresia_id
	join eventos.Actividad a on a.id = id_actividad
	where asistencia = 'A'
	group by m.nombre, a.nombre
	order by Cantidad_Inasistencias desc

end


-----------------------------------------------------------------------------------------

-- INFORME 4

go
create or alter procedure sp.VerSociosSinAsistencias
as
begin
	
	select s.numero_socio, s.nombre, s.apellido, 
		DATEDIFF(YEAR, s.fecha_nac, GETDATE()) 
		- CASE 
			WHEN MONTH(s.fecha_nac) > MONTH(GETDATE()) 
				 OR (MONTH(s.fecha_nac) = MONTH(GETDATE()) AND DAY(s.fecha_nac) > DAY(GETDATE()))
			THEN 1 ELSE 0 
		  END AS edad,
		  m.nombre as categoria, a.nombre as actividad
	from (
		-- socios sin presentes
		select id_socio
		from eventos.Clase
		except
		select c.id_socio
		from eventos.Clase c
		where asistencia in ('P')) aa
	join socios.Socio s on id_socio = s.numero_socio
	join eventos.SocioActividad sa on sa.id_socio = s.numero_socio
	join socios.Membresia m on m.id = s.membresia_id
	join eventos.Actividad a on a.id = sa.id_actividad

end

-----------------------------------------------------------------------------------------

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
