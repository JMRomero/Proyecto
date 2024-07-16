-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost
-- Tiempo de generación: 16-07-2024 a las 14:29:49
-- Versión del servidor: 10.4.28-MariaDB
-- Versión de PHP: 8.2.4

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
CREATE DEFINER=`root`@`localhost` PROCEDURE `aumento_lote` ()   BEGIN
declare idProductos int;
declare precioVA bigint;
declare cont int;
select COUNT(id_producto) into cont from aumento;
if cont is not null then
set cont =cont-1;
repetir: LOOP
select id_producto into idProductos from aumento limit cont,1;
select PrecioV into precioVA from aumento where id_producto=idProductos;
update lote set precioV=precioVA where id_producto=idProductos and Estado=True;
set cont=cont-1;
if cont=-1 THEN
leave repetir;
end if;
end loop;
delete from aumento;
ELSE 
select cont;
end if;
END$$

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

CREATE DEFINER=`root`@`localhost` PROCEDURE `calcularHoras` (IN `usuario` VARCHAR(150))   insert into horas_trabajadas (usuario,fecha,horas)values(usuario,now(),(select timestampdiff(minute,hora_login,hora_logout) from auth_user where username=usuario))$$

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
GROUP BY v.fecha
ORDER BY v.fecha;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Lotes_vencer` ()   BEGIN
select Lote.Loteid,Lote.id_producto,Producto.nombre,proveedor.Nombre from Lote inner join Producto on Lote.id_producto=Producto.id_producto inner join detalle_compra on lote.Loteid=detalle_compra.Lote inner join compra on detalle_compra.id_compra=compra.id_compra INNER join proveedor on compra.NIT=proveedor.NIT where TIMESTAMPDIFF(month, NOW(), fechaVenci)<proveedor.Politica_Devolucion and TIMESTAMPDIFF(DAY, NOW(), fechaVenci)>0;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Lotes_vencidos` ()   begin
select Lote.Loteid,Lote.id_producto,Producto.nombre,proveedor.Nombre from Lote inner join Producto on Lote.id_producto=Producto.id_producto inner join detalle_compra on lote.Loteid=detalle_compra.Lote inner join compra on detalle_compra.id_compra=compra.id_compra INNER join proveedor on compra.NIT=proveedor.NIT where TIMESTAMPDIFF(DAY, NOW(), fechaVenci)<=0;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Producto_cero` ()   select nombre from producto where CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End=0 and Estado=True and rotacion="Normal"$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Producto_min` ()   select nombre from producto where CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End<Min and CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End>0 and estado=1 and rotacion="Normal"$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `User_group` (IN `cedula` INT(10), IN `idG` INT(10), IN `telefono` VARCHAR(10), IN `fecha` DATE, IN `direccion` VARCHAR(150))   begin 
INSERT INTO auth_user_groups (user_id,group_id) values((select id from auth_user where username=cedula),idG);
update auth_user set Telefono=telefono, fechaNacimiento=fecha,Direccion=direccion where username=cedula;
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
  `name` varchar(150) NOT NULL
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
  `name` varchar(255) NOT NULL,
  `content_type_id` int(11) NOT NULL,
  `codename` varchar(100) NOT NULL
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
  `password` varchar(128) NOT NULL,
  `last_login` datetime(6) DEFAULT NULL,
  `is_superuser` tinyint(1) NOT NULL DEFAULT 0,
  `username` varchar(150) NOT NULL,
  `first_name` varchar(150) NOT NULL,
  `last_name` varchar(150) NOT NULL,
  `email` varchar(254) NOT NULL,
  `is_staff` tinyint(1) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `date_joined` datetime(6) NOT NULL,
  `fechaNacimiento` date NOT NULL,
  `Direccion` varchar(250) NOT NULL DEFAULT '',
  `Telefono` varchar(10) NOT NULL DEFAULT '',
  `hora_login` datetime DEFAULT NULL,
  `hora_logout` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `auth_user`
--

