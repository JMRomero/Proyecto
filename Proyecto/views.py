from django.shortcuts import render,redirect
from django.db import connection

#producto
def producto(request):
    if request.method=="POST":
        if request.POST.get('codigo') and request.POST.get('nombre')  and request.POST.get('gramo_litro')  and request.POST.get('Max') and request.POST.get('Min'):
            ##Captura la infromacion, conecte a la base de datos y ejecute el insert
            insert=connection.cursor()
            insert.execute("INSERT INTO producto (id_producto,Nombre,GramoLitro,Max,Min)VALUES("+request.POST.get('codigo')+",'"+request.POST.get('nombre')+"','"+request.POST.get('gramo_litro')+"',"+request.POST.get('Max')+","+request.POST.get('Min')+")")
            return redirect('/Producto/lista')
    else:
        return render(request,'Producto/insertar.html')
def viewP(request):
    viewA=connection.cursor()
    viewA.execute("select *, CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End as cantidad from producto where estado=True;")
    viewI=connection.cursor()
    viewI.execute("select *, CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End as cantidad from producto where estado=False;")
    inactivos=viewI.fetchall()
    return render(request,'Producto/lista.html',{'productoA':viewA,'productoI':viewI,'activos':activos,'inactivos':inactivos})
def viewL(request,id):
    viewLA=connection.cursor()
    viewLA.execute("select * from Lote where id_producto="+str(id)+" and Estado=1")
    activos=viewLA.fetchall()   
    viewLI=connection.cursor()
    viewLI.execute("select * from Lote where id_producto="+str(id)+" and Estado=0")
    inactivos=viewLI.fetchall()
    with connection.cursor() as cursor:
        cursor.execute("SELECT Estado FROM producto WHERE id_producto="+str(id)+";")  # Me consulta a la hora de cambiar un lote, si el producto al que esta asignado el lote esta activo, para hacer la validacion en el html y dejar o no activar
        impEA = cursor.fetchone()[0]#guarda el booleano
    with connection.cursor() as cursor:
        cursor.execute("select timestampdiff(day,now(),fechaVenci) from lote where id_producto="+str(id)+" and Estado=False;") 
        dias = [row[0] for row in cursor.fetchall()]
        Lvenci=[valor>0 for valor in dias]
    Listaconbinada=list(zip(viewLI,Lvenci))
    return render(request,'lote/listaL.html',{'LoteA':viewLA,'Diff_L':Listaconbinada,'estado':impEA,'fvenci':Lvenci,'activos':activos,'inactivos':inactivos})



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
        return render(request,'Producto/actualizar.html',{'datos':consulta})
def esatdoI(request,id):
    estadoI=connection.cursor()
    estadoI.execute("UPDATE producto SET Estado=True where id_producto="+str(id)+"")
    return redirect('/Producto/lista')
def esatdoA(request,id):
    estadoA=connection.cursor()
    estadoA.execute("UPDATE producto SET Estado=False where id_producto="+str(id)+"")
    return redirect('/Producto/lista')
def estadoiL(request,id,lote):
    estadoiL=connection.cursor()
    estadoiL.execute(f"UPDATE Lote SET Estado=True WHERE id_producto={str(id)} and Loteid='{str(lote)}'")
    return redirect(f'/Producto/listal/{str(id)}')
def estadoaL(request,id,lote):
    estadoiL=connection.cursor()
    estadoiL.execute(f"UPDATE Lote SET Estado=False WHERE id_producto={str(id)} and Loteid='{str(lote)}'")
    return redirect(f'/Producto/listal/{str(id)}')
def menu(request):
    return render(request,'Menu/menu.html')


#proveedor
def viewProveedor(request):
    viewA=connection.cursor()
    viewA.execute("select * from proveedor where Estado=1;")
    activos=viewA.fetchall()
    viewI=connection.cursor()
    viewI.execute("select * from proveedor where Estado=0;")
    inactivos=viewI.fetchall()
    return render(request,'Proveedor/lista.html',{'proveedorA':viewA,'proveedorI':viewI,'activos':activos,'inactivos':inactivos})

