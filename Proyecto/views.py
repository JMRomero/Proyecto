from itertools import product
from django.shortcuts import render,redirect
from django.db import connection
from django.contrib.auth.decorators import login_required
from django.contrib.auth import logout
from django.contrib.auth.models import User,Group
from django.contrib.auth.hashers import make_password
from django.contrib.auth import authenticate, login
from django.contrib import messages
from django.db.models import Q
from Proyecto.models import Producto

from plyer import notification

def group_iden(request):
    grupos_usuario = request.user.groups.all()
    for grupo in grupos_usuario:
        grupoA=grupo.name
        return grupoA
#login
def inicio(request):
    if request.method == 'POST':
        username = request.POST['username']
        password = request.POST['password']
        user = authenticate(request, username=username, password=password)
        if user is not None:
            login(request, user)
            # Usuario autenticado con éxito
            return redirect('/')  # Redirige a la página de inicio
        else:
            # Autenticación fallida, agregamos un mensaje de error a la URL
            messages.error(request, 'Usuario o contraseña incorrectos')
            return redirect('login')
    else:
        return render(request, 'registration/login.html')
@login_required
def menu(request):
    grupo_actual= group_iden(request)
    return render(request,'Menu/menu.html',{'group':grupo_actual})
#producto
@login_required
def producto(request):
    if request.method=="POST":
        if request.POST.get('codigo') and request.POST.get('nombre')  and request.POST.get('gramo_litro')  and request.POST.get('Max') and request.POST.get('Min'):
            ##Captura la infromacion, conecte a la base de datos y ejecute el insert
            insert=connection.cursor()
            insert.execute("INSERT INTO producto (id_producto,Nombre,GramoLitro,Max,Min)VALUES("+request.POST.get('codigo')+",'"+request.POST.get('nombre')+"','"+request.POST.get('gramo_litro')+"',"+request.POST.get('Max')+","+request.POST.get('Min')+")")
            return redirect('/Producto/lista')
    else:
        grupo_actual= group_iden(request)
        return render(request,'Producto/insertar.html',{'group':grupo_actual})
@login_required
def viewP(request):
    if request.method == 'POST':
        viewA=connection.cursor()
        v=request.POST.get("qp")
        vv=[caracter.isdigit() for caracter in v]
        if all(vv):
            viewA.execute("select *, CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End as cantidad from producto where estado=True and id_producto LIKE '%"+str(request.POST.get("qp"))+"%';")
        else:
            viewA.execute("select *, CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End as cantidad from producto where estado=True and Nombre LIKE '%"+str(request.POST.get("qp"))+"%';")
        activos=viewA.fetchall()
        viewI=connection.cursor()
        viewI.execute("select *, CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End as cantidad from producto where estado=False;")
        inactivos=viewI.fetchall()
    else:
        viewA=connection.cursor()
        viewA.execute("select *, CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End as cantidad from producto where estado=True;")
        activos=viewA.fetchall()
        viewI=connection.cursor()
        viewI.execute("select *, CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End as cantidad from producto where estado=False;")
        inactivos=viewI.fetchall()
    grupo_actual= group_iden(request)
    return render(request,'Producto/lista.html',{'productoA':viewA,'productoI':viewI,'activos':activos,'inactivos':inactivos,'group':grupo_actual})
