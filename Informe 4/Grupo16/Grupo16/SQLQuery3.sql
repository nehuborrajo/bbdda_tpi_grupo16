use Com5600G16
go

exec sp.InsertarSocio 'Nehuen', 'Borrajo', 45581523, 'nehuborrajo004@gmail.com', '04-03-2004', 1131928843, 1144752526, 'Swiss Medical', '0800-555-444'
exec sp.DesactivarSocio 45581523
exec sp.ActivarSocio 45581523
exec sp.EliminarSocio 45581523

select * from socios.Socio
select * from socios.Usuario
select * from socios.Membresia
select * from eventos.Actividad

exec sp.InsertarMembresia 'Menor', 20500
exec sp.InsertarMembresia 'Cadete', 25000
exec sp.InsertarMembresia 'Mayor', 30000

exec sp.ModificarValorMembresia 'Mayor', 31000
exec sp.EliminarMembresia 1

exec sp.InsertarActividad 'Futbol', 7000
exec sp.ModificarValorActividad 'Futbol', 8000
exec sp.EliminarActividad 1

delete from socios.Socio