def updateProveedor(request,id):
    if request.method=="POST":
        if request.POST.get('nit') and request.POST.get('nombre') and  request.POST.get('telefono') and request.POST.get('categoria_productos') and request.POST.get('horario_atencion') and request.POST.get('politica_devolucion'):
            insert=connection.cursor()
            insert.execute("UPDATE proveedor SET NIT="+request.POST.get('nit')+",Nombre='"+request.POST.get('nombre')+"',Telefono="+request.POST.get('telefono')+",Categoria_Productos='"+request.POST.get('categoria_productos')+"',Politica_Devolucion='"+request.POST.get('politica_devolucion')+"' where NIT="+str(id)+";")
            return redirect('/Proveedor/lista')
    else:
        consulta=connection.cursor()
        consulta.execute("select * from proveedor where NIT="+str(id)+";")
        return render(request,'Proveedor/actualizar.html',{'datos':consulta})
    
def proveedorInsert(request):
    if request.method=="POST":
        if request.POST.get('nit') and request.POST.get('nombre') and  request.POST.get('telefono') and request.POST.get('categoria_productos') and request.POST.get('horario_atencion') and request.POST.get('politica_devolucion'):
            insert=connection.cursor()
            insert.execute("INSERT INTO proveedor (NIT,Nombre,Telefono,Categoria_Productos,Horario_Atencion,Politica_Devolucion) VALUES("+request.POST.get('nit')+",'"+request.POST.get('nombre')+"',"+request.POST.get('telefono')+",'"+request.POST.get('categoria_productos')+"','"+request.POST.get('horario_atencion')+"','"+request.POST.get('politica_devolucion')+"')")
            return redirect('/Proveedor/lista')
    else:
        return render(request,'Proveedor/insertar.html')
    
def proveedorEstadoI(request,id):
    estadoI=connection.cursor()
    estadoI.execute("UPDATE proveedor SET Estado=0 where NIT="+str(id)+"")
    return redirect('/Proveedor/lista')
def proveedorEstadoA(request,id):
    estadoA=connection.cursor()
    estadoA.execute("UPDATE proveedor SET Estado=1 where NIT="+str(id)+"")
    return redirect('/Proveedor/lista')

#lote
def Stock(request):
    if request.method=="POST":
        if request.POST.get('codigo') and  request.POST.get('precioC') and request.POST.get('precioT')  and request.POST.get('cantidad') and request.POST.get('vencimiento') and request.POST.get('lote'):
            
            insert=connection.cursor()
            insert.execute("UPDATE producto SET PrecioC="+request.POST.get('precioC')+",PrecioT="+request.POST.get('precioT')+",Fecha_Modificacion=now() where id_producto="+request.POST.get('codigo')+";")
            insert2=connection.cursor()
            insert2.execute("Insert into vencimiento (fechaV,id_producto,LoteP,Cantidad) VALUES('"+request.POST.get('vencimiento')+"',"+request.POST.get('codigo')+",'"+request.POST.get('lote')+"',"+request.POST.get('cantidad')+");")
            return redirect('/Producto/lista')
    else:
       return render(request,'Producto/Stock.html')

def viewLote(request,id):
    viewA=connection.cursor()
    viewA.execute("select producto.*, vencimiento.fechaV,vencimiento.LoteP,vencimiento.Cantidad from producto inner join vencimiento on vencimiento.id_producto=producto.id_producto where producto.Estado=0; and producto.id")
    viewI=connection.cursor()
    viewI.execute("select producto.*, vencimiento.fechaV,vencimiento.LoteP,vencimiento.Cantidad from producto inner join vencimiento on vencimiento.id_producto=producto.id_producto where producto.Estado=1;")
    return render(request,'Producto/lista.html',{'productoA':viewA,'productoI':viewI})

#pedidos especiales
def viewPedidos(request):
    viewA=connection.cursor()
    viewA.execute("select * from pedidos_especiales where estadoPe=1;")
    activos=viewA.fetchall()
    viewI=connection.cursor()
    viewI.execute("select * from pedidos_especiales where estadoPe=0;")
    inactivos=viewI.fetchall()
    return render(request,'Pedidos/lista.html',{'pedidosA':viewA,'pedidosI':viewI,'activos':activos,'inactivos':inactivos})

