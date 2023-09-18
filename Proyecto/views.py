from django.shortcuts import render,redirect
from django.db import connection


def producto(request):
    if request.method=="POST":
        if request.POST.get('codigo') and request.POST.get('nombre') and request.POST.get('estado') and  request.POST.get('precioC') and request.POST.get('precioT') and request.POST.get('gramo_litro') and request.POST.get('cantidad') and request.POST.get('vencimiento') and request.POST.get('lote') and request.POST.get('Max') and request.POST.get('Min'):
            ##Captura la infromacion, conecte a la base de datos y ejecute el insert
            insert=connection.cursor()
            insert.execute("INSERT INTO producto VALUES("+request.POST.get('codigo')+",'"+request.POST.get('nombre')+"','"+request.POST.get('estado')+"',"+request.POST.get('precioC')+","+request.POST.get('precioT')+",'"+request.POST.get('gramo_litro')+"',"+request.POST.get('cantidad')+",now(),'"+request.POST.get('lote')+"',"+request.POST.get('Max')+","+request.POST.get('Min')+")")
            insert2=connection.cursor()
            insert2.execute("INSERT INTO vencimiento (fechaV,id_producto,LoteP) VALUES('"+request.POST.get('vencimiento')+"',"+request.POST.get('codigo')+",'"+request.POST.get('lote')+"')")
            return redirect('/Producto/lista')
    else:
        return render(request,'Producto/insertar.html')
def viewP(request):
    viewA=connection.cursor()
    viewA.execute("select producto.*, vencimiento.fechaV,vencimiento.LoteP,vencimiento.Cantidad from producto inner join vencimiento on vencimiento.id_producto=producto.id_producto where producto.Estado=0;")
    viewI=connection.cursor()
    viewI.execute("select producto.*, vencimiento.fechaV,vencimiento.LoteP,vencimiento.Cantidad from producto inner join vencimiento on vencimiento.id_producto=producto.id_producto where producto.Estado=1;")
    return render(request,'Producto/lista.html',{'productoA':viewA,'productoI':viewI})

def update(request,id,lote):
    if request.method=="POST":
        if request.POST.get('codigo') and request.POST.get('nombre') and  request.POST.get('precioC') and request.POST.get('precioT') and request.POST.get('gramo_litro') and request.POST.get('cantidad') and request.POST.get('vencimiento') and request.POST.get('lote') and request.POST.get('Max') and request.POST.get('Min'):
            ##Captura la infromacion, conecte a la base de datos y ejecute el insert
            insert=connection.cursor()
            insert.execute("UPDATE producto SET id_producto="+request.POST.get('codigo')+",Nombre='"+request.POST.get('nombre')+"',PrecioC="+request.POST.get('precioC')+",PrecioT="+request.POST.get('precioT')+",GramoLitro='"+request.POST.get('gramo_litro')+"',Cantidad="+request.POST.get('cantidad')+",Fecha_Modificacion=now(),Lote='"+request.POST.get('lote')+"',Max="+request.POST.get('Max')+",Min="+request.POST.get('Min')+" where id_producto="+str(id)+" and Lote='"+str(lote)+"';")
            insert2=connection.cursor()
            insert2.execute("UPDATE vencimiento SET  fechaV='"+request.POST.get('vencimiento')+"',id_producto="+request.POST.get('codigo')+",LoteP='"+request.POST.get('lote')+"',Cantidad="+request.POST.get('cantidad')+" where id_producto="+str(id)+" and LoteP='"+str(lote)+"';")
            return redirect('/Producto/lista')
    else:
        consulta=connection.cursor()
        consulta.execute("select producto.*, vencimiento.fechaV,vencimiento.LoteP from producto inner join vencimiento on vencimiento.id_producto=producto.id_producto where producto.id_producto="+str(id)+" and vencimiento.LoteP='"+str(lote)+"';")
        return render(request,'Producto/actualizar.html',{'datos':consulta})
def esatdoI(request,id):
    estadoI=connection.cursor()
    estadoI.execute("UPDATE producto SET Estado=1 where id_producto="+str(id)+"")
    return redirect('/Producto/lista')
def esatdoA(request,id):
    estadoA=connection.cursor()
    estadoA.execute("UPDATE producto SET Estado=0 where id_producto="+str(id)+"")
    return redirect('/Producto/lista')

def menu(request):
    return render(request,'Menu/menu.html')
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

def menu(request):
    return render(request,'Menu/menu.html')

def viewProveedor(request):
    viewA=connection.cursor()
    viewA.execute("select * from proveedor where Estado=1;")
    viewI=connection.cursor()
    viewI.execute("select * from proveedor where Estado=0;")
    return render(request,'Proveedor/lista.html',{'proveedorA':viewA,'proveedorI':viewI})

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