@login_required
def viewL(request,id):
    viewLA=connection.cursor()
    viewLA.execute("select *,format(PrecioC,'###.###.###.###'),format(PrecioV,'###.###.###.###') from Lote where id_producto="+str(id)+" and Estado=1")
    activos=viewLA.fetchall() 
    viewLI=connection.cursor()
    viewLI.execute("select *,format(PrecioC,'###.###.###.###'),format(PrecioV,'###.###.###.###') from Lote where id_producto="+str(id)+" and Estado=0")
    inactivos=viewLI.fetchall()
    with connection.cursor() as cursor:
        cursor.execute("SELECT Estado FROM producto WHERE id_producto="+str(id)+";")  # Me consulta a la hora de cambiar un lote, si el producto al que esta asignado el lote esta activo, para hacer la validacion en el html y dejar o no activar
        impEA = cursor.fetchone()[0]#guarda el booleano
    with connection.cursor() as cursor:
        cursor.execute("select timestampdiff(day,fechaVenci,now()) from lote where id_producto="+str(id)+" and Estado=False;") 
        dias = [row[0] for row in cursor.fetchall()]
        Lvenci=[valor<0 if valor is not None else False for valor in dias]
    ListacombinadaI=list(zip(viewLI,Lvenci))
    grupo_actual= group_iden(request)

    return render(request,'lote/listaL.html',{'LoteA':viewLA,'Diff_L':ListacombinadaI,'Diff_LA':viewLA,'estado':impEA,'fvenci':Lvenci,'activos':activos,'inactivos':inactivos,'group':grupo_actual})


@login_required
def update(request,id):
    if request.method=="POST":
        if request.POST.get('codigo') and request.POST.get('nombre')  and request.POST.get('gramo_litro')  and request.POST.get('Max') and request.POST.get('Min'):
            ##Captura la infromacion, conecte a la base de datos y ejecute el insert
            insert=connection.cursor()
            insert.execute("UPDATE producto SET id_producto="+request.POST.get('codigo')+",Nombre='"+request.POST.get('nombre')+"',GramoLitro='"+request.POST.get('gramo_litro')+"',Fecha_Modificacion=now(),Max="+request.POST.get('Max')+",Min="+request.POST.get('Min')+" where id_producto="+str(id)+";")
            return redirect('/Producto/lista')
    else:
        consulta=connection.cursor()
        consulta.execute("select *from producto where id_producto="+str(id)+";")
        grupo_actual= group_iden(request)
        return render(request,'Producto/actualizar.html',{'datos':consulta,'group':grupo_actual})
@login_required
def esatdoI(request,id):
    estadoI=connection.cursor()
    estadoI.execute("UPDATE producto SET Estado=True where id_producto="+str(id)+"")
    return redirect('/Producto/lista')
@login_required
def esatdoA(request,id):
    estadoA=connection.cursor()
    estadoA.execute("UPDATE producto SET Estado=False where id_producto="+str(id)+"")
    return redirect('/Producto/lista')
@login_required
def estadoiL(request,id,lote):
    estadoiL=connection.cursor()
    estadoiL.execute(f"UPDATE Lote SET Estado=True WHERE id_producto={str(id)} and Loteid='{str(lote)}'")
    return redirect(f'/Producto/listal/{str(id)}')
@login_required
def estadoaL(request,id,lote):
    estadoiL=connection.cursor()
    estadoiL.execute(f"UPDATE Lote SET Estado=False WHERE id_producto={str(id)} and Loteid='{str(lote)}'")
    return redirect(f'/Producto/listal/{str(id)}')




#proveedor
@login_required
def viewProveedor(request):
    viewA=connection.cursor()
    viewA.execute("select * from proveedor where Estado=1;")
    activos=viewA.fetchall()
    viewI=connection.cursor()
    viewI.execute("select * from proveedor where Estado=0;")
    inactivos=viewI.fetchall()
    grupo_actual= group_iden(request)
    return render(request,'Proveedor/lista.html',{'proveedorA':viewA,'proveedorI':viewI,'activos':activos,'inactivos':inactivos,'group':grupo_actual})
@login_required
def updateProveedor(request,id):
    if request.method=="POST":
        if request.POST.get('nit') and request.POST.get('nombre') and  request.POST.get('telefono') and request.POST.get('horario_atencion') and request.POST.get('politica_devolucion'):
            insert=connection.cursor()
            insert.execute("UPDATE proveedor SET NIT="+request.POST.get('nit')+",Nombre='"+request.POST.get('nombre')+"',Telefono="+request.POST.get('telefono')+",Politica_Devolucion='"+request.POST.get('politica_devolucion')+"' where NIT="+str(id)+";")
            return redirect('/Proveedor/lista')
    else:
        consulta=connection.cursor()
        consulta.execute("select * from proveedor where NIT="+str(id)+";")
        grupo_actual= group_iden(request)
        return render(request,'Proveedor/actualizar.html',{'datos':consulta,'group':grupo_actual})
@login_required    
def proveedorInsert(request):
    if request.method=="POST":
        if request.POST.get('nit') and request.POST.get('nombre') and  request.POST.get('telefono') and request.POST.get('horario_atencion') and request.POST.get('politica_devolucion'):
            insert=connection.cursor()
            insert.execute("INSERT INTO proveedor (NIT,Nombre,Telefono,Horario_Atencion,Politica_Devolucion) VALUES("+request.POST.get('nit')+",'"+request.POST.get('nombre')+"',"+request.POST.get('telefono')+",'"+request.POST.get('horario_atencion')+"','"+request.POST.get('politica_devolucion')+"')")
            return redirect('/Proveedor/lista')
    else:
        grupo_actual= group_iden(request)
        return render(request,'Proveedor/insertar.html',{'group':grupo_actual})
@login_required    
def proveedorEstadoI(request,id):
    estadoI=connection.cursor()
    estadoI.execute("UPDATE proveedor SET Estado=0 where NIT="+str(id)+"")
    return redirect('/Proveedor/lista')
@login_required
def proveedorEstadoA(request,id):
    estadoA=connection.cursor()
    estadoA.execute("UPDATE proveedor SET Estado=1 where NIT="+str(id)+"")
    return redirect('/Proveedor/lista')

#lote
@login_required
def viewLote(request,id):
    viewA=connection.cursor()
    viewA.execute("select producto.*, vencimiento.fechaV,vencimiento.LoteP,vencimiento.Cantidad from producto inner join vencimiento on vencimiento.id_producto=producto.id_producto where producto.Estado=0; and producto.id")
    viewI=connection.cursor()
    viewI.execute("select producto.*, vencimiento.fechaV,vencimiento.LoteP,vencimiento.Cantidad from producto inner join vencimiento on vencimiento.id_producto=producto.id_producto where producto.Estado=1;")
    grupo_actual= group_iden(request)
    return render(request,'Producto/lista.html',{'productoA':viewA,'productoI':viewI,'group':grupo_actual})
@login_required
def updateLote(request,id,lote):
    if request.method=="POST":
        if request.POST.get('codigo') and request.POST.get('cantidad') and  request.POST.get('precioC') and request.POST.get('precioV') and request.POST.get('fechaVenci'):
            insert=connection.cursor()
            insert.execute("UPDATE lote SET Loteid='"+request.POST.get('codigo')+"',Cantidad='"+request.POST.get('cantidad')+"',PrecioC="+request.POST.get('precioC')+",PrecioV='"+request.POST.get('precioV')+"',fechaVenci='"+request.POST.get('fechaVenci')+"' where Loteid='"+str(lote)+"'")
            return redirect('/Producto/listal/'+str(id)+'')
    else:
        consulta=connection.cursor()
        consulta.execute("select * from lote where Loteid='"+str(lote)+"';")
        grupo_actual= group_iden(request)
        return render(request,'lote/actualizar.html',{'datos':consulta,'group':grupo_actual})
               
#pedidos especiales
@login_required
def viewPedidos(request):
    viewA=connection.cursor()
    viewA.execute("SELECT *,(SELECT first_name FROM auth_user WHERE pedidos_especiales.Cedula=auth_user.username) FROM pedidos_especiales where estadoPe=1;")
    activos=viewA.fetchall()
    viewI=connection.cursor()
    viewI.execute("SELECT *,(SELECT first_name FROM auth_user WHERE pedidos_especiales.Cedula=auth_user.username) FROM pedidos_especiales where estadoPe=0;")
    inactivos=viewI.fetchall()
    grupo_actual= group_iden(request)
    return render(request,'Pedidos/lista.html',{'pedidosA':viewA,'pedidosI':viewI,'activos':activos,'inactivos':inactivos,'group':grupo_actual})