def pedidosInsert(request):
    if request.method=="POST":
        if request.POST.get('cedula') and request.POST.get('nombreClie') and  request.POST.get('celularClie') and request.POST.get('descripcion'):
            insert=connection.cursor()
            insert.execute("INSERT INTO pedidos_especiales (Cedula,nombreClie,celularClie,descripcion,fechaP) VALUES("+request.POST.get('cedula')+",'"+request.POST.get('nombreClie')+"',"+request.POST.get('celularClie')+",'"+request.POST.get('descripcion')+"',now())")
            return redirect('/Pedidos/lista')
    else:
        return render(request,'Pedidos/insertar.html')
    
def pedidosEstadoI(request,id):
    estadoI=connection.cursor()
    estadoI.execute("UPDATE pedidos_especiales SET estadoPe=0 where id_pedido="+str(id)+"")
    return redirect('/Pedidos/lista')
def pedidosEstadoA(request,id):
    estadoA=connection.cursor()
    estadoA.execute("UPDATE pedidos_especiales SET estadoPe=1 where id_pedido="+str(id)+"")
    return redirect('/Pedidos/lista')
#usuarios
def viewUsuario(request):
    viewA=connection.cursor()
    viewA.execute("select * from usuario where estado=1;")
    activos=viewA.fetchall()
    viewI=connection.cursor()
    viewI.execute("select * from usuario where estado=0;")
    inactivos=viewI.fetchall()
    return render(request,'Usuario/lista.html',{'usuarioA':viewA,'usuarioI':viewI,'activos':activos,'inactivos':inactivos})
def usuarioEstadoI(request,id):
    estadoI=connection.cursor()
    estadoI.execute("UPDATE usuario SET Estado=0 where Cedula="+str(id)+"")
    return redirect('/Usuario/lista')
def usuarioEstadoA(request,id):
    estadoA=connection.cursor()
    estadoA.execute("UPDATE usuario SET Estado=1 where Cedula="+str(id)+"")
    return redirect('/Usuario/lista')
def usuarioInsert(request):
    if request.method=="POST":
        if request.POST.get('cedula') and request.POST.get('nombre') and request.POST.get('apellido') and request.POST.get('telefono') and request.POST.get('correo')and request.POST.get('direccion')and request.POST.get('fecha_nacimiento')and request.POST.get('Id_rol'):
            insert=connection.cursor()
            insert.execute("INSERT INTO usuario (Cedula,Nombre,Apellido,Telefono,Correo,Direccion,Fecha_Nacimiento,Fecha_Creacion,id_rol) VALUES("+request.POST.get('cedula')+",'"+request.POST.get('nombre')+"','"+request.POST.get('apellido')+"',"+request.POST.get('telefono')+",'"+request.POST.get('correo')+"','"+request.POST.get('direccion')+"','"+request.POST.get('fecha_nacimiento')+"',now(),"+request.POST.get('Id_rol')+")")
            return redirect('/Usuario/lista')
    else:
        return render(request,'Usuario/insertar.html')
def updateUsuario(request,id):
    if request.method=="POST":
        if request.POST.get('cedula') and request.POST.get('nombre') and request.POST.get('apellido') and  request.POST.get('telefono') and request.POST.get('correo') and request.POST.get('direccion') and request.POST.get('fecha_nacimiento') and request.POST.get('Id_rol'):
            insert=connection.cursor()
            insert.execute("UPDATE usuario SET Cedula="+request.POST.get('cedula')+",Nombre='"+request.POST.get('nombre')+"',Apellido='"+request.POST.get('apellido')+"',Telefono="+request.POST.get('telefono')+",Correo='"+request.POST.get('correo')+"',Direccion='"+request.POST.get('direccion')+"',Fecha_Nacimiento='"+request.POST.get('fecha_nacimiento')+"',id_rol='"+request.POST.get('Id_rol')+"' where Cedula="+str(id)+";")
            return redirect('/Usuario/lista')
    else:
        consulta=connection.cursor()
        consulta.execute("select * from usuario where Cedula="+str(id)+";")
        return render(request,'Usuario/actualizar.html',{'datos':consulta})