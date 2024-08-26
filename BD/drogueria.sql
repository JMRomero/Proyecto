-- phpMyAdmin SQL Dump
-- version 5.1.3
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 26-08-2024 a las 17:40:11
-- Versión del servidor: 10.4.24-MariaDB
-- Versión de PHP: 7.4.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `drogueria`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `Borrar_producto_venta` (IN `idVenta` INT, IN `Posicion` INT)   begin  
declare cantidad_lotes int;
declare cantidad_vendida int;
declare LOTE_ID varchar(15);
declare TotalV int;
SELECT COUNT(id_Lote) into cantidad_lotes from detalle_venta where PosicionTabla=Posicion and id_venta=idVenta;
repetir:loop
select Cantidad,id_Lote,TotalProducto into cantidad_vendida,LOTE_ID,TotalV from detalle_venta where PosicionTabla=Posicion and id_venta=idVenta limit 1;
update lote set Cantidad=Cantidad+cantidad_vendida where Loteid=LOTE_ID;
Update venta set TotalCompra=TotalCompra-TotalV where id_venta=idVenta;
delete from detalle_venta WHERE id_lote=LOTE_ID and id_venta=idVenta and PosicionTabla=Posicion;
set cantidad_lotes=cantidad_lotes-1;
if cantidad_lotes=0 THEN
leave repetir;
end if;
end loop repetir;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `calcularHoras` (IN `usuario` VARCHAR(150))   insert into horas_trabajadas (usuario,fecha,horas)values(usuario,now(),(select timestampdiff(second,hora_login,hora_logout) from auth_user where username=usuario))$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Cancelar_venta` (IN `idVenta` INT)   begin  
declare cantidad_lotes int;
declare cantidad_vendida int;
declare LOTE_ID varchar(15);
declare TotalV int;
SELECT COUNT(id_Lote) into cantidad_lotes from detalle_venta where id_venta=idVenta;
repetir:loop
select Cantidad,id_Lote,TotalProducto into cantidad_vendida,LOTE_ID,TotalV from detalle_venta where id_venta=idVenta limit 1;
update lote set Cantidad=Cantidad+cantidad_vendida where Loteid=LOTE_ID;
Update venta set TotalCompra=TotalCompra-TotalV where id_venta=idVenta;
delete from detalle_venta WHERE id_lote=LOTE_ID and id_venta=idVenta;
set cantidad_lotes=cantidad_lotes-1;
if cantidad_lotes=0 THEN
leave repetir;
end if;
end loop repetir;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Datos_producto` (IN `codigo` BIGINT)   BEGIN
select Nombre,GramoLitro,(select precioV from lote where id_producto=codigo and estado=True order by MAX(timestampdiff(hour, fechaCreate,now())))AS precio,(select sum(Cantidad) from lote where id_producto=codigo and estado=True)AS cantidad,estado from producto where id_producto=codigo; 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Delete_Temp` ()   begin 
DELETE FROM temp_proveedor;
DELETE FROM temp_producto;
DELETE FROM temp_lote;
DELETE FROM temp_compra;
DELETE FROM temp_detalle_compra;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Desactivar_Vencidos` ()   begin
update lote set estado=False where timestampdiff(day,now(),fechaVenci)<=0; end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Dias_Venta` ()   BEGIN
WITH UniqueDetalle AS (
    SELECT DISTINCT posiciontabla, id_venta
    FROM detalle_venta
)
SELECT v.fecha,(Select COUNT(id_venta) from venta where Fecha=v.Fecha) as facturas, COUNT(ud.id_venta) AS num_registros,format((select sum(TotalCompra) from venta where Fecha=v.Fecha),"###.###.###.###") as total
FROM venta v
JOIN UniqueDetalle ud ON v.id_venta = ud.id_venta
where v.Efectivo_Recibido>0
GROUP BY v.fecha
ORDER BY v.fecha;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Lotes_vencer` ()   BEGIN
select Lote.Loteid,Lote.id_producto,Producto.nombre,proveedor.Nombre from Lote inner join Producto on Lote.id_producto=Producto.id_producto inner join detalle_compra on lote.Loteid=detalle_compra.Lote inner join compra on detalle_compra.id_compra=compra.id_compra INNER join proveedor on compra.NIT=proveedor.NIT where TIMESTAMPDIFF(month, NOW(), fechaVenci)<proveedor.Politica_Devolucion and TIMESTAMPDIFF(DAY, NOW(), fechaVenci)>0;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Lotes_vencidos` ()   begin
select Lote.Loteid,Lote.id_producto,Producto.nombre,proveedor.Nombre from Lote inner join Producto on Lote.id_producto=Producto.id_producto inner join detalle_compra on lote.Loteid=detalle_compra.Lote inner join compra on detalle_compra.id_compra=compra.id_compra INNER join proveedor on compra.NIT=proveedor.NIT where TIMESTAMPDIFF(DAY, NOW(), fechaVenci)<=0;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `precioAnterior` (IN `idP` INT)   begin 
select case when(select count(Loteid) from lote where id_producto=idP)>0 then (SELECT precioV from lote where id_producto=idP order by fechaCreate limit 1)else 0 end;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `productoCmes` (IN `fechas` DATE)   select SUM(dc.CantidadProductos) as cantidad,p.Nombre from compra as c INNER join detalle_compra as dc on c.id_compra=dc.id_compra INNER join lote as l on l.Loteid=dc.Lote INNER join producto as p on p.id_producto=l.id_producto where MONTH(c.Fecha_Llegada)=MONTH(fechas) group by p.Nombre order by cantidad desc limit 3$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `productoCsem` (IN `yearSelect` INT, IN `weekSelect` INT, IN `fechas` DATE)   begin 
if yearSelect=0 or weekSelect=0 THEN
select SUM(dc.CantidadProductos) as cantidad, p.Nombre from compra as c INNER join detalle_compra as dc on c.id_compra=dc.id_compra INNER join lote as l on l.Loteid=dc.Lote INNER join producto as p on p.id_producto=l.id_producto where WEEK(c.Fecha_Llegada, 1) = WEEK(CURDATE(), 1) AND YEAR(c.Fecha_Llegada) = YEAR(fechas) group by p.Nombre order by cantidad desc limit 3;
ELSE
select SUM(dc.CantidadProductos) as cantidad, p.Nombre from compra as c INNER join detalle_compra as dc on c.id_compra=dc.id_compra INNER join lote as l on l.Loteid=dc.Lote INNER join producto as p on p.id_producto=l.id_producto where WEEK(c.Fecha_Llegada, 1) =weekSelect AND YEAR(c.Fecha_Llegada) =yearSelect group by p.Nombre order by cantidad desc limit 3; 
end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `productoVmes` (IN `fechas` DATE)   BEGIN
select SUM(dv.Cantidad) as cantidad, p.Nombre from venta as v INNER join detalle_venta as dv on v.id_venta=dv.id_venta INNER join lote as l on l.Loteid=dv.id_Lote INNER join producto as p on p.id_producto=l.id_producto where MONTH(v.Fecha)= month(fechas) group by p.nombre order by cantidad desc limit 3;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `productoVsem` (IN `yearSelect` INT, IN `weekSelect` INT, IN `fechas` DATE)   BEGIN
if yearSelect=0 or weekSelect=0 THEN
select SUM(dv.Cantidad) as cantidad, p.Nombre from venta as v INNER join detalle_venta as dv on v.id_venta=dv.id_venta INNER join lote as l on l.Loteid=dv.id_Lote INNER join producto as p on p.id_producto=l.id_producto where WEEK(v.Fecha, 1) = WEEK(fechas,1) AND YEAR(v.Fecha) = year(fechas) GROUP BY p.nombre order by cantidad desc limit 3;
else
select SUM(dv.Cantidad) as cantidad, p.Nombre from venta as v INNER join detalle_venta as dv on v.id_venta=dv.id_venta INNER join lote as l on l.Loteid=dv.id_Lote INNER join producto as p on p.id_producto=l.id_producto where WEEK(v.Fecha, 1) = weekSelect AND YEAR(v.Fecha) = yearSelect GROUP BY p.nombre order by cantidad desc limit 3;
end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Producto_cero` ()   select nombre from producto where CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End=0 and Estado=True and rotacion="Normal"$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Producto_min` ()   select nombre from producto where CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End<Min and CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End>0 and estado=1 and rotacion="Normal"$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `User_group` (IN `cedula` INT(10), IN `idG` INT(10), IN `telefono` VARCHAR(10), IN `fecha` DATE, IN `direccion` VARCHAR(150))   begin 
INSERT INTO auth_user_groups (user_id,group_id) values((select id from auth_user where username=cedula),idG);
update auth_user set Telefono=telefono, fechaNacimiento=fecha,Direccion=direccion where username=cedula;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Usuarios+trabajados` (IN `semana` TINYINT, IN `fechas` DATE)   BEGIN
if semana then 
SELECT usuario, month(fechas) as mes, year(fechas) as año,sec_to_time(sum(horas)) as total_horas FROM horas_trabajadas where week(fecha)=week(fechas) and month(fecha)=month(fechas) GROUP by usuario, week(fecha,1) ORDER BY week(fechas) DESC LIMIT 3;
ELSE
SELECT usuario,month(fechas) as mes, year(fechas) as año,sec_to_time(sum(horas)) as total_horas FROM horas_trabajadas where month(fecha)=month(fechas) GROUP by usuario, month(fechas), YEAR(fechas) ORDER BY mes, total_horas DESC LIMIT 3;
end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Venta_id` (IN `cedula_usuario` INT)   BEGIN
declare id int;
declare total int;
select MAX(id_venta) into id from venta;
select TotalCompra into total from venta where id_venta=id;
if total=0 THEN
select id;
ELSE 
insert into venta (TotalCompra,Fecha,Hora,Efectivo_Recibido,Efectivo_Entregado,Cedula) VALUES(0,Now(),Now(),0,0,cedula_usuario);
select MAX(id_venta) from venta;
end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Venta_Registo` (IN `codigo` BIGINT(20), IN `cantidadregistrar` INT, IN `Posicion` INT)   BEGIN
declare idVenta int;
declare loteIDD varchar(15);
declare cantidadLOTE int;
declare precioLOTE int;
declare TotalV int;
declare TotalVT int;
declare restante int;
set TotalV=0;
set TotalVT=0;
set idVenta=(select MAX(id_venta) from venta);
repetir:LOOP
select Cantidad,Loteid,precioV into cantidadLOTE,loteIDD,precioLOTE from lote where id_producto=codigo and Estado=True and Cantidad>0 order by max(timestampdiff(day,fechaCreate,now()));
if cantidadLOTE<cantidadregistrar THEN
set TotalV= TotalV+(cantidadLOTE*precioLOTE);
update lote set Cantidad=0 where Loteid=loteIDD;
insert into detalle_venta values (loteIDD,precioLOTE,TotalV,cantidadLOTE,Posicion,idVenta);
set cantidadregistrar= cantidadregistrar-cantidadLote;
set TotalVT =TotalV+TotalVT;
set TotalV=0;
else 
set TotalV= TotalV+(cantidadregistrar*precioLOTE);
set restante = cantidadLOTE-cantidadregistrar;
update lote set Cantidad=restante where Loteid=loteIDD;
insert into detalle_venta values (loteIDD,precioLOTE,TotalV,cantidadregistrar,Posicion,idVenta);
set TotalVT =TotalV+TotalVT;
leave repetir;
end if;
end LOOP repetir;
SELECT TotalVT,Posicion;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auth_group`
--

CREATE TABLE `auth_group` (
  `id` int(11) NOT NULL,
  `name` varchar(150) COLLATE utf8_spanish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `auth_group`
--

INSERT INTO `auth_group` (`id`, `name`) VALUES
(2, 'Admin'),
(1, 'Regente');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auth_group_permissions`
--

