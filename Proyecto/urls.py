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
from .views import producto,viewP,viewL,update,esatdoI,esatdoA,menu,viewProveedor,updateProveedor,proveedorInsert,proveedorEstadoI,proveedorEstadoA,viewPedidos,pedidosEstadoA,pedidosEstadoI,pedidosInsert,estadoaL,estadoiL,viewUsuario,usuarioEstadoI,usuarioEstadoA,usuarioInsert,updateUsuario,updateLote,pedidosEstadoC,pedidosEstadoR,viewPedidosC,updatePedidos,inicio,Notificacion,updateUsuarioContrasena,usuarioRolA,usuarioRolR,RProveedor1,RProveedor2,Cproveedor,crearR,RProducto,Cproducto,LoteInsert,reciboCompraView,LoteUpdate,Recibos,RecibosD, Recibos_Finalizar,Recibos_Cancelar


urlpatterns = [
    path('admin/', admin.site.urls),
    path('Producto/insert', producto),
    path('Producto/lista',viewP),
    path('Producto/actualizar/<int:id>',update),
    path('Producto/EI/<int:id>',esatdoI),
    path('Producto/EA/<int:id>',esatdoA),
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
    path('Compra/Recibos',Recibos),
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
    path('Usuario/actualizar/contrasena/<int:id>',updateUsuarioContrasena),

    #lote
    path('Producto/listal/<int:id>',viewL),
    path('Producto/LEI/<int:id>/<str:lote>',estadoiL),
    path('Producto/LEA/<int:id>/<str:lote>',estadoaL),
    path('Producto/actualizarL/<int:id>/<str:lote>',updateLote),
    #dos lineas de login
    path('accounts/login/',inicio, name='login'),
    path('accounts/',include('django.contrib.auth.urls')),
    path('salir/', views.salir, name="salir"),
]