@login_required
def pedidosInsert(request):
    if request.method=="POST":
        if request.POST.get('nombreClie') and  request.POST.get('celularClie') and request.POST.get('descripcion') and request.POST.get('cantidad'):
            cedu = request.user.username
            insert=connection.cursor()
            insert.execute("INSERT INTO pedidos_especiales (Cedula,nombreClie,celularClie,descripcion,fechaP,Cantidad,fechaM) VALUES("+str(cedu)+",'"+request.POST.get('nombreClie')+"',"+request.POST.get('celularClie')+",'"+request.POST.get('descripcion')+"',now(),"+request.POST.get('cantidad')+",now())")
            return redirect('/Pedidos/lista')
    else:
        grupo_actual= group_iden(request)
        return render(request,'Pedidos/insertar.html',{'group':grupo_actual})
@login_required    
def pedidosEstadoI(request,id):
    estadoI=connection.cursor()
    estadoI.execute("UPDATE pedidos_especiales SET estadoPe=0 where id_pedido="+str(id)+"")
    return redirect('/Pedidos/lista')
@login_required
def pedidosEstadoA(request,id):
    estadoA=connection.cursor()
    estadoA.execute("UPDATE pedidos_especiales SET estadoPe=1 where id_pedido="+str(id)+"")
    return redirect('/Pedidos/lista')
@login_required
def pedidosEstadoC(request,id):
    estadoA=connection.cursor()
    estadoA.execute("UPDATE pedidos_especiales SET estadoPe=2 where id_pedido="+str(id)+"")
    return redirect('/Pedidos/lista')
@login_required
def pedidosEstadoR(request,id):
    estadoA=connection.cursor()
    estadoA.execute("UPDATE pedidos_especiales SET estadoPe=0 where id_pedido="+str(id)+"")
    return redirect('/Pedidos/listaC')
@login_required
def viewPedidosC(request):
    viewC=connection.cursor()
    viewC.execute("SELECT *,(SELECT first_name FROM auth_user WHERE pedidos_especiales.Cedula=auth_user.username) FROM pedidos_especiales where estadoPe=2;")
    Concluidos=viewC.fetchall()
    grupo_actual= group_iden(request)
    return render(request,'Pedidos/listaC.html',{'pedidosC':viewC,'concluidos':Concluidos,'group':grupo_actual})
@login_required
def updatePedidos(request,id):
    if request.method=="POST":
        if request.POST.get('celularClie') and request.POST.get('cantidad') and  request.POST.get('descripcion'):
            insert=connection.cursor()
            insert.execute("UPDATE pedidos_especiales SET celularClie='"+request.POST.get('celularClie')+"',fechaM=now(),descripcion='"+request.POST.get('descripcion')+"',Cantidad="+request.POST.get('cantidad')+" where id_pedido="+str(id)+";")
            estado=connection.cursor()
            estado.execute("select estadoPe from pedidos_especiales where id_pedido="+str(id)+";")
            Es=estado.fetchone()
            for E in Es:
                if E == 2:
                    return redirect('/Pedidos/listaC')
                else:
                    return redirect('/Pedidos/lista')
    else:
        consulta=connection.cursor()
        consulta.execute("select * from pedidos_especiales where id_pedido="+str(id)+";")
        grupo_actual= group_iden(request)
        return render(request,'Pedidos/actualizar.html',{'datos':consulta,'group':grupo_actual})
