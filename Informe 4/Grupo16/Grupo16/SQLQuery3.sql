--use master
use Com5600G16
go

exec sp.InsertarSocio 'Diego', 'Borrajo', 45581523, 'nehuborrajo004@gmail.com', '2004-03-04','11-31928843', '11-44752526', 'Swiss Medical', '0800-555-444'
exec sp.DesactivarSocio 45581523
exec sp.ActivarSocio 45581523
exec sp.EliminarSocio 45581523

exec sp.InsertarSocioFamiliar 'Nehuen', 'Borrajo', 45581523, 'nehuborrajo004@gmail.com', '04-03-2004','11-31928843', 'Padre', 'Avion', 'Franco', 97855903, '2015-05-31', NULL, NULL
exec sp.DesasociarResponsable 95581523

select * from socios.Socio
select * from socios.Usuario
select * from socios.Membresia
select * from eventos.Actividad

exec sp.CrearUsuarioSocio 45581523, 'Socio' --socio inactivo
exec sp.CrearUsuarioSocio 95581523, 'Socio' --socio con usuario
exec sp.CrearUsuarioSocio 45581523, 'Socio'

exec sp.ActualizarContraseniaUsuario 45581523, 'Contraseniaaaa nueva'
exec sp.EliminarUsuario 45581523

exec sp.InsertarMembresia 'Menor', 20500
exec sp.InsertarMembresia 'Cadete', 25000
exec sp.InsertarMembresia 'Mayor', 30000

exec sp.ModificarValorMembresia 'Mayor', 31000
exec sp.EliminarMembresia 1

exec sp.InsertarActividad 'Futbol', 7000
exec sp.ModificarValorActividad 'Futbol', 8000
exec sp.EliminarActividad 1

delete from socios.Socio