INSERT INTO `auth_user` (`id`, `password`, `last_login`, `is_superuser`, `username`, `first_name`, `last_name`, `email`, `is_staff`, `is_active`, `date_joined`, `fechaNacimiento`, `Direccion`, `Telefono`, `hora_login`, `hora_logout`) VALUES
(3, 'pbkdf2_sha256$720000$m1TKqvmSILVVZUJXOhKs8Y$dXEypJ7jPT5XBXB/YUR/T5JGSibWIrFGmjiXWMJa004=', '2024-07-16 12:28:06.860951', 0, '1017924962', 'jose', 'romero', 'rjosemiguel787@gmail.com', 0, 1, '2023-11-17 06:36:00.000000', '2005-05-05', 'CL 112 81-74', '3046803586', '2024-07-16 07:28:06', '2024-06-25 07:03:23');

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
(2, 3, 2);

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
-- Estructura de tabla para la tabla `compra`
--

CREATE TABLE `compra` (
  `id_compra` int(11) NOT NULL,
  `Total` int(11) DEFAULT NULL,
  `Fecha_Llegada` datetime DEFAULT NULL,
  `NIT` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_compra`
--

CREATE TABLE `detalle_compra` (
  `Lote` varchar(15) DEFAULT NULL,
  `Precio` int(11) NOT NULL,
  `PrecioU` int(11) NOT NULL,
  `CantidadProductos` int(11) NOT NULL,
  `id_compra` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Disparadores `detalle_compra`
--
DELIMITER $$
CREATE TRIGGER `TotalCompra` AFTER INSERT ON `detalle_compra` FOR EACH ROW begin
declare sum int;
select SUM(Precio) into sum from detalle_compra where id_compra=new.id_compra;
update compra set Total=sum where compra.id_compra=new.id_compra;
update lote set Estado=True where Lote.Loteid=new.Lote;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
  `object_id` longtext DEFAULT NULL,
  `object_repr` varchar(200) NOT NULL,
  `action_flag` smallint(5) UNSIGNED NOT NULL CHECK (`action_flag` >= 0),
  `change_message` longtext NOT NULL,
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
  `app_label` varchar(100) NOT NULL,
  `model` varchar(100) NOT NULL
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
  `app` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
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
  `session_key` varchar(40) NOT NULL,
  `session_data` longtext NOT NULL,
  `expire_date` datetime(6) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `django_session`
--

INSERT INTO `django_session` (`session_key`, `session_data`, `expire_date`) VALUES
('2pgda48nvs8ypx5veze4jff7h55m7l8z', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sIFWQ:TXiOgnZ6Qu6xsxCbeKIDJp321HZeUEbz2oRJsdJKfzQ', '2024-06-15 06:35:50.678006'),
('31kjxeqcgkvbtgdmdio5s37a6zeey5l9', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sJCgJ:9EPEVu_FS54mMs2B0UZicCte6L4_2dvRM0iNXPw2f1A', '2024-06-17 21:45:59.417572'),
('7zdq3dhy3vzncrp6w1tscn1ivgfpmap9', '.eJxVjEEOwiAQRe_C2hBwKIhL9z0DGZhBqgaS0q6Md7dNutDte-__twi4LiWsnecwkbiKszj9sojpyXUX9MB6bzK1usxTlHsiD9vl2Ihft6P9OyjYy7Y21hlk6w2pCHCJKg-RGEArp7SyfkNxQAM2Y3IZkdgmBCb0NjtkLT5f3KE4hA:1rd7zn:4pbBkMd99V9yWe6fJvhlQPXuacr1PVdg1zHieLYO7tg', '2024-03-07 12:16:11.132810'),
('cg4ymx6r8sa4nxtvhd1l0e9soagndh57', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1s55rC:iIlGi1A2fwZZ_bwjAwSnn85f5q28bHZum36Su2Dspcc', '2024-05-09 23:38:54.830193'),
('chyooe62g6zwxcawg5ay7znr7pbekogr', '.eJxVjDsOwjAQBe_iGllr-RtKes5geddrHECOFCdVxN1JpBTQvpl5m4hpXWpcO89xzOIqtLj8bpjoxe0A-ZnaY5I0tWUeUR6KPGmX9ynz-3a6fwc19brX7MArj3pwRpFBRRaQHNGAOVAiwOJBaQPZ6GJAs2Xe5eJDAG-DA_H5AuOAN5s:1sLwFc:SujOw8L_pw82b8l71Hli8lERAN9is4aEjL4Sd2xI17s', '2024-06-25 10:49:44.436241'),
('d7zag99le2kmnj6hbhl7j435r2xjz4m7', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1s2unE:tGWctmgSiVChI_lF9U37j5KOzT6_TW1Sh0bxHcG05Gg', '2024-05-03 23:25:48.318442'),
('drre2v61ei9yc5ekxp4ti0zb13q56kcz', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sJlhR:DCfDRO6ZCXG-x1dRst5e3mMrL_rq27ZJ7-Y5oAqfKaQ', '2024-06-19 11:09:29.702333'),
('e5ooz9enqk4fc9f7bjbhg5au4pf08ckn', '.eJxVjDsOwjAQBe_iGln-hg0lfc5grb1rHEC2FCcV4u4QKQW0b2beSwTc1hK2zkuYSVyEEaffLWJ6cN0B3bHemkytrssc5a7Ig3Y5NeLn9XD_Dgr28q19hkjeQ0KjASFGTd66NPhzdo6MYYhgKWWADFapkVkTqIHsiMYzGfH-AO3qOBI:1r3br7:aOTxIf1Hf47gTaaaK7ia9K2VAOLaQkBpSt5hXONxgHY', '2023-11-30 12:52:25.502416'),
('f2lot3b8mynewz1rw76ssie5zby93xc5', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sI5u8:wVwOOie6UmZo8whPgZKIXf38sfxglT_piFHDpxocSfY', '2024-06-14 20:19:40.421524'),
('fp0qoj4asiuedixif1lqv2p9wgeolvz1', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sJWu4:JAj-9SFGu0nq8sB6z9_jJUoKjoyyrUkEehGekQuAfv8', '2024-06-18 19:21:32.451664'),
('fyldwgfbpqmgtnv4iomeukd0i0tx34j5', 'e30:1rzxwv:FpU4zIMgxjrRVk2zEY-5pLx9q5fnbyj-YzixOs5t5kE', '2024-05-09 12:11:37.859978'),
('hhvo7bow73onn27eow554ktoa3w1azb3', '.eJxVjDsOwjAQBe_iGllr-RtKes5geddrHECOFCdVxN1JpBTQvpl5m4hpXWpcO89xzOIqtLj8bpjoxe0A-ZnaY5I0tWUeUR6KPGmX9ynz-3a6fwc19brX7MArj3pwRpFBRRaQHNGAOVAiwOJBaQPZ6GJAs2Xe5eJDAG-DA_H5AuOAN5s:1sRBo0:RNwOMX5WGylIXGEUQiTjhFhazX13vaeZO7oLgqivY3s', '2024-07-09 22:26:56.944177'),
('hn0o6qq8rtxzidbr2z1ob0ivbcgjgxaa', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sKfGI:2D4dw5cXVaY1JrUivvuhVHvU9qmzky7XNzv7nSpYkk0', '2024-06-21 22:29:10.479350'),
('ielf6q699i8vizx7utdi6og09lwrt75b', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sKGe6:p7qxCCDrb0CYqSdTxhE1LYMIccAoFt18lY_v7us_SVU', '2024-06-20 20:12:06.502499'),
('inea3e07iwpssx3kpfdhxsqytx1y7yc0', '.eJxVjDsOwjAQBe_iGllr-RtKes5geddrHECOFCdVxN1JpBTQvpl5m4hpXWpcO89xzOIqtLj8bpjoxe0A-ZnaY5I0tWUeUR6KPGmX9ynz-3a6fwc19brX7MArj3pwRpFBRRaQHNGAOVAiwOJBaQPZ6GJAs2Xe5eJDAG-DA_H5AuOAN5s:1sQmKL:vgylAnyJxzhhBciUaZ0t795qQj4ybo8gNAbzNB3o_oo', '2024-07-08 19:14:37.955179'),
('k3ppqmyhc2xwts6aykbbcqpcm77jwnh1', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sLVlM:j5lFvs-b_JqzSxw0g-LVoW2neIqjjBv5o00cDca9zVs', '2024-06-24 06:32:44.180204'),
('kjbdpge97ji9ark2ok2fqcj5q2ofkjvf', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sAAaW:ITOpSr_t2bE_IhUAP4G6UMkW9tI6hJ3h-bZnOS7Yjd4', '2024-05-23 23:42:40.700289'),
('klglvjofb1odcfcowdq5g5ip8a0h8r1d', '.eJxVjDsOwjAQBe_iGllr-RtKes5geddrHECOFCdVxN1JpBTQvpl5m4hpXWpcO89xzOIqtLj8bpjoxe0A-ZnaY5I0tWUeUR6KPGmX9ynz-3a6fwc19brX7MArj3pwRpFBRRaQHNGAOVAiwOJBaQPZ6GJAs2Xe5eJDAG-DA_H5AuOAN5s:1sLvae:-fVIYf9uqqiKwYJJjwdAR09wYX1TG9EEdQC4a7fIGxw', '2024-06-25 10:07:24.104964'),
('mebrh7czld1cmnqf68us3qnroeqvu8pk', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1s7dit:oeEBNhMuNRZ354FasIFcNlQ_RdDtfOjCGBVZC1DiBLY', '2024-05-17 00:12:51.562914'),
('muq3be3ljpvxe8fx7fl7fntp5s6jlnbj', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1s7wkl:iEVYmXl2fNiBEvN6RnDAzBtjvXvzk0znfFpX960494Y', '2024-05-17 20:32:03.041359'),
('naln5a4d93phok2ido5avkvwl304lkp4', '.eJxVjDsOwjAQBe_iGln4E-OlpOcM1m68iwPIluKkQtwdIqWA9s3Me6mE61LS2nlOU1Zn5dThdyMcH1w3kO9Yb02PrS7zRHpT9E67vrbMz8vu_h0U7OVbG0_RYBYmB0EYiCAHL5ZOxpCQCAoSWCeB7RBBjmKYeADvrPMRnHp_ABy4ONc:1r46Vg:hyTABNosUu5IRIeC7_OXbEFXXpGHABuF0x2TL6eClt0', '2023-12-01 21:36:20.429767'),
('nhk4relqpow9zu0e7k7bwtg007swuvl0', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sAW5A:3nSisoYIbyB_8F5RGq03NK4IlFKU6REsqLgQcE-hqks', '2024-05-24 22:39:44.973061'),
('nvpjhfh5el8o6oesxchl3frxai0vop4a', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sKPoq:kAoBexzD4NT5igCZNpBQTNaOBPoEGkdq9c_P5HDSn8w', '2024-06-21 05:59:48.167616'),
('smmct7qge5xdj3wv8uro8mpyksi29vyl', '.eJxVjDsOwjAQBe_iGllr-RtKes5geddrHECOFCdVxN1JpBTQvpl5m4hpXWpcO89xzOIqtLj8bpjoxe0A-ZnaY5I0tWUeUR6KPGmX9ynz-3a6fwc19brX7MArj3pwRpFBRRaQHNGAOVAiwOJBaQPZ6GJAs2Xe5eJDAG-DA_H5AuOAN5s:1sThHq:5okwBOcPXP62Xfd1XI5C4yRRvqMtCcD1R4CN8tSychg', '2024-07-16 20:28:06.864350'),
('usbf9f4trkkdqgbzi2vwy9hkt4mos0aa', '.eJxVjDsOwjAQBe_iGln-J0tJzxms9XqNA8iR4qRC3B0ipYD2zcx7iYjbWuPWeYlTFmdhxel3S0gPbjvId2y3WdLc1mVKclfkQbu8zpmfl8P9O6jY67f2BDbQ6IIpSSvPVjmAVELxwINLjg0ab4Gz0t45KKAJiyXCIWAeWYn3B9KoN-I:1sJtFh:0OpGWsn_XWIRDIpUCCmJh9CkRo5JTAJ4ewH16_im_Mo', '2024-06-19 19:13:21.227605'),
('z97y9w84xe499svmt10kj9zypyt1mcxo', '.eJxVzMsOwiAUBNB_YW0IeHt5uHTvNxAuD6kaSEq7Mv67NOlCt3Nm5s2c39bitp4WN0d2YRM7_WbkwzPVHeLD13vjodV1mYnvFX5o57cW0-t6dP8Oiu9lrG02EqW2Z68wkJYmg8AJyJo8iKI2hANjAsCgiSCoSYAZagmjEuzzBc3VN2w:1rY568:pwBOBLr5sXzIPjAIDdGdEiQJrcni-LnhXNv0TbhBkKA', '2024-02-22 14:09:52.270358');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `horas_trabajadas`
--

CREATE TABLE `horas_trabajadas` (
  `id` int(11) NOT NULL,
  `usuario` varchar(150) CHARACTER SET utf8 COLLATE utf8_spanish_ci NOT NULL,
  `fecha` date NOT NULL,
  `horas` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `lote`
--

CREATE TABLE `lote` (
  `id_producto` bigint(20) NOT NULL,
  `Loteid` varchar(15) NOT NULL,
  `Cantidad` int(11) NOT NULL,
  `PrecioC` int(11) NOT NULL,
  `precioV` int(11) NOT NULL,
  `Estado` tinyint(1) DEFAULT 1,
  `fechaVenci` date NOT NULL,
  `fechaModify` date NOT NULL,
  `fechaCreate` date NOT NULL,
  `Notificacion_on` tinyint(4) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
CREATE TRIGGER `PrecioVL` BEFORE UPDATE ON `lote` FOR EACH ROW begin
declare PrecioVL int;
select ((new.PrecioC/new.Cantidad)+((new.PrecioC/new.Cantidad)*((select PrecioU from detalle_compra where Lote=new.Loteid)/100))) into PrecioVL from lote where Loteid=new.Loteid;
if old.precioV=0 Then
if MOD(PrecioVL,50)>0 then 
while MOD(PrecioVL,50)!=0 DO 
set PrecioVL=PrecioVL+1;
end While;
set new.precioV=PrecioVL;
ELSEIF MOD(PrecioVL,50)=0 then
set new.precioV=PrecioVL;
end if;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `temp_compra`
--

CREATE TABLE `temp_compra` (
  `id_compra` int(11) NOT NULL,
  `Total` int(11) NOT NULL,
  `Fecha_Llegada` datetime DEFAULT NULL,
  `NIT` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `temp_detalle_compra`
--

CREATE TABLE `temp_detalle_compra` (
  `Lote` varchar(15) DEFAULT NULL,
  `Precio` int(11) NOT NULL,
  `PrecioU` int(11) NOT NULL,
  `CantidadProductos` int(11) NOT NULL,
  `id_compra` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `temp_lote`
--

CREATE TABLE `temp_lote` (
  `id_producto` bigint(20) NOT NULL,
  `Loteid` varchar(15) NOT NULL,
  `Cantidad` int(11) NOT NULL,
  `PrecioC` int(11) NOT NULL,
  `precioV` int(11) NOT NULL,
  `Estado` tinyint(1) DEFAULT 1,
  `fechaVenci` date NOT NULL,
  `fechaModify` date NOT NULL,
  `fechaCreate` date NOT NULL,
  `Notificacion_on` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT de la tabla `auth_user_groups`
--
ALTER TABLE `auth_user_groups`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

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
-- AUTO_INCREMENT de la tabla `horas_trabajadas`
--
ALTER TABLE `horas_trabajadas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=62;

--
-- AUTO_INCREMENT de la tabla `pedidos_especiales`
--
ALTER TABLE `pedidos_especiales`
  MODIFY `id_pedido` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `temp_compra`
--
ALTER TABLE `temp_compra`
  MODIFY `id_compra` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT de la tabla `venta`
--
ALTER TABLE `venta`
  MODIFY `id_venta` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=67;

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
