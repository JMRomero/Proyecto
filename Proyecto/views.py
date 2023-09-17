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
    viewA.execute("select producto.*, vencimiento.fechaV from producto inner join vencimiento on vencimiento.id_producto=producto.id_producto where producto.Estado=0;")
    viewI=connection.cursor()
    viewI.execute("select producto.*, vencimiento.fechaV from producto inner join vencimiento on vencimiento.id_producto=producto.id_producto where producto.Estado=1;")
    return render(request,'Producto/lista.html',{'productoA':viewA,'productoI':viewI})

def update(request,id):
    if request.method=="POST":
        if request.POST.get('codigo') and request.POST.get('nombre') and  request.POST.get('precioC') and request.POST.get('precioT') and request.POST.get('gramo_litro') and request.POST.get('cantidad') and request.POST.get('vencimiento') and request.POST.get('lote') and request.POST.get('Max') and request.POST.get('Min'):
            ##Captura la infromacion, conecte a la base de datos y ejecute el insert
            insert=connection.cursor()
            insert.execute("UPDATE producto SET id_producto="+request.POST.get('codigo')+",Nombre='"+request.POST.get('nombre')+"',PrecioC="+request.POST.get('precioC')+",PrecioT="+request.POST.get('precioT')+",GramoLitro='"+request.POST.get('gramo_litro')+"',Cantidad="+request.POST.get('cantidad')+",Fecha_Modificacion=now(),Lote='"+request.POST.get('lote')+"',Max="+request.POST.get('Max')+",Min="+request.POST.get('Min')+" where id_producto="+str(id)+";")
            insert2=connection.cursor()
            insert2.execute("UPDATE vencimiento SET  fechaV='"+request.POST.get('vencimiento')+"',id_producto="+request.POST.get('codigo')+",LoteP='"+request.POST.get('lote')+"' where id_producto="+str(id)+";")
            return redirect('/Producto/lista')
    else:
        consulta=connection.cursor()
        consulta.execute("select producto.*, vencimiento.fechaV from producto inner join vencimiento on vencimiento.id_producto=producto.id_producto where producto.id_producto="+str(id)+";")
        return render(request,'Producto/actualizar.html',{'datos':consulta})
def esatdoI(request,id):
    estadoI=connection.cursor()
    estadoI.execute("UPDATE producto SET Estado=1 where id_producto="+str(id)+"")
    return redirect('/Producto/lista')
def esatdoA(request,id):
    estadoA=connection.cursor()
    estadoA.execute("UPDATE producto SET Estado=0 where id_producto="+str(id)+"")
    return redirect('/Producto/lista')