CREATE TABLE `auth_group_permissions` (
  `id` bigint(20) NOT NULL,
  `group_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `auth_group_permissions`
--

INSERT INTO `auth_group_permissions` (`id`, `group_id`, `permission_id`) VALUES
(1, 1, 4);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auth_permission`
--

CREATE TABLE `auth_permission` (
  `id` int(11) NOT NULL,
  `name` varchar(255) COLLATE utf8_spanish_ci NOT NULL,
  `content_type_id` int(11) NOT NULL,
  `codename` varchar(100) COLLATE utf8_spanish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `auth_permission`
--

INSERT INTO `auth_permission` (`id`, `name`, `content_type_id`, `codename`) VALUES
(1, 'Can add producto', 1, 'add_producto'),
(2, 'Can change producto', 1, 'change_producto'),
(3, 'Can delete producto', 1, 'delete_producto'),
(4, 'Can view producto', 1, 'view_producto'),
(5, 'Can add vencimiento', 2, 'add_vencimiento'),
(6, 'Can change vencimiento', 2, 'change_vencimiento'),
(7, 'Can delete vencimiento', 2, 'delete_vencimiento'),
(8, 'Can view vencimiento', 2, 'view_vencimiento'),
(9, 'Can add log entry', 3, 'add_logentry'),
(10, 'Can change log entry', 3, 'change_logentry'),
(11, 'Can delete log entry', 3, 'delete_logentry'),
(12, 'Can view log entry', 3, 'view_logentry'),
(13, 'Can add permission', 4, 'add_permission'),
(14, 'Can change permission', 4, 'change_permission'),
(15, 'Can delete permission', 4, 'delete_permission'),
(16, 'Can view permission', 4, 'view_permission'),
(17, 'Can add group', 5, 'add_group'),
(18, 'Can change group', 5, 'change_group'),
(19, 'Can delete group', 5, 'delete_group'),
(20, 'Can view group', 5, 'view_group'),
(21, 'Can add user', 6, 'add_user'),
(22, 'Can change user', 6, 'change_user'),
(23, 'Can delete user', 6, 'delete_user'),
(24, 'Can view user', 6, 'view_user'),
(25, 'Can add content type', 7, 'add_contenttype'),
(26, 'Can change content type', 7, 'change_contenttype'),
(27, 'Can delete content type', 7, 'delete_contenttype'),
(28, 'Can view content type', 7, 'view_contenttype'),
(29, 'Can add session', 8, 'add_session'),
(30, 'Can change session', 8, 'change_session'),
(31, 'Can delete session', 8, 'delete_session'),
(32, 'Can view session', 8, 'view_session');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auth_user`
--

CREATE TABLE `auth_user` (
  `id` int(11) NOT NULL,
  `password` varchar(128) COLLATE utf8_spanish_ci NOT NULL,
  `last_login` datetime(6) DEFAULT NULL,
  `is_superuser` tinyint(1) NOT NULL DEFAULT 0,
  `username` varchar(150) COLLATE utf8_spanish_ci NOT NULL,
  `first_name` varchar(150) COLLATE utf8_spanish_ci NOT NULL,
  `last_name` varchar(150) COLLATE utf8_spanish_ci NOT NULL,
  `email` varchar(254) COLLATE utf8_spanish_ci NOT NULL,
  `is_staff` tinyint(1) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `date_joined` datetime(6) NOT NULL,
  `fechaNacimiento` date NOT NULL,
  `Direccion` varchar(250) COLLATE utf8_spanish_ci NOT NULL DEFAULT '',
  `Telefono` varchar(10) COLLATE utf8_spanish_ci NOT NULL DEFAULT '',
  `hora_login` datetime DEFAULT NULL,
  `hora_logout` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `auth_user`
--

INSERT INTO `auth_user` (`id`, `password`, `last_login`, `is_superuser`, `username`, `first_name`, `last_name`, `email`, `is_staff`, `is_active`, `date_joined`, `fechaNacimiento`, `Direccion`, `Telefono`, `hora_login`, `hora_logout`) VALUES
(3, 'pbkdf2_sha256$720000$NjhwZWuCcQz0RODIC3ZBT5$fDnsKWR42Cp0pq0Rb2G/vEjeQ3KXXhw3tzT6OWGEj04=', '2024-08-26 11:28:04.337749', 0, '1017924962', 'jose', 'romero', 'rjosemiguel787@gmail.com', 0, 1, '2023-11-17 06:36:00.000000', '2005-05-05', 'CL 112 81-74', '3046803586', '2024-08-26 06:28:04', '2024-08-20 10:49:51'),
(15, 'pbkdf2_sha256$720000$IrvJ9SuMxGICLRBxmXvLsD$oI5aKDExIn0MhTcU1700Z1KQu/RseMTnwtW0RBiw8tE=', '2024-08-20 15:49:55.139006', 0, '1025644878', 'Juan', 'Guerra', 'juanpguerra14@gmail.com', 0, 1, '2024-07-17 15:32:02.856608', '2000-08-22', 'cll23', '3144698932', '2024-08-20 10:49:55', '2024-08-12 07:00:09');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auth_user_groups`
--

CREATE TABLE `auth_user_groups` (
  `id` bigint(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `auth_user_groups`
--

INSERT INTO `auth_user_groups` (`id`, `user_id`, `group_id`) VALUES
(2, 3, 2),
(10, 15, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auth_user_user_permissions`
--

CREATE TABLE `auth_user_user_permissions` (
  `id` bigint(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `caja`
--

CREATE TABLE `caja` (
  `id` int(11) NOT NULL,
  `dinero` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `caja`
--

INSERT INTO `caja` (`id`, `dinero`) VALUES
(1, -3375345950);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compra`
--

CREATE TABLE `compra` (
  `id_compra` int(11) NOT NULL,
  `Total` int(11) DEFAULT NULL,
  `Fecha_Llegada` datetime DEFAULT NULL,
  `NIT` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `compra`
--

INSERT INTO `compra` (`id_compra`, `Total`, `Fecha_Llegada`, `NIT`) VALUES
(1, 6500, '2024-07-21 23:08:25', 12121212),
(2, 41890, '2024-07-21 23:10:04', 12121212),
(3, 25890, '2024-07-21 23:19:11', 12121212),
(4, 20022, '2024-07-21 23:34:04', 12121212),
(5, 91500, '2024-08-12 07:18:31', 12121212),
(6, 60000, '2024-08-12 08:54:09', 12121212),
(7, 10000, '2024-08-12 11:34:04', 12121212),
(8, 27890, '2024-08-26 06:28:21', 12121212),
(9, 100800, '2024-08-26 07:36:45', 2147483647),
(10, 58901, '2024-08-26 07:43:38', 12121212);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_compra`
--

CREATE TABLE `detalle_compra` (
  `Lote` varchar(15) DEFAULT NULL,
  `Precio` int(11) NOT NULL,
  `procentaje` int(11) NOT NULL,
  `PrecioU` int(11) NOT NULL,
  `CantidadProductos` int(11) NOT NULL,
  `id_compra` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `detalle_compra`
--

INSERT INTO `detalle_compra` (`Lote`, `Precio`, `procentaje`, `PrecioU`, `CantidadProductos`, `id_compra`) VALUES
('qqqqqqq', 6500, 0, 100, 300, 1),
('wwwwwwwww', 26890, 0, 70, 300, 2),
('eeeeeee', 15000, 0, 100, 300, 2),
('rrrrrrrrr', 25890, 70, 150, 300, 3),
('yyyyyy', 20000, 100, 150, 300, 4),
('yyyyyy', 22, 22, 200, 2, 4),
('888asas', 34500, 70, 2000, 30, 5),
('nnnnasasa', 57000, 75, 1700, 60, 5),
('jksajsa', 60000, 60, 3200, 30, 6),
('jjajsaj', 10000, 100, 2000, 10, 7),
('UJJS', 27890, 65, 1550, 30, 8),
('Ibu9922', 45000, 100, 300, 300, 9),
('JJJ8987', 27910, 78, 1700, 30, 9),
('JKSNa8989', 27890, 100, 200, 300, 9),
('NSJAS990', 58901, 70, 3350, 30, 10);

--
-- Disparadores `detalle_compra`
--
DELIMITER $$
CREATE TRIGGER `TotalCompra` AFTER INSERT ON `detalle_compra` FOR EACH ROW begin
declare sum int;
declare precioa int;
declare idP int;
select SUM(Precio) into sum from detalle_compra where id_compra=new.id_compra;
update compra set Total=sum where compra.id_compra=new.id_compra;
#verificar precio anterior y aumentar el resto si sube
select id_producto into idP from lote where Loteid=new.Lote;
select case when(select count(Loteid) from lote where id_producto=idP)>0 then (SELECT precioV from lote where id_producto=idP order by fechaCreate limit 1)else 0 end into precioa;
if new.PrecioU>precioa then 
	update lote set precioV=new.PrecioU where id_producto=idP;
    end if;
end
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_venta`
--

CREATE TABLE `detalle_venta` (
  `id_Lote` varchar(15) DEFAULT NULL,
  `PrecioU` int(11) NOT NULL,
  `TotalProducto` int(11) NOT NULL,
  `Cantidad` int(11) NOT NULL,
  `PosicionTabla` int(11) DEFAULT NULL,
  `id_venta` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `detalle_venta`
--

INSERT INTO `detalle_venta` (`id_Lote`, `PrecioU`, `TotalProducto`, `Cantidad`, `PosicionTabla`, `id_venta`) VALUES
('eeeeeee', 200, 2000, 10, 1, 72),
('rrrrrrrrr', 150, 1500, 10, 1, 74),
('eeeeeee', 200, 2000, 10, 1, 75),
('rrrrrrrrr', 150, 1500, 10, 1, 76),
('eeeeeee', 200, 2000, 10, 1, 77),
('rrrrrrrrr', 150, 1500, 10, 1, 78),
('rrrrrrrrr', 150, 1500, 10, 1, 79),
('eeeeeee', 200, 2000, 10, 1, 80),
('rrrrrrrrr', 150, 1500, 10, 1, 81),
('eeeeeee', 200, 2000, 10, 1, 82),
('eeeeeee', 200, 2000, 10, 1, 83),
('eeeeeee', 200, 2000, 10, 1, 84),
('nnnnasasa', 1700, 5100, 3, 1, 85),
('888asas', 2000, 4000, 2, 2, 85),
('eeeeeee', 2000, 2000, 1, 1, 86),
('rrrrrrrrr', 70, 700, 10, 1, 88),
('rrrrrrrrr', 70, 700, 10, 1, 89),
('nnnnasasa', 1700, 3400, 2, 2, 89),
('eeeeeee', 2000, 2000, 1, 3, 89),
('jksajsa', 3200, 3200, 1, 4, 89);

--
-- Disparadores `detalle_venta`
--
DELIMITER $$
CREATE TRIGGER `Aumento_venta` AFTER INSERT ON `detalle_venta` FOR EACH ROW begin
declare sum int;
select TotalCompra into sum from venta where id_venta=new.id_venta;
set sum=sum+new.TotalProducto;
update venta set TotalCompra=sum where id_venta=new.id_venta;
end
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `django_admin_log`
--

CREATE TABLE `django_admin_log` (
  `id` int(11) NOT NULL,
  `action_time` datetime(6) NOT NULL,
  `object_id` longtext COLLATE utf8_spanish_ci DEFAULT NULL,
  `object_repr` varchar(200) COLLATE utf8_spanish_ci NOT NULL,
  `action_flag` smallint(5) UNSIGNED NOT NULL CHECK (`action_flag` >= 0),
  `change_message` longtext COLLATE utf8_spanish_ci NOT NULL,
  `content_type_id` int(11) DEFAULT NULL,
  `user_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `django_admin_log`
--

INSERT INTO `django_admin_log` (`id`, `action_time`, `object_id`, `object_repr`, `action_flag`, `change_message`, `content_type_id`, `user_id`) VALUES
(5, '2023-11-17 12:37:55.527569', '3', 'jose', 2, '[{\"changed\": {\"fields\": [\"Username\", \"Groups\"]}}]', 6, 3),
(6, '2023-11-17 12:44:42.648832', '2', 'Admin', 1, '[{\"added\": {}}]', 5, 3),
(7, '2023-11-17 13:35:48.847588', '3', '27452842', 2, '[{\"changed\": {\"fields\": [\"Username\"]}}]', 6, 3);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `django_content_type`
--

CREATE TABLE `django_content_type` (
  `id` int(11) NOT NULL,
  `app_label` varchar(100) COLLATE utf8_spanish_ci NOT NULL,
  `model` varchar(100) COLLATE utf8_spanish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `django_content_type`
--

INSERT INTO `django_content_type` (`id`, `app_label`, `model`) VALUES
(3, 'admin', 'logentry'),
(5, 'auth', 'group'),
(4, 'auth', 'permission'),
(6, 'auth', 'user'),
(7, 'contenttypes', 'contenttype'),
(1, 'Proyecto', 'producto'),
(2, 'Proyecto', 'vencimiento'),
(8, 'sessions', 'session');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `django_migrations`
--

CREATE TABLE `django_migrations` (
  `id` bigint(20) NOT NULL,
  `app` varchar(255) COLLATE utf8_spanish_ci NOT NULL,
  `name` varchar(255) COLLATE utf8_spanish_ci NOT NULL,
  `applied` datetime(6) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `django_migrations`
--

INSERT INTO `django_migrations` (`id`, `app`, `name`, `applied`) VALUES
(1, 'contenttypes', '0001_initial', '2023-10-25 22:42:29.111942'),
(2, 'auth', '0001_initial', '2023-10-25 22:42:29.960887'),
(3, 'admin', '0001_initial', '2023-10-25 22:42:30.169883'),
(4, 'admin', '0002_logentry_remove_auto_add', '2023-10-25 22:42:30.176393'),
(5, 'admin', '0003_logentry_add_action_flag_choices', '2023-10-25 22:42:30.184356'),
(6, 'contenttypes', '0002_remove_content_type_name', '2023-10-25 22:42:30.303434'),
(7, 'auth', '0002_alter_permission_name_max_length', '2023-10-25 22:42:30.324963'),
(8, 'auth', '0003_alter_user_email_max_length', '2023-10-25 22:42:30.374505'),
(9, 'auth', '0004_alter_user_username_opts', '2023-10-25 22:42:30.386472'),
(10, 'auth', '0005_alter_user_last_login_null', '2023-10-25 22:42:30.473352'),
(11, 'auth', '0006_require_contenttypes_0002', '2023-10-25 22:42:30.475346'),
(12, 'auth', '0007_alter_validators_add_error_messages', '2023-10-25 22:42:30.482369'),
(13, 'auth', '0008_alter_user_username_max_length', '2023-10-25 22:42:30.497286'),
(14, 'auth', '0009_alter_user_last_name_max_length', '2023-10-25 22:42:30.514961'),
(15, 'auth', '0010_alter_group_name_max_length', '2023-10-25 22:42:30.717970'),
(16, 'auth', '0011_update_proxy_permissions', '2023-10-25 22:42:30.727740'),
(17, 'auth', '0012_alter_user_first_name_max_length', '2023-10-25 22:42:30.776490'),
(18, 'sessions', '0001_initial', '2023-10-25 22:42:30.876242');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `django_session`
--

CREATE TABLE `django_session` (
  `session_key` varchar(40) COLLATE utf8_spanish_ci NOT NULL,
  `session_data` longtext COLLATE utf8_spanish_ci NOT NULL,
  `expire_date` datetime(6) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `django_session`
--

INSERT INTO `django_session` (`session_key`, `session_data`, `expire_date`) VALUES
('1zlmcu8u559ryx74j9n0l8kpjyg11j6k', '.eJxVjEEOwiAQRe_C2pCOHWDGpXvPQGBAqRpISrsy3l2bdKHb_977L-XDuhS_9jz7KamTGtXhd4tBHrluIN1DvTUtrS7zFPWm6J12fWkpP8-7-3dQQi_fmgcwgYAsA2RLESCCC4KER2MZDV5HBMNDtI4lAVhCIU4WMwm6EdT7A50ENgk:1siXtE:Gs_sYbWei631bRgpijBlcRUeUoFcPOTl_6mI7jwCIbs', '2024-08-26 19:28:04.342748'),
('2pgda48nvs8ypx5veze4jff7h55m7l8z', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sIFWQ:TXiOgnZ6Qu6xsxCbeKIDJp321HZeUEbz2oRJsdJKfzQ', '2024-06-15 06:35:50.678006'),
('31kjxeqcgkvbtgdmdio5s37a6zeey5l9', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sJCgJ:9EPEVu_FS54mMs2B0UZicCte6L4_2dvRM0iNXPw2f1A', '2024-06-17 21:45:59.417572'),
('78x0z2qpumhos8rke02yntufxbwntgbg', '.eJxVjEEOwiAQRe_C2pCOHWDGpXvPQGBAqRpISrsy3l2bdKHb_977L-XDuhS_9jz7KamTGtXhd4tBHrluIN1DvTUtrS7zFPWm6J12fWkpP8-7-3dQQi_fmgcwgYAsA2RLESCCC4KER2MZDV5HBMNDtI4lAVhCIU4WMwm6EdT7A50ENgk:1sgbOq:OeSlrwfVoYpSxvxQZT0aFwK2QVOlYsVn3ve6Zub6lJ4', '2024-08-21 10:48:40.752029'),
('7zdq3dhy3vzncrp6w1tscn1ivgfpmap9', '.eJxVjEEOwiAQRe_C2hBwKIhL9z0DGZhBqgaS0q6Md7dNutDte-__twi4LiWsnecwkbiKszj9sojpyXUX9MB6bzK1usxTlHsiD9vl2Ihft6P9OyjYy7Y21hlk6w2pCHCJKg-RGEArp7SyfkNxQAM2Y3IZkdgmBCb0NjtkLT5f3KE4hA:1rd7zn:4pbBkMd99V9yWe6fJvhlQPXuacr1PVdg1zHieLYO7tg', '2024-03-07 12:16:11.132810'),
('9ow5ww4pvw1rhmnvrtvgbmi4peo7jvvm', '.eJxVjDsOwjAQBe_iGllr-RtKes5geddrHECOFCdVxN1JpBTQvpl5m4hpXWpcO89xzOIqtLj8bpjoxe0A-ZnaY5I0tWUeUR6KPGmX9ynz-3a6fwc19brX7MArj3pwRpFBRRaQHNGAOVAiwOJBaQPZ6GJAs2Xe5eJDAG-DA_H5AuOAN5s:1sVjay:gwCWeU28HDdGFDbVzxgGjXP8fHTFdQ8KzD6hFpoZ4Ps', '2024-07-22 11:20:16.909912'),
('cg4ymx6r8sa4nxtvhd1l0e9soagndh57', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1s55rC:iIlGi1A2fwZZ_bwjAwSnn85f5q28bHZum36Su2Dspcc', '2024-05-09 23:38:54.830193'),
('chyooe62g6zwxcawg5ay7znr7pbekogr', '.eJxVjDsOwjAQBe_iGllr-RtKes5geddrHECOFCdVxN1JpBTQvpl5m4hpXWpcO89xzOIqtLj8bpjoxe0A-ZnaY5I0tWUeUR6KPGmX9ynz-3a6fwc19brX7MArj3pwRpFBRRaQHNGAOVAiwOJBaQPZ6GJAs2Xe5eJDAG-DA_H5AuOAN5s:1sLwFc:SujOw8L_pw82b8l71Hli8lERAN9is4aEjL4Sd2xI17s', '2024-06-25 10:49:44.436241'),
('d7zag99le2kmnj6hbhl7j435r2xjz4m7', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1s2unE:tGWctmgSiVChI_lF9U37j5KOzT6_TW1Sh0bxHcG05Gg', '2024-05-03 23:25:48.318442'),
('drre2v61ei9yc5ekxp4ti0zb13q56kcz', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sJlhR:DCfDRO6ZCXG-x1dRst5e3mMrL_rq27ZJ7-Y5oAqfKaQ', '2024-06-19 11:09:29.702333'),
('e5ooz9enqk4fc9f7bjbhg5au4pf08ckn', '.eJxVjDsOwjAQBe_iGln-hg0lfc5grb1rHEC2FCcV4u4QKQW0b2beSwTc1hK2zkuYSVyEEaffLWJ6cN0B3bHemkytrssc5a7Ig3Y5NeLn9XD_Dgr28q19hkjeQ0KjASFGTd66NPhzdo6MYYhgKWWADFapkVkTqIHsiMYzGfH-AO3qOBI:1r3br7:aOTxIf1Hf47gTaaaK7ia9K2VAOLaQkBpSt5hXONxgHY', '2023-11-30 12:52:25.502416'),
('eidtb0u2qp9dfqcwannuur4uagsxixg0', '.eJxVjEEOwiAQRe_C2pCOHWDGpXvPQGBAqRpISrsy3l2bdKHb_977L-XDuhS_9jz7KamTGtXhd4tBHrluIN1DvTUtrS7zFPWm6J12fWkpP8-7-3dQQi_fmgcwgYAsA2RLESCCC4KER2MZDV5HBMNDtI4lAVhCIU4WMwm6EdT7A50ENgk:1sdY2C:w-xA_t-QNavSwxOOR0mP3tFIEF5u1YVu93BtvG7JHSo', '2024-08-13 00:36:40.118848'),
('f2lot3b8mynewz1rw76ssie5zby93xc5', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sI5u8:wVwOOie6UmZo8whPgZKIXf38sfxglT_piFHDpxocSfY', '2024-06-14 20:19:40.421524'),
('fp0qoj4asiuedixif1lqv2p9wgeolvz1', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sJWu4:JAj-9SFGu0nq8sB6z9_jJUoKjoyyrUkEehGekQuAfv8', '2024-06-18 19:21:32.451664'),
('fyldwgfbpqmgtnv4iomeukd0i0tx34j5', 'e30:1rzxwv:FpU4zIMgxjrRVk2zEY-5pLx9q5fnbyj-YzixOs5t5kE', '2024-05-09 12:11:37.859978'),
('h7fyh0rfsei2r5sk1xwsptqojnsdhaya', '.eJxVjEEOwiAQRe_C2pCOHWDGpXvPQGBAqRpISrsy3l2bdKHb_977L-XDuhS_9jz7KamTGtXhd4tBHrluIN1DvTUtrS7zFPWm6J12fWkpP8-7-3dQQi_fmgcwgYAsA2RLESCCC4KER2MZDV5HBMNDtI4lAVhCIU4WMwm6EdT7A50ENgk:1siQAZ:mN6GtgHrrnS2EtGK-JwE2HqpAkcOh-isQCMl96zv9XY', '2024-08-26 11:13:27.034398'),
('hhvo7bow73onn27eow554ktoa3w1azb3', '.eJxVjDsOwjAQBe_iGllr-RtKes5geddrHECOFCdVxN1JpBTQvpl5m4hpXWpcO89xzOIqtLj8bpjoxe0A-ZnaY5I0tWUeUR6KPGmX9ynz-3a6fwc19brX7MArj3pwRpFBRRaQHNGAOVAiwOJBaQPZ6GJAs2Xe5eJDAG-DA_H5AuOAN5s:1sRBo0:RNwOMX5WGylIXGEUQiTjhFhazX13vaeZO7oLgqivY3s', '2024-07-09 22:26:56.944177'),
('hn0o6qq8rtxzidbr2z1ob0ivbcgjgxaa', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sKfGI:2D4dw5cXVaY1JrUivvuhVHvU9qmzky7XNzv7nSpYkk0', '2024-06-21 22:29:10.479350'),
('ielf6q699i8vizx7utdi6og09lwrt75b', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sKGe6:p7qxCCDrb0CYqSdTxhE1LYMIccAoFt18lY_v7us_SVU', '2024-06-20 20:12:06.502499'),
('inea3e07iwpssx3kpfdhxsqytx1y7yc0', '.eJxVjDsOwjAQBe_iGllr-RtKes5geddrHECOFCdVxN1JpBTQvpl5m4hpXWpcO89xzOIqtLj8bpjoxe0A-ZnaY5I0tWUeUR6KPGmX9ynz-3a6fwc19brX7MArj3pwRpFBRRaQHNGAOVAiwOJBaQPZ6GJAs2Xe5eJDAG-DA_H5AuOAN5s:1sQmKL:vgylAnyJxzhhBciUaZ0t795qQj4ybo8gNAbzNB3o_oo', '2024-07-08 19:14:37.955179'),
('k3ppqmyhc2xwts6aykbbcqpcm77jwnh1', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sLVlM:j5lFvs-b_JqzSxw0g-LVoW2neIqjjBv5o00cDca9zVs', '2024-06-24 06:32:44.180204'),
('kjbdpge97ji9ark2ok2fqcj5q2ofkjvf', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sAAaW:ITOpSr_t2bE_IhUAP4G6UMkW9tI6hJ3h-bZnOS7Yjd4', '2024-05-23 23:42:40.700289'),
('klglvjofb1odcfcowdq5g5ip8a0h8r1d', '.eJxVjDsOwjAQBe_iGllr-RtKes5geddrHECOFCdVxN1JpBTQvpl5m4hpXWpcO89xzOIqtLj8bpjoxe0A-ZnaY5I0tWUeUR6KPGmX9ynz-3a6fwc19brX7MArj3pwRpFBRRaQHNGAOVAiwOJBaQPZ6GJAs2Xe5eJDAG-DA_H5AuOAN5s:1sLvae:-fVIYf9uqqiKwYJJjwdAR09wYX1TG9EEdQC4a7fIGxw', '2024-06-25 10:07:24.104964'),
('mebrh7czld1cmnqf68us3qnroeqvu8pk', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1s7dit:oeEBNhMuNRZ354FasIFcNlQ_RdDtfOjCGBVZC1DiBLY', '2024-05-17 00:12:51.562914'),
('mrwcoeudmnm7y3w30wcmiqbaieynhkoo', '.eJxVjEEOwiAQRe_C2pCOHWDGpXvPQGBAqRpISrsy3l2bdKHb_977L-XDuhS_9jz7KamTGtXhd4tBHrluIN1DvTUtrS7zFPWm6J12fWkpP8-7-3dQQi_fmgcwgYAsA2RLESCCC4KER2MZDV5HBMNDtI4lAVhCIU4WMwm6EdT7A50ENgk:1shU5b:h9zmsJYCQSuYDsXa1eFv9nskEQ4vRh9H-DIShh98FRE', '2024-08-23 21:12:27.011303'),
('muq3be3ljpvxe8fx7fl7fntp5s6jlnbj', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1s7wkl:iEVYmXl2fNiBEvN6RnDAzBtjvXvzk0znfFpX960494Y', '2024-05-17 20:32:03.041359'),
('naln5a4d93phok2ido5avkvwl304lkp4', '.eJxVjDsOwjAQBe_iGln4E-OlpOcM1m68iwPIluKkQtwdIqWA9s3Me6mE61LS2nlOU1Zn5dThdyMcH1w3kO9Yb02PrS7zRHpT9E67vrbMz8vu_h0U7OVbG0_RYBYmB0EYiCAHL5ZOxpCQCAoSWCeB7RBBjmKYeADvrPMRnHp_ABy4ONc:1r46Vg:hyTABNosUu5IRIeC7_OXbEFXXpGHABuF0x2TL6eClt0', '2023-12-01 21:36:20.429767'),
('nhk4relqpow9zu0e7k7bwtg007swuvl0', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sAW5A:3nSisoYIbyB_8F5RGq03NK4IlFKU6REsqLgQcE-hqks', '2024-05-24 22:39:44.973061'),
('nif8owffr5nm53vvvxm88ykn3akvftrg', '.eJxVjDsOwjAQBe_iGllr-RtKes5geddrHECOFCdVxN1JpBTQvpl5m4hpXWpcO89xzOIqtLj8bpjoxe0A-ZnaY5I0tWUeUR6KPGmX9ynz-3a6fwc19brX7MArj3pwRpFBRRaQHNGAOVAiwOJBaQPZ6GJAs2Xe5eJDAG-DA_H5AuOAN5s:1saw17:X3y3oj5g2Fc2zacjCdB14HIOi3p16LzewEiryT42y_o', '2024-08-05 19:36:45.520686'),
('nvpjhfh5el8o6oesxchl3frxai0vop4a', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sKPoq:kAoBexzD4NT5igCZNpBQTNaOBPoEGkdq9c_P5HDSn8w', '2024-06-21 05:59:48.167616'),
('q2rx0gsnn49hsxgus1h9dcvizu73c6be', '.eJxVjDsOwjAQBe_iGllr-RtKes5geddrHECOFCdVxN1JpBTQvpl5m4hpXWpcO89xzOIqtLj8bpjoxe0A-ZnaY5I0tWUeUR6KPGmX9ynz-3a6fwc19brX7MArj3pwRpFBRRaQHNGAOVAiwOJBaQPZ6GJAs2Xe5eJDAG-DA_H5AuOAN5s:1sU6aU:7gCDkzdAuybjUPEhOZobvC5tYFWAeF0CqSHXqxur9KA', '2024-07-17 23:29:02.387769'),
('r84vdmy19hm0vyl92kgfp8swrcd1qvy1', '.eJxVjDsOwjAQBe_iGllr-RtKes5geddrHECOFCdVxN1JpBTQvpl5m4hpXWpcO89xzOIqtLj8bpjoxe0A-ZnaY5I0tWUeUR6KPGmX9ynz-3a6fwc19brX7MArj3pwRpFBRRaQHNGAOVAiwOJBaQPZ6GJAs2Xe5eJDAG-DA_H5AuOAN5s:1sbJrb:3Ed94hzG9dvqEmB68TilaudgnAQLyf8iPNEnBbBrv_w', '2024-08-06 21:04:31.856279'),
('rnqdnpcqrsskyidb5u5r1i6vkfxhf0d7', '.eJxVjjsOwjAQRO_iGlmx499S0nOGaO1d4wCypXwqxN3BUgpo570ZzUtMuG9l2ldeppnEWSgrTr9hxPTg2gndsd6aTK1uyxxlV-RBV3ltxM_L4f4NFFxLb9vBMHhrxhSC04pcjmCzxxFYe8gZFXgVONvoAvHoDBEOHjQbB-H76v0B--Y3qw:1sgR7L:3fyluFxsc9dVjlVGd24tUsMDxZ9QqVX9PuAbH4cPRKo', '2024-08-20 23:49:55.147004'),
('smmct7qge5xdj3wv8uro8mpyksi29vyl', '.eJxVjDsOwjAQBe_iGllr-RtKes5geddrHECOFCdVxN1JpBTQvpl5m4hpXWpcO89xzOIqtLj8bpjoxe0A-ZnaY5I0tWUeUR6KPGmX9ynz-3a6fwc19brX7MArj3pwRpFBRRaQHNGAOVAiwOJBaQPZ6GJAs2Xe5eJDAG-DA_H5AuOAN5s:1sThHq:5okwBOcPXP62Xfd1XI5C4yRRvqMtCcD1R4CN8tSychg', '2024-07-16 20:28:06.864350'),
('ujsce9v4tr5eps2bxwlegx3j7opxk1ya', '.eJxVjDsOwjAQBe_iGllr-RtKes5geddrHECOFCdVxN1JpBTQvpl5m4hpXWpcO89xzOIqtLj8bpjoxe0A-ZnaY5I0tWUeUR6KPGmX9ynz-3a6fwc19brX7MArj3pwRpFBRRaQHNGAOVAiwOJBaQPZ6GJAs2Xe5eJDAG-DA_H5AuOAN5s:1sTjYU:Smum9lOvluifwwSK9fGx4YRc5qv6GoSNkGPWzuzPYok', '2024-07-16 22:53:26.500247'),
('usbf9f4trkkdqgbzi2vwy9hkt4mos0aa', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sJtFh:0OpGWsn_XWIRDIpUCCmJh9CkRo5JTAJ4ewH16_im_Mo', '2024-06-19 19:13:21.227605'),
('v8tl9cmzewf7ii5011di62p4v6np8xvz', '.eJxVjMEOwiAQRP-FsyECWygevfsNZGEXqRpISnsy_rtt0oMeZ96beYuA61LC2nkOE4mLUIM4_ZYR05PrTuiB9d5kanWZpyh3RR60y1sjfl0P9--gYC_bGrNjUNqgIlKj8Z4gWkjZ0DlndhAjIcMWBmKlkJzzCUedI2iwwFZ8vjE8OSQ:1scRrH:QVG4z985ypXmy4inXZtFl1SFthd4vzdKb2h8TWPAtl8', '2024-08-09 23:48:51.579214'),
('xcoracqb8c5x1k27spbuf6ijg37pihop', '.eJxVjEEOwiAQRe_C2pCOHWDGpXvPQGBAqRpISrsy3l2bdKHb_977L-XDuhS_9jz7KamTGtXhd4tBHrluIN1DvTUtrS7zFPWm6J12fWkpP8-7-3dQQi_fmgcwgYAsA2RLESCCC4KER2MZDV5HBMNDtI4lAVhCIU4WMwm6EdT7A50ENgk:1sgjup:vCRiN-oI0WlUcmlgpeB1SD2g7jQzX1NKZEPGq8OCQIs', '2024-08-21 19:54:15.022414'),
('z97y9w84xe499svmt10kj9zypyt1mcxo', '.eJxVzMsOwiAUBNB_YW0IeHt5uHTvNxAuD6kaSEq7Mv67NOlCt3Nm5s2c39bitp4WN0d2YRM7_WbkwzPVHeLD13vjodV1mYnvFX5o57cW0-t6dP8Oiu9lrG02EqW2Z68wkJYmg8AJyJo8iKI2hANjAsCgiSCoSYAZagmjEuzzBc3VN2w:1rY568:pwBOBLr5sXzIPjAIDdGdEiQJrcni-LnhXNv0TbhBkKA', '2024-02-22 14:09:52.270358');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `historia_caja`
--

CREATE TABLE `historia_caja` (
  `id` int(11) NOT NULL,
  `id_caja` int(11) NOT NULL,
  `cedula` varchar(15) CHARACTER SET utf8 COLLATE utf8_spanish_ci DEFAULT NULL,
  `inicio` bigint(20) NOT NULL,
  `final` bigint(20) DEFAULT NULL,
  `retiro` bigint(20) DEFAULT 0,
  `fecha` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `historia_caja`
--

INSERT INTO `historia_caja` (`id`, `id_caja`, `cedula`, `inicio`, `final`, `retiro`, `fecha`) VALUES
(1, 1, NULL, 50000, NULL, 0, NULL),
(2, 1, '1025644878', 50000, 50000, 45000, NULL),
(3, 1, '1025644878', 50000, 85000, 10000, NULL),
(4, 1, '1017924962', 85000, 50000, 35000, NULL),
(5, 1, '1017924962', 50000, 50000, 0, NULL),
(6, 1, '1017924962', 50000, 50000, 0, NULL),
(7, 1, '1017924962', 50000, 50000, 0, NULL),
(8, 1, '1017924962', 50000, 50000, 2000, NULL),
(9, 1, '1017924962', 50000, 49100, 10000, '2024-08-12 11:36:35'),
(10, 1, '1017924962', 49100, 51100, 0, '2024-08-20 09:37:23'),
(11, 1, NULL, 51100, NULL, 0, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `horas_trabajadas`
--

CREATE TABLE `horas_trabajadas` (
  `id` int(11) NOT NULL,
  `usuario` varchar(150) CHARACTER SET utf8 COLLATE utf8_spanish_ci NOT NULL,
  `fecha` date NOT NULL,
  `horas` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `horas_trabajadas`
--

INSERT INTO `horas_trabajadas` (`id`, `usuario`, `fecha`, `horas`) VALUES
(68, '1017924962', '2024-08-09', 7079),
(69, '1017924962', '2024-08-02', 3621),
(70, '1025644878', '2024-08-09', 14),
(71, '1025644878', '2024-08-12', 12),
(72, '1025644878', '2024-08-12', 6094),
(73, '1017924962', '2024-08-12', 145),
(74, '1017924962', '2024-08-12', 78),
(75, '1017924962', '2024-08-12', 7),
(76, '1017924962', '2024-08-12', 7),
(77, '1017924962', '2024-08-12', 42),
(78, '1017924962', '2024-08-12', 15517),
(79, '1017924962', '2024-08-20', 10421),
(80, '1017924962', '2024-08-20', 4343);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `lote`
--

CREATE TABLE `lote` (
  `id_producto` bigint(20) NOT NULL,
  `Loteid` varchar(15) NOT NULL,
  `Cantidad` int(11) NOT NULL,
  `PrecioC` int(11) NOT NULL,
  `porcentaje` int(11) NOT NULL,
  `precioV` int(11) NOT NULL,
  `Estado` tinyint(1) DEFAULT 1,
  `fechaVenci` date NOT NULL,
  `fechaModify` date NOT NULL,
  `fechaCreate` date NOT NULL,
  `Notificacion_on` tinyint(4) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `lote`
--

INSERT INTO `lote` (`id_producto`, `Loteid`, `Cantidad`, `PrecioC`, `porcentaje`, `precioV`, `Estado`, `fechaVenci`, `fechaModify`, `fechaCreate`, `Notificacion_on`) VALUES
(770321, '888asas', 28, 34500, 70, 3200, 0, '2023-11-12', '2024-08-12', '2024-08-12', 1),
(770123, 'eeeeeee', 0, 15000, 100, 2000, 0, '2030-03-22', '2024-07-21', '2024-07-21', 0),
(7701234, 'Ibu9922', 300, 45000, 100, 300, 1, '2036-02-01', '2024-08-26', '2024-08-26', 1),
(770123, 'jjajsaj', 1481239, 10000, 100, 2000, 1, '2026-09-01', '2024-08-12', '2024-08-12', 1),
(770321, 'JJJ8987', 30, 27910, 78, 1700, 1, '2038-03-01', '2024-08-26', '2024-08-26', 1),
(770321, 'jksajsa', 29, 60000, 60, 3200, 1, '2028-11-01', '2024-08-12', '2024-08-12', 1),
(770123, 'JKSNa8989', 300, 27890, 100, 200, 1, '2038-02-01', '2024-08-26', '2024-08-26', 1),
(77012345, 'nnnnasasa', 30, 57000, 75, 3350, 1, '2034-03-01', '2024-08-12', '2024-08-12', 1),
(77012345, 'NSJAS990', 30, 58901, 70, 3350, 1, '2038-02-01', '2024-08-26', '2024-08-26', 1),
(770123, 'qqqqqqq', 300, 6500, 100, 2000, 1, '2029-07-22', '2024-07-21', '2024-07-21', 0),
(7701234, 'rrrrrrrrr', 230, 25890, 70, 300, 1, '2024-08-31', '2024-07-21', '2024-07-21', 0),
(77012345, 'UJJS', 30, 27890, 65, 3350, 1, '2035-07-01', '2024-08-26', '2024-08-26', 1),
(7701234, 'wwwwwwwww', 300, 26890, 70, 300, 1, '2030-09-22', '2024-07-21', '2024-07-21', 0),
(770123, 'yyyyyy', 300, 20000, 100, 2000, 1, '2028-08-22', '2024-07-21', '2024-07-21', 1);

--
-- Disparadores `lote`
--
DELIMITER $$
CREATE TRIGGER `EstadoLAV` BEFORE UPDATE ON `lote` FOR EACH ROW begin
if TIMESTAMPDIFF(day,now(),new.fechaVenci)<0 then
SET new.Estado=False;
elseif new.Cantidad<=0 then
SET new.Estado=False;

end if;
end
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Very_estadoP` BEFORE UPDATE ON `lote` FOR EACH ROW begin
declare productoE boolean;
select Estado into productoE from producto where id_producto=new.id_producto;

if productoE=False then
SET New.Estado=Old.Estado;
end if;
end
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pedidos_especiales`
--

CREATE TABLE `pedidos_especiales` (
  `id_pedido` int(11) NOT NULL,
  `Cedula` varchar(150) CHARACTER SET utf8 COLLATE utf8_spanish_ci NOT NULL DEFAULT '',
  `nombreClie` varchar(50) NOT NULL,
  `celularClie` varchar(10) NOT NULL,
  `descripcion` varchar(250) NOT NULL,
  `estadoPe` tinyint(1) DEFAULT 1,
  `fechaP` date NOT NULL,
  `Cantidad` int(11) NOT NULL,
  `fechaM` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `pedidos_especiales`
--

INSERT INTO `pedidos_especiales` (`id_pedido`, `Cedula`, `nombreClie`, `celularClie`, `descripcion`, `estadoPe`, `fechaP`, `Cantidad`, `fechaM`) VALUES
(9, '1017924962', 'Sebas', '3015678990', 'crema para heridas ', 2, '2024-08-20', 2, '2024-08-20 10:05:13');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

CREATE TABLE `producto` (
  `id_producto` bigint(20) NOT NULL DEFAULT 0,
  `Nombre` varchar(30) NOT NULL DEFAULT '',
  `estado` tinyint(1) DEFAULT 1,
  `GramoLitro` varchar(30) DEFAULT NULL,
  `Fecha_Modificacion` datetime NOT NULL DEFAULT current_timestamp(),
  `Max` int(11) NOT NULL DEFAULT 0,
  `Min` int(11) NOT NULL DEFAULT 0,
  `rotacion` varchar(250) NOT NULL DEFAULT 'Normal'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `producto`
--

INSERT INTO `producto` (`id_producto`, `Nombre`, `estado`, `GramoLitro`, `Fecha_Modificacion`, `Max`, `Min`, `rotacion`) VALUES
(770123, 'Acetaminofen', 1, '30mg', '2024-07-21 22:31:57', 900, 100, 'Normal'),
(770321, 'Next gl', 1, '215 mg', '2024-08-12 07:46:37', 50, 15, 'Baja'),
(7701234, 'Ibuprofeno', 1, '300mg', '2024-07-21 23:10:44', 600, 100, 'Normal'),
(77012345, 'Advil Gripa', 1, '30 mg', '2024-08-20 07:06:21', 90, 20, 'Normal');

--
-- Disparadores `producto`
--
DELIMITER $$
CREATE TRIGGER `EstadoLA` AFTER UPDATE ON `producto` FOR EACH ROW begin
if new.Estado=True then
update Lote set Estado=True where Lote.id_producto=new.id_producto;
end if;
end
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `estado_lotes` BEFORE UPDATE ON `producto` FOR EACH ROW begin
if new.Estado=False then
update Lote set Estado=False where Lote.id_producto=new.id_producto;
end if;
end
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedor`
--

CREATE TABLE `proveedor` (
  `NIT` int(11) NOT NULL DEFAULT 0,
  `Nombre` varchar(30) NOT NULL,
  `Estado` tinyint(1) DEFAULT 1,
  `Telefono` varchar(10) NOT NULL,
  `Horario_Atencion` varchar(250) NOT NULL,
  `Politica_Devolucion` varchar(250) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `proveedor`
--

INSERT INTO `proveedor` (`NIT`, `Nombre`, `Estado`, `Telefono`, `Horario_Atencion`, `Politica_Devolucion`) VALUES
(12121212, 'Hexon', 1, '3025469090', 'lunes-viernes 7am-1pm', '3'),
(2147483647, 'Henfar', 1, '3214567890', 'lunes-viernes 8am-1pm', '5');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `temp_compra`
--

CREATE TABLE `temp_compra` (
  `id_compra` int(11) NOT NULL,
  `Total` int(11) NOT NULL,
  `Fecha_Llegada` datetime DEFAULT NULL,
  `NIT` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `temp_detalle_compra`
--

CREATE TABLE `temp_detalle_compra` (
  `Lote` varchar(15) DEFAULT NULL,
  `Precio` int(11) NOT NULL,
  `procentaje` int(11) NOT NULL,
  `PrecioU` int(11) NOT NULL,
  `CantidadProductos` int(11) NOT NULL,
  `id_compra` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `temp_lote`
--

CREATE TABLE `temp_lote` (
  `id_producto` bigint(20) NOT NULL,
  `Loteid` varchar(15) NOT NULL,
  `Cantidad` int(11) NOT NULL,
  `PrecioC` int(11) NOT NULL,
  `porcentaje` int(11) NOT NULL,
  `precioV` int(11) NOT NULL,
  `Estado` tinyint(1) DEFAULT 1,
  `fechaVenci` date NOT NULL,
  `fechaModify` date NOT NULL,
  `fechaCreate` date NOT NULL,
  `Notificacion_on` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `temp_producto`
--

CREATE TABLE `temp_producto` (
  `id_producto` bigint(20) NOT NULL DEFAULT 0,
  `Nombre` varchar(30) NOT NULL DEFAULT '',
  `estado` tinyint(1) DEFAULT 1,
  `GramoLitro` varchar(30) DEFAULT NULL,
  `Fecha_Modificacion` datetime NOT NULL DEFAULT current_timestamp(),
  `Max` int(11) NOT NULL DEFAULT 0,
  `Min` int(11) NOT NULL DEFAULT 0,
  `rotacion` varchar(250) NOT NULL DEFAULT 'Normal'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `temp_proveedor`
--

CREATE TABLE `temp_proveedor` (
  `NIT` int(11) NOT NULL DEFAULT 0,
  `Nombre` varchar(30) NOT NULL,
  `Estado` tinyint(1) DEFAULT 1,
  `Telefono` varchar(10) NOT NULL,
  `Horario_Atencion` varchar(250) NOT NULL,
  `Politica_Devolucion` varchar(250) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta`
--

CREATE TABLE `venta` (
  `id_venta` int(11) NOT NULL,
  `TotalCompra` int(11) NOT NULL,
  `Fecha` date NOT NULL,
  `Hora` time DEFAULT NULL,
  `Efectivo_Recibido` int(11) NOT NULL,
  `Efectivo_Entregado` int(11) NOT NULL,
  `Cedula` varchar(150) CHARACTER SET utf8 COLLATE utf8_spanish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `venta`
--

INSERT INTO `venta` (`id_venta`, `TotalCompra`, `Fecha`, `Hora`, `Efectivo_Recibido`, `Efectivo_Entregado`, `Cedula`) VALUES
(72, 2000, '2024-08-05', '07:45:48', 2000, 0, '1017924962'),
(74, 1500, '2024-08-05', '07:47:18', 0, 0, '1017924962'),
(75, 2000, '2024-08-05', '09:08:12', 0, 0, '1017924962'),
(76, 1500, '2024-08-05', '09:10:53', 2000, 500, '1017924962'),
(77, 2000, '2024-08-05', '09:13:40', 9, -1991, '1017924962'),
(78, 1500, '2024-07-05', '09:15:00', 12121, 10621, '1017924962'),
(79, 1500, '2024-08-05', '09:15:55', 1500, 0, '1017924962'),
(80, 2000, '2024-08-05', '09:16:50', 5000, 3000, '1017924962'),
(81, 1500, '2024-08-05', '09:17:27', 2000, 500, '1017924962'),
(82, 2000, '2024-08-06', '10:35:46', 5000, 3000, '1017924962'),
(83, 2000, '2024-08-09', '10:49:04', 3000, 1000, '1025644878'),
(84, 2000, '2024-08-12', '07:11:00', 5000, 3000, '1017924962'),
(85, 9100, '2024-08-12', '07:54:44', 10000, 900, '1017924962'),
(86, 2000, '2024-08-12', '06:57:50', 2000, 0, '1017924962'),
(87, -2147483648, '2024-08-23', '10:47:56', 2000, 7420000, '1017924962'),
(88, 700, '2024-08-23', '10:48:43', 1000, 300, '1017924962'),
(89, 9300, '2024-08-26', '07:08:48', 10000, 700, '1017924962'),
(90, -371364250, '2024-08-26', '08:58:45', 0, 0, '1017924962'),
(91, 0, '2024-08-26', '09:13:40', 0, 0, '1017924962');

--
-- Disparadores `venta`
--
DELIMITER $$
CREATE TRIGGER `actualizar_caja_registro` BEFORE UPDATE ON `venta` FOR EACH ROW BEGIN
declare caja INT;
declare cash bigint;
select count(id) into caja from caja;
if caja<=0 then 
insert into caja values (1,50000);
insert into historia_caja (id_caja,inicio) values (1,50000);
end if;
select dinero into cash from caja; 
if (new.TotalCompra-old.TotalCompra)<0 THEN 
update caja set dinero =((cash)+(new.TotalCompra-old.TotalCompra))where id=1;
ELSEIF (new.TotalCompra-old.TotalCompra)>0 THEN
update caja set dinero =(cash+(new.TotalCompra-old.TotalCompra)) where id=1;
end if;
END
$$
DELIMITER ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `auth_group`
--
ALTER TABLE `auth_group`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indices de la tabla `auth_group_permissions`
--
ALTER TABLE `auth_group_permissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `auth_group_permissions_group_id_permission_id_0cd325b0_uniq` (`group_id`,`permission_id`),
  ADD KEY `auth_group_permissio_permission_id_84c5c92e_fk_auth_perm` (`permission_id`);

--
-- Indices de la tabla `auth_permission`
--
ALTER TABLE `auth_permission`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `auth_permission_content_type_id_codename_01ab375a_uniq` (`content_type_id`,`codename`);

--
-- Indices de la tabla `auth_user`
--
ALTER TABLE `auth_user`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indices de la tabla `auth_user_groups`
--
ALTER TABLE `auth_user_groups`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `auth_user_groups_user_id_group_id_94350c0c_uniq` (`user_id`,`group_id`),
  ADD KEY `auth_user_groups_group_id_97559544_fk_auth_group_id` (`group_id`);

--
-- Indices de la tabla `auth_user_user_permissions`
--
ALTER TABLE `auth_user_user_permissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `auth_user_user_permissions_user_id_permission_id_14a6b632_uniq` (`user_id`,`permission_id`),
  ADD KEY `auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm` (`permission_id`);

--
-- Indices de la tabla `caja`
--
ALTER TABLE `caja`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `compra`
--
ALTER TABLE `compra`
  ADD PRIMARY KEY (`id_compra`),
  ADD KEY `NIT` (`NIT`);

--
-- Indices de la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD KEY `Lote` (`Lote`),
  ADD KEY `id_compra` (`id_compra`);

--
-- Indices de la tabla `detalle_venta`
--
ALTER TABLE `detalle_venta`
  ADD KEY `id_Lote` (`id_Lote`),
  ADD KEY `id_venta` (`id_venta`);

--
-- Indices de la tabla `django_admin_log`
--
ALTER TABLE `django_admin_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `django_admin_log_content_type_id_c4bce8eb_fk_django_co` (`content_type_id`),
  ADD KEY `django_admin_log_user_id_c564eba6_fk_auth_user_id` (`user_id`);

--
-- Indices de la tabla `django_content_type`
--
ALTER TABLE `django_content_type`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `django_content_type_app_label_model_76bd3d3b_uniq` (`app_label`,`model`);

--
-- Indices de la tabla `django_migrations`
--
ALTER TABLE `django_migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `django_session`
--
ALTER TABLE `django_session`
  ADD PRIMARY KEY (`session_key`),
  ADD KEY `django_session_expire_date_a5c62663` (`expire_date`);

--
-- Indices de la tabla `historia_caja`
--
ALTER TABLE `historia_caja`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_caja` (`id_caja`),
  ADD KEY `cedula` (`cedula`);

--
-- Indices de la tabla `horas_trabajadas`
--
ALTER TABLE `horas_trabajadas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `usuario` (`usuario`);

--
-- Indices de la tabla `lote`
--
ALTER TABLE `lote`
  ADD PRIMARY KEY (`Loteid`),
  ADD KEY `CodigoP` (`id_producto`);

--
-- Indices de la tabla `pedidos_especiales`
--
ALTER TABLE `pedidos_especiales`
  ADD PRIMARY KEY (`id_pedido`),
  ADD KEY `Cedula` (`Cedula`);

--
-- Indices de la tabla `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`id_producto`) USING BTREE;

--
-- Indices de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  ADD PRIMARY KEY (`NIT`) USING BTREE;

--
-- Indices de la tabla `temp_compra`
--
ALTER TABLE `temp_compra`
  ADD PRIMARY KEY (`id_compra`);

--
-- Indices de la tabla `temp_lote`
--
ALTER TABLE `temp_lote`
  ADD PRIMARY KEY (`Loteid`);

--
-- Indices de la tabla `temp_producto`
--
ALTER TABLE `temp_producto`
  ADD PRIMARY KEY (`id_producto`) USING BTREE;

--
-- Indices de la tabla `temp_proveedor`
--
ALTER TABLE `temp_proveedor`
  ADD PRIMARY KEY (`NIT`) USING BTREE;

--
-- Indices de la tabla `venta`
--
ALTER TABLE `venta`
  ADD PRIMARY KEY (`id_venta`),
  ADD KEY `Cedula` (`Cedula`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `auth_group`
--
ALTER TABLE `auth_group`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `auth_group_permissions`
--
ALTER TABLE `auth_group_permissions`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `auth_permission`
--
ALTER TABLE `auth_permission`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT de la tabla `auth_user`
--
ALTER TABLE `auth_user`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT de la tabla `auth_user_groups`
--
ALTER TABLE `auth_user_groups`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `auth_user_user_permissions`
--
ALTER TABLE `auth_user_user_permissions`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `compra`
--
ALTER TABLE `compra`
  MODIFY `id_compra` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT de la tabla `django_admin_log`
--
ALTER TABLE `django_admin_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `django_content_type`
--
ALTER TABLE `django_content_type`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `django_migrations`
--
ALTER TABLE `django_migrations`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT de la tabla `historia_caja`
--
ALTER TABLE `historia_caja`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla `horas_trabajadas`
--
ALTER TABLE `horas_trabajadas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=81;

--
-- AUTO_INCREMENT de la tabla `pedidos_especiales`
--
ALTER TABLE `pedidos_especiales`
  MODIFY `id_pedido` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `temp_compra`
--
ALTER TABLE `temp_compra`
  MODIFY `id_compra` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT de la tabla `venta`
--
ALTER TABLE `venta`
  MODIFY `id_venta` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=92;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `auth_group_permissions`
--
ALTER TABLE `auth_group_permissions`
  ADD CONSTRAINT `auth_group_permissio_permission_id_84c5c92e_fk_auth_perm` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`),
  ADD CONSTRAINT `auth_group_permissions_group_id_b120cbf9_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`);

--
-- Filtros para la tabla `auth_permission`
--
ALTER TABLE `auth_permission`
  ADD CONSTRAINT `auth_permission_content_type_id_2f476e4b_fk_django_co` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`);

--
-- Filtros para la tabla `auth_user_groups`
--
ALTER TABLE `auth_user_groups`
  ADD CONSTRAINT `auth_user_groups_group_id_97559544_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`),
  ADD CONSTRAINT `auth_user_groups_user_id_6a12ed8b_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);

--
-- Filtros para la tabla `auth_user_user_permissions`
--
ALTER TABLE `auth_user_user_permissions`
  ADD CONSTRAINT `auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`),
  ADD CONSTRAINT `auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);

--
-- Filtros para la tabla `compra`
--
ALTER TABLE `compra`
  ADD CONSTRAINT `compra_ibfk_1` FOREIGN KEY (`NIT`) REFERENCES `proveedor` (`NIT`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD CONSTRAINT `detalle_compra_ibfk_1` FOREIGN KEY (`Lote`) REFERENCES `lote` (`Loteid`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `detalle_compra_ibfk_2` FOREIGN KEY (`id_compra`) REFERENCES `compra` (`id_compra`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `detalle_venta`
--
ALTER TABLE `detalle_venta`
  ADD CONSTRAINT `detalle_venta_ibfk_1` FOREIGN KEY (`id_Lote`) REFERENCES `lote` (`Loteid`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `detalle_venta_ibfk_2` FOREIGN KEY (`id_venta`) REFERENCES `venta` (`id_venta`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `django_admin_log`
--
ALTER TABLE `django_admin_log`
  ADD CONSTRAINT `django_admin_log_content_type_id_c4bce8eb_fk_django_co` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`),
  ADD CONSTRAINT `django_admin_log_user_id_c564eba6_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);

--
-- Filtros para la tabla `historia_caja`
--
ALTER TABLE `historia_caja`
  ADD CONSTRAINT `historia_caja_ibfk_1` FOREIGN KEY (`id_caja`) REFERENCES `caja` (`id`),
  ADD CONSTRAINT `historia_caja_ibfk_2` FOREIGN KEY (`cedula`) REFERENCES `auth_user` (`username`);

--
-- Filtros para la tabla `horas_trabajadas`
--
ALTER TABLE `horas_trabajadas`
  ADD CONSTRAINT `horas_trabajadas_ibfk_1` FOREIGN KEY (`usuario`) REFERENCES `auth_user` (`username`);

--
-- Filtros para la tabla `lote`
--
ALTER TABLE `lote`
  ADD CONSTRAINT `lote_ibfk_1` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id_producto`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `pedidos_especiales`
--
ALTER TABLE `pedidos_especiales`
  ADD CONSTRAINT `Cedula_Username` FOREIGN KEY (`Cedula`) REFERENCES `auth_user` (`username`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `venta`
--
ALTER TABLE `venta`
  ADD CONSTRAINT `venta_ibfk_1` FOREIGN KEY (`Cedula`) REFERENCES `auth_user` (`username`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