#usuarios
@login_required
def viewUsuario(request):
    viewA=connection.cursor()
    viewA.execute("SELECT auth_user.*, auth_group.name FROM auth_user INNER JOIN auth_user_groups ON auth_user.id=auth_user_groups.user_id INNER JOIN auth_group on auth_group.id=auth_user_groups.group_id WHERE auth_user.is_active=True;")
    activos=viewA.fetchall()
    viewI=connection.cursor()
    viewI.execute("SELECT auth_user.*, auth_group.name FROM auth_user INNER JOIN auth_user_groups ON auth_user.id=auth_user_groups.user_id INNER JOIN auth_group on auth_group.id=auth_user_groups.group_id WHERE auth_user.is_active=False;")
    inactivos=viewI.fetchall()
    grupo_actual= group_iden(request)
    return render(request,'Usuario/lista.html',{'usuarioA':viewA,'usuarioI':viewI,'activos':activos,'inactivos':inactivos,'group':grupo_actual})
@login_required
def usuarioEstadoI(request,id):
    estadoI=connection.cursor()
    estadoI.execute("UPDATE auth_user SET is_active=0 where username="+str(id)+"")
    return redirect('/Usuario/lista')
@login_required
def usuarioEstadoA(request,id):
    estadoA=connection.cursor()
    estadoA.execute("UPDATE auth_user SET is_active=1 where username="+str(id)+"")
    return redirect('/Usuario/lista')
@login_required
def usuarioInsert(request):
    if request.method=="POST":

        if request.POST.get('cedula') and request.POST.get('nombre') and request.POST.get('apellido') and request.POST.get('telefono') and request.POST.get('correo')and request.POST.get('direccion')and request.POST.get('fecha_nacimiento')and request.POST.get('Id_rol')and request.POST.get('contrasena'):
            password = (request.POST.get('contrasena'))
            hashed_password = make_password(password)
            insert=connection.cursor()
            insert.execute("INSERT INTO auth_user (username,first_name,last_name,Telefono,email,Direccion,fechaNacimiento,date_joined,password) VALUES("+request.POST.get('cedula')+",'"+request.POST.get('nombre')+"','"+request.POST.get('apellido')+"',"+request.POST.get('telefono')+",'"+request.POST.get('correo')+"','"+request.POST.get('direccion')+"','"+request.POST.get('fecha_nacimiento')+"',now(),'"+str(hashed_password)+"');")
            insertgroup=connection.cursor()
            insertgroup.execute("INSERT INTO auth_user_groups (user_id,group_id) values((select id from auth_user where username="+request.POST.get('cedula')+"),"+request.POST.get('Id_rol')+");")
            return redirect('/Usuario/lista')
    else:
        grupo_actual= group_iden(request)
        return render(request,'Usuario/insertar.html',{'group':grupo_actual})
@login_required
def updateUsuario(request,id):
    if request.method=="POST":
        if request.POST.get('cedula') and request.POST.get('nombre') and request.POST.get('apellido') and  request.POST.get('telefono') and request.POST.get('correo') and request.POST.get('direccion') and request.POST.get('fecha_nacimiento'):
            insert=connection.cursor()
            insert.execute("UPDATE auth_user SET username="+request.POST.get('cedula')+",first_name='"+request.POST.get('nombre')+"',last_name='"+request.POST.get('apellido')+"',Telefono="+request.POST.get('telefono')+",email='"+request.POST.get('correo')+"',Direccion='"+request.POST.get('direccion')+"',fechaNacimiento='"+request.POST.get('fecha_nacimiento')+"' where username="+str(id)+";")
            return redirect('/Usuario/lista')
    else:
        consulta=connection.cursor()
        consulta.execute("select * from auth_user where username="+str(id)+";")
        grupo_actual= group_iden(request)
        return render(request,'Usuario/actualizar.html',{'datos':consulta,'group':grupo_actual})
