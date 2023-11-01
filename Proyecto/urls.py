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
from django.urls import path
from .views import producto,viewP,update,esatdoI,esatdoA,Stock,menu,viewProveedor,updateProveedor,proveedorInsert,proveedorEstadoI,proveedorEstadoA,viewPedidos,pedidosEstadoA,pedidosEstadoI,pedidosInsert


urlpatterns = [
    path('admin/', admin.site.urls),
    path('Producto/insert', producto),
    path('Producto/lista',viewP),
    path('Producto/actualizar/<int:id>,<str:lote>',update),
    path('Producto/EI/<int:id>',esatdoI),
    path('Producto/EA/<int:id>',esatdoA),
    path('menu',menu),
    path('Proveedor/lista',viewProveedor),
    path('Proveedor/actualizar/<int:id>',updateProveedor),
    path('Proveedor/insert',proveedorInsert),
    path('Proveedor/EI/<int:id>',proveedorEstadoI),
    path('Proveedor/EA/<int:id>',proveedorEstadoA),
    path('Pedidos/lista',viewPedidos),
    path('Pedidos/EI/<int:id>',pedidosEstadoI),
    path('Pedidos/EA/<int:id>',pedidosEstadoA),
    path('Pedidos/insert',pedidosInsert),







    


    path('Producto/stock',Stock),
]
