"""
URL configuration for EjemploDjangoFreddy project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from . import views
from django.urls import path, include
from .views import producto,viewP,viewL,update,esatdoI,cambiarpassword,esatdoA,menu,viewProveedor,updateProveedor,proveedorInsert,proveedorEstadoI,proveedorEstadoA,viewPedidos,pedidosEstadoA,pedidosEstadoI,pedidosInsert,estadoaL,estadoiL,viewUsuario,usuarioEstadoI,usuarioEstadoA,usuarioInsert,updateUsuario,updateLote,pedidosEstadoC,pedidosEstadoR,viewPedidosC,updatePedidos,inicio,Notificacion,updateUsuarioContrasena,usuarioRolA,usuarioRolR,RProveedor1,RProveedor2,Cproveedor,crearR,RProducto,Cproducto,LoteInsert,reciboCompraView,LoteUpdate,Recibos,RecibosD, Recibos_Finalizar,Recibos_Cancelar,registro_venta,producto_API,registo_detalleVenta,venta_crear_factura, estadisticas
from .views import venta_eliminar_API,venta_Cancelar_API,venta_DONE,venta_dias,venta_Info
from django.contrib.auth import views as auth_views
from django.urls import path


urlpatterns = [
    path('admin/', admin.site.urls),
    path('Producto/insert', producto),
    path('Producto/lista',viewP),
    path('Producto/actualizar/<int:id>',update),
    path('Producto/EI/<int:id>',esatdoI),
    path('Producto/EA/<int:id>',esatdoA),
    path('Producto/API/<int:codigo>',producto_API),
    #menu
    path('',menu),
    #notificacion
    path('Notificacion',Notificacion),
    #Recibo compra
    path('Compra/SProveedor1',RProveedor1),
    path('Compra/SProveedor2',RProveedor2),
    path('Compra/CProveedor',Cproveedor),
    path('Compra/create/<int:NIT>',crearR),
    path('Compra/Producto/<int:idc>',RProducto),
    path('Compra/CProducto/<int:idc>',Cproducto),
    path('Compra/lote/<int:idc>/<int:idp>',LoteInsert),
    path('Compra/loteA/<int:idc>/<str:idl>',LoteUpdate),
    path('Compra/Lista/<int:idc>',reciboCompraView),
    path('Compra/Recibos/<int:pag>',Recibos),
    path('Compra/Recibos/Finalizar',Recibos_Finalizar),
    path('Compra/Recibos/Cancelar',Recibos_Cancelar),
    path('Compra/Recibo/<int:idc>',RecibosD),
    #proveedor
    path('Proveedor/lista',viewProveedor),
    path('Proveedor/actualizar/<int:id>',updateProveedor),
    path('Proveedor/insert',proveedorInsert),
    path('Proveedor/EI/<int:id>',proveedorEstadoI),
    path('Proveedor/EA/<int:id>',proveedorEstadoA),
    #pedidos
    path('Pedidos/lista',viewPedidos),
    path('Pedidos/listaC',viewPedidosC),
    path('Pedidos/actualizar/<int:id>',updatePedidos),
    path('Pedidos/EI/<int:id>',pedidosEstadoI),
    path('Pedidos/EA/<int:id>',pedidosEstadoA),
    path('Pedidos/EC/<int:id>',pedidosEstadoC),
    path('Pedidos/ER/<int:id>',pedidosEstadoR),

    path('Pedidos/insert',pedidosInsert),
    #usuario
    path('Usuario/lista',viewUsuario),
    path('Usuario/EI/<int:id>',usuarioEstadoI),
    path('Usuario/EA/<int:id>',usuarioEstadoA),
    path('Usuario/RA/<int:id>',usuarioRolA),
    path('Usuario/RR/<int:id>',usuarioRolR),
    path('Usuario/insert',usuarioInsert),
    path('Usuario/actualizar/<int:id>',updateUsuario),
    path('Usuario/actualizar/contrasena/<str:id>',updateUsuarioContrasena),

    #lote
    path('Producto/listal/<int:id>',viewL),
    path('Producto/LEI/<int:id>/<str:lote>',estadoiL),
    path('Producto/LEA/<int:id>/<str:lote>',estadoaL),
    path('Producto/actualizarL/<int:id>/<str:lote>',updateLote),
    #login
    path('accounts/login/',inicio, name='login'),
    path('salir/', views.salir, name="salir"),
    path('cambiarcontraseña/<str:username>',cambiarpassword),
    #recuperacion de contraseña 
    path('reset_password/', auth_views.PasswordResetView.as_view(template_name="reset_password/reset_password.html", email_template_name="reset_password/reset_password_email.html", subject_template_name = 'password_reset_subject.txt'), name="password_reset"),
    path('reset_password_sent/', auth_views.PasswordResetDoneView.as_view(template_name="reset_password/reset_password_sent.html"), name = "password_reset_done"),
    path('reset/<uidb64>/<token>', auth_views.PasswordResetConfirmView.as_view(template_name="reset_password/reset.html"), name = 'password_reset_confirm'),
    path('reset_password_complete/', auth_views.PasswordResetCompleteView.as_view(template_name="reset_password/reset_password_complete.html"), name = 'password_reset_complete'),
    #venta
    path('Venta/registrar',registro_venta),
    path('Venta/API/crear/<int:user>',venta_crear_factura),
    path('Venta/API/detalle/<int:idP>/<int:Cant><int:Posi>',registo_detalleVenta),
    path('Venta/API/eliminar/<int:idV><int:posi>',venta_eliminar_API),
    path('Venta/API/Cancelar/<int:idV>',venta_Cancelar_API),
    path('Venta/Terminar/API/<int:idV>/<int:efectivo>',venta_DONE),
    path('Venta/Dias',venta_dias),
    path('Venta/Info/<str:fecha>',venta_Info),
    #estadisticas
    path('estadisticas',estadisticas),
]