@login_required
def updateUsuarioContrasena(request,id):
    if request.method == 'POST':
        if request.POST.get('contrasena') and request.POST.get('confirmar_contrasena'):
            password=request.POST.get('contrasena')
            hashed_password=make_password(password)
            insert=connection.cursor()
            insert.execute("Update auth_user SET password='"+str(hashed_password)+"' where username='"+str(id)+"'")
            return redirect('/Usuario/lista')
    else:
        usuariodata=connection.cursor()
        usuariodata.execute("select username,first_name,last_name from auth_user where username="+str(id)+";")
        grupo_actual= group_iden(request)
        return render(request,"Usuario/insertar_contra.html",{'datos':usuariodata,'group':grupo_actual})
@login_required
def usuarioRolA(request,id):
    rol=connection.cursor()
    rol.execute("UPDATE auth_user_groups SET group_id=2 where user_id=(select id from auth_user where username="+str(id)+")")
    return redirect('/Usuario/lista')
@login_required
def usuarioRolR(request,id):
    rol=connection.cursor()
    rol.execute("UPDATE auth_user_groups SET group_id=1 where user_id=(select id from auth_user where username="+str(id)+")")
    return redirect('/Usuario/lista')
#Notificaciones
@login_required
def Notificacion(request):
    PROMin=connection.cursor()
    PROMin.execute("call Producto_Min")
    PROCero=connection.cursor()
    PROCero.execute("call Producto_cero")
    LOTEvencer=connection.cursor()
    LOTEvencer.execute("call Lotes_Vencer")
    LOTEvencido=connection.cursor()
    LOTEvencido.execute("call Lotes_vencidos")
    grupo_actual= group_iden(request)
    return render(request,'Notificacion/Notificaciones.html',{'PM':PROMin,'PC':PROCero,'LV':LOTEvencer,'LVV':LOTEvencido,'group':grupo_actual})

#recibo de compra
@login_required
def RProveedor1(request):
    vaciar=connection.cursor()
    vaciar.execute("DELETE FROM temp_proveedor;")
    vaciar.execute("DELETE FROM temp_producto;")
    vaciar.execute("DELETE FROM temp_lote;")
    vaciar.execute("DELETE FROM temp_compra;")
    vaciar.execute("DELETE FROM temp_detalle_compra;")
    return redirect('/Compra/SProveedor2')
def RProveedor2(request):
    proveedor=connection.cursor()
    proveedor.execute("select NIT,Nombre from proveedor  where proveedor.Estado=True;")
    grupo_actual= group_iden(request)
    return render(request,'ReciboCompra/Proveedor.html',{'PROV':proveedor,'group':grupo_actual})
@login_required
def Cproveedor(request):
    if request.method=="POST":
        if request.POST.get('nit') and request.POST.get('nombre') and  request.POST.get('telefono') and request.POST.get('horario_atencion') and request.POST.get('politica_devolucion'):
            nit=request.POST.get('nit')
            insert=connection.cursor()
            insert.execute("INSERT INTO temp_proveedor (NIT,Nombre,Telefono,Horario_Atencion,Politica_Devolucion) VALUES("+request.POST.get('nit')+",'"+request.POST.get('nombre')+"',"+request.POST.get('telefono')+",'"+request.POST.get('horario_atencion')+"','"+request.POST.get('politica_devolucion')+"')")
            return redirect(f'/Compra/create/{nit}')
    else:
        grupo_actual= group_iden(request)
        return render(request,'ReciboCompra/Nproveedor.html',{'group':grupo_actual})
@login_required
def crearR(request,NIT):
    compra=connection.cursor()
    compra.execute(f"insert into temp_compra (id_compra,Fecha_Llegada,NIT) Values((select COUNT(id_compra)+1 from compra),now(),{NIT});")
    idc=connection.cursor()
    idc.execute("select COUNT(id_compra)+1 from compra;")
    idc2=idc.fetchone()
    for idc3 in idc2:
        return redirect(f'/Compra/Producto/{idc3}')
@login_required
def RProducto(request,idc):
    prod=connection.cursor()
    prod.execute("select id_producto,Nombre from Producto where Estado=True;")
    prod2=connection.cursor()
    prod2.execute("select id_producto, Nombre from temp_producto where Estado=True;")
    info=connection.cursor ()
    info.execute("select * from temp_compra where id_compra="+str(idc)+";")
    info2=info.fetchall()
    grupo_actual= group_iden(request)
    return render(request,'ReciboCompra/Producto.html',{'PROD':prod,'PROD2':prod2,'RC':str(idc),'info':info2,'group':grupo_actual})
@login_required
def Cproducto(request,idc):
   if request.method=="POST":
        if request.POST.get('codigo') and request.POST.get('nombre')  and request.POST.get('gramo_litro')  and request.POST.get('Max') and request.POST.get('Min'):
            id=request.POST.get('codigo')
            insert=connection.cursor()
            insert.execute("INSERT INTO temp_producto (id_producto,Nombre,GramoLitro,Max,Min)VALUES("+request.POST.get('codigo')+",'"+request.POST.get('nombre')+"','"+request.POST.get('gramo_litro')+"',"+request.POST.get('Max')+","+request.POST.get('Min')+")")
            return redirect(f'/Compra/lote/{idc}/{id}')
   else:
        info=connection.cursor ()
        info.execute("select * from temp_compra where id_compra="+str(idc)+";")
        info2=info.fetchall()
        grupo_actual= group_iden(request)
        return render(request,'ReciboCompra/Nproducto.html',{'RC':idc,'info':info2,'group':grupo_actual})
@login_required
def LoteInsert(request,idc,idp):
    if request.method == 'POST':
        if request.POST.get('Lote') and request.POST.get('Cantidad') and request.POST.get('PrecioC') and request.POST.get('PrecioV') and request.POST.get('FechaVenci'):
            lote=connection.cursor()
            lote.execute("Insert into temp_lote (id_producto,Loteid,Cantidad,PrecioC,Estado,fechaVenci,fechaModify,fechaCreate) values("+str(idp)+",'"+request.POST.get('Lote')+"',"+request.POST.get('Cantidad')+","+request.POST.get('PrecioC')+",True,'"+request.POST.get('FechaVenci')+"',Now(),now());")
            detalle=connection.cursor()
            detalle.execute("Insert into temp_detalle_compra values('"+request.POST.get('Lote')+"',"+request.POST.get('PrecioC')+","+request.POST.get('PrecioV')+","+request.POST.get('Cantidad')+","+str(idc)+");")
            return redirect (f'/Compra/Lista/{idc}')
    else:
        info=connection.cursor ()
        info.execute("select * from temp_compra where id_compra="+str(idc)+";")
        info2=info.fetchall()
        grupo_actual= group_iden(request)
        return render(request,'ReciboCompra/Loteinsertar.html',{'RC':idc,'info':info2,'group':grupo_actual})
@login_required   
def reciboCompraView(request,idc):
    idc2=idc
    lote=connection.cursor()
    lote.execute("select temp_detalle_compra.*,temp_lote.fechaVenci,temp_lote.id_producto from temp_detalle_compra inner join temp_lote on temp_detalle_compra.Lote=temp_lote.loteid where temp_detalle_compra.id_compra="+str(idc2)+";")
    lote2=lote.fetchall()
    info=connection.cursor()
    info.execute("select * from temp_compra where id_compra="+str(idc)+";")
    info2=info.fetchall()
    grupo_actual= group_iden(request)
    return render(request,'ReciboCompra/CompraVisualizar.html',{'RC':lote2,'info':info2,'idc':idc2,'group':grupo_actual})
@login_required
def Recibos(request):
    recibos=connection.cursor()
    recibos.execute("select compra.*,Proveedor.Nombre,format(Compra.Total,'###.###.###.###') from compra inner join proveedor on compra.NIT=Proveedor.NIT;")
    grupo_actual= group_iden(request)
    return render(request,'ReciboCompra/ListaR.html',{'RC':recibos,'group':grupo_actual})
@login_required
def RecibosD(request,idc):
    recibo=connection.cursor()
    recibo.execute("select detalle_compra.*,Producto.Nombre,Lote.fechaVenci,Lote.id_producto,format(detalle_compra.Precio,'###.###.###.###'),format(detalle_compra.PrecioU,'###.###.###.###') from detalle_compra inner join Lote on detalle_compra.Lote=Lote.loteid inner join producto on Lote.id_producto=Producto.id_producto where detalle_compra.id_compra="+str(idc)+";")
    grupo_actual= group_iden(request)
    return render(request,'ReciboCompra/ListaRD.html',{'RC':recibo,'group':grupo_actual})
@login_required
def LoteUpdate(request,idc,idl):
    if request.method == 'POST':
        if request.POST.get('Lote') and request.POST.get('Cantidad') and request.POST.get('PrecioC') and request.POST.get('PrecioV') and request.POST.get('FechaVenci'):
            insert=connection.cursor()
            insert.execute("Update temp_lote set Loteid='"+request.POST.get('Lote')+"',Cantidad="+request.POST.get('Cantidad')+",PrecioC="+request.POST.get('PrecioC')+",precioV="+request.POST.get('PrecioV')+",fechaVenci='"+request.POST.get('FechaVenci')+"',fechaModify=now() where Loteid='"+str(idl)+"';")
            insert=connection.cursor()
            insert.execute("Update temp_detalle_Compra set Precio="+request.POST.get('PrecioC')+",PrecioU="+request.POST.get('PrecioV')+",CantidadProductos="+request.POST.get('Cantidad')+" where id_compra="+str(idc)+" and Lote='"+str(idl)+"';")
            return redirect(f'/Compra/Lista/{idc}')
    else:
        lote=connection.cursor()
        lote.execute("select * from temp_lote where Loteid='"+str(idl)+"';")
        info=connection.cursor ()
        info.execute("select * from temp_compra where id_compra="+str(idc)+";")
        info2=info.fetchall()
        grupo_actual= group_iden(request)
        return render(request,"ReciboCompra/LoteActualizar.html",{'lote':lote,'info':info2,'group':grupo_actual})
@login_required
def Recibos_Finalizar(request):
    proveedor=connection.cursor()
    proveedor.execute("INSERT INTO proveedor SELECT * FROM temp_proveedor;")
    proveedor.execute("DELETE FROM temp_proveedor;")

    producto=connection.cursor()
    producto.execute("INSERT INTO producto SELECT * FROM temp_producto;")
    producto.execute("DELETE FROM temp_producto;")

    lote=connection.cursor()
    lote.execute("INSERT INTO lote SELECT *FROM temp_lote;")
    lote.execute("DELETE FROM temp_lote;")

    compra=connection.cursor()
    compra.execute("INSERT INTO compra SELECT * FROM temp_compra;")
    compra.execute("DELETE FROM temp_compra;")

    detalle_compra=connection.cursor()
    detalle_compra.execute("INSERT INTO detalle_compra SELECT * FROM temp_detalle_compra;")
    detalle_compra.execute("DELETE FROM temp_detalle_compra;")
    return redirect('/Compra/Recibos')
@login_required
def Recibos_Cancelar(request):
    proveedor=connection.cursor()
    proveedor.execute("DELETE FROM temp_proveedor;")

    producto=connection.cursor()
    producto.execute("DELETE FROM temp_producto;")

    lote=connection.cursor()
    lote.execute("DELETE FROM temp_lote;")

    compra=connection.cursor()
    compra.execute("DELETE FROM temp_compra;")

    detalle_compra=connection.cursor()
    detalle_compra.execute("DELETE FROM temp_detalle_compra;")
    return redirect('/Compra/Recibos')

#logout
def salir(request):
    logout(request)
    return redirect('login')