from itertools import product
from django.shortcuts import render,redirect
from django.db import connection
from django.contrib.auth.decorators import login_required
from django.contrib.auth import logout,authenticate, login
from django.contrib.auth.models import User,Group #para realizar el inicio mediante django se debe migrar mediante py manage.py migrate donde trae las tablas que necesita django para el login
from django.contrib.auth.hashers import make_password #funcion para encriptar contraseña
from django.contrib import messages
from plyer import notification
from django.core.serializers import serialize
from django.http import HttpResponse,JsonResponse

def group_iden(request):
    grupos_usuario = request.user.groups.all()
    for grupo in grupos_usuario:
        grupoA=grupo.name
        return grupoA
def nombredelusuario(request):
    nombreusuario=request.user.username
    return nombreusuario
def nombredelusuario2(request):
    nombreusuario=request.user.first_name
    apellidousuario=request.user.last_name
    nombreC=nombreusuario+" "+apellidousuario
    return nombreC
def fecha(request):
    fecha=connection.cursor()
    fecha.execute("select now();")
    fechaHoy=fecha.fetchone()[0]
    return fechaHoy
#region inicio
#login
def inicio(request):
    sesioniniciada=0
    desactivarVencidos=connection.cursor()
    if request.method == 'POST':
        username = request.POST['username']
        password = request.POST['password']
        user = authenticate(request, username=username, password=password)
        if user is not None:
            primerinicio=connection.cursor()
            primerinicio.execute("select last_login from auth_user where username='"+username+"';") #buscar su ultimo login
            primerinicioo=primerinicio.fetchone()[0]
            if primerinicioo==None: #si no a iniciado session, debera cambiar contraseña
                return redirect(f'/cambiarcontraseña/{username}')  # Redirige a cambiar contraseña
            else:
                hora=connection.cursor()
                hora.execute(f"update auth_user set hora_login=now() where username={username};")
                desactivarVencidos.execute("call Desactivar_Vencidos()")
                login(request, user)#token que verifica el inicio
            # Usuario autenticado con éxito
            return redirect('/')  # Redirige a la página de inicio
        else:
            activo=connection.cursor()
            activo.execute("select is_active from auth_user where username='"+username+"';")
            try :
                activoo=activo.fetchone()[0]
                if activoo==0:
                    messages.error(request, 'Su usuario esta Inactivo')
                else:
                    messages.error(request, 'Usuario o contraseña incorrectos')
            except:
            # Autenticación fallida, agregamos un mensaje de error a la URL
                messages.error(request, 'Usuario o contraseña incorrectos')
            return redirect('login')
    else:
        nombre=nombredelusuario(request)
        if nombre:
            sesioniniciada=True
            print(nombre,"session")

        return render(request, 'registration/login.html',{'session':sesioniniciada})
#cambiarcontraseña
def cambiarpassword(request,username):
    desactivarVencidos=connection.cursor()
    if request.method=='POST':
        if request.POST.get('new_password1') and request.POST.get('new_password2'):
            password1=request.POST.get('new_password1')
            password2=request.POST.get('new_password2')
            count=0
            if password1 != password2:
                nConiciden=True
                count=+1
            else:
                nConiciden=False
            numeros=[caracter.isdigit() for caracter in password1]
            if all(numeros):
                todonumeros=True
                count=+1
            else:
                todonumeros=False
            if len(password1)<8:
                corta=True
                count=+1
            else:
                corta=False
            with connection.cursor()as cursor:
                cursor.execute("select COUNT(id) from auth_user where first_name LIKE'%"+password1+"%' and username='"+username+"';")
                nombre=cursor.fetchone()[0]
                cursor.execute("select COUNT(id) from auth_user where last_name LIKE'%"+password1+"%' and username='"+username+"';")
                apellido=cursor.fetchone()[0]
                cursor.execute("select COUNT(id) from auth_user where email LIKE'%"+password1+"%' and username='"+username+"';")
                email=cursor.fetchone()[0]
                cursor.execute("select COUNT(id) from auth_user where username ='"+password1+"' and username='"+username+"';")
                cedula=cursor.fetchone()[0]
            if nombre>0:
                nombrep=True
                count=+1
            else:
                nombrep=False
            if apellido>0:
                apellidop=True
                count=+1
            else:
                apellidop=False
            if email>0:
                emailp=True
                count=+1
            else:
                emailp=False
            if cedula>0:
                cedulap=True
                count=+1
            else:
                cedulap=False
            if nConiciden or todonumeros or corta or nombrep or apellidop or emailp or cedulap:
                return render(request, "registration/changePassword.html",{'coinciden':nConiciden,'corta':corta,'numero':todonumeros,'nombre':nombrep,'apellido':apellidop,'email':emailp,'cedula':cedulap,'count':count}) 
            else:
                hashed_password=make_password(password1)
                insert=connection.cursor()
                insert.execute("Update auth_user SET password='"+str(hashed_password)+"' where username='"+username+"'")
                user = authenticate(request, username=username, password=password1)
                hora=connection.cursor()
                hora.execute(f"update auth_user set hora_login=now() where username={username};")
                desactivarVencidos.execute("call Desactivar_Vencidos()")
                login(request, user)
                return redirect('/')
    else:
        return render(request, "registration/changePassword.html")
#endregion 
#region Menu
@login_required
def menu(request):
    with connection.cursor() as cursor:
        cursor.execute("SELECT COUNT(id_producto) FROM producto where Estado=True")
        productosA = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(id_producto) FROM producto where Estado=False")
        productosI = cursor.fetchone()[0]
        cursor.execute("select COUNT(NIT) from proveedor where Estado=True")
        proveedorA=cursor.fetchone()[0]
        cursor.execute("select COUNT(NIT) from proveedor where Estado=False")
        proveedorI=cursor.fetchone()[0]
        cursor.execute("select COUNT(id_pedido) from pedidos_especiales where estadoPe=1")
        realizar=cursor.fetchone()[0]
        cursor.execute("select COUNT(id_pedido) from pedidos_especiales where estadoPe=0")
        realizado=cursor.fetchone()[0]
        cursor.execute("select COUNT(id_pedido) from pedidos_especiales where estadoPe=2")
        concluido=cursor.fetchone()[0]
        cursor.execute("select COUNT(id) from auth_user where is_active=True")
        usuariosA=cursor.fetchone()[0]
        cursor.execute("select COUNT(id) from auth_user where is_active=False")
        usuariosI=cursor.fetchone()[0]
        cursor.execute("select COUNT(id_venta) from venta where Fecha=CURRENT_DATE() and TotalCompra>0;")
        ventas=cursor.fetchone()[0]
        cursor.execute(f"Select SUM(TotalCompra) from venta where Fecha=CURRENT_DATE();")
        TotalDia=cursor.fetchone()[0]
    grupo_actual= group_iden(request)
    return render(request,'Menu/menu.html',{'group':grupo_actual,'productosA':productosA,'productosI':productosI,'proveedorA':proveedorA,'proveedorI':proveedorI,'realizar':realizar,'realizado':realizado,'usuariosA':usuariosA,'usuariosI':usuariosI,'concluido':concluido,'Ventas':ventas,'Total':TotalDia})
#endregion
#region producto
#producto
def producto_API(request,codigo):
    datosP=connection.cursor()
    datosP.execute("call Datos_producto("+str(codigo)+")")
    columnas = [col[0] for col in datosP.description]#mediante esto consulto los nombre de los atributos que vienen
    resultado=datosP.fetchall()#recorro para tener todos los datos
    datos_producto = [dict(zip(columnas, fila)) for fila in resultado]#creo un diccionario con los nomnres de los atributos y sus respectivos valores
    return JsonResponse(datos_producto,safe=False)
@login_required
def producto(request):
    if request.method=="POST":
        if request.POST.get('codigo') and request.POST.get('nombre')  and request.POST.get('gramo_litro')  and request.POST.get('Max') and request.POST.get('Min'):
            consulta=connection.cursor()
            consulta.execute("select COUNT(nombre) from producto where id_producto="+request.POST.get('codigo')+";")
            existente=consulta.fetchone()[0]
            rotacion=request.POST.get('rotacion')
            if existente>0:
                codigo=request.POST.get('codigo')
                nombre=request.POST.get('nombre')
                gramo_litro=request.POST.get('gramo_litro')
                Max=request.POST.get('Max')
                Min=request.POST.get('Min')
                repetido=1
                nombrep=connection.cursor()
                nombrep.execute("select nombre from producto where id_producto="+codigo+";")
                nombrep2=nombrep.fetchone()[0]
                grupo_actual= group_iden(request)
                return render(request,'Producto/insertar.html',{'group':grupo_actual,'codigo':codigo,'nombre':nombre,'nombrep':nombrep2,'gramo_litro':gramo_litro,'Max':Max,'Min':Min,'rotacion':rotacion,'repetido':repetido})
            else:
            ##Captura la infromacion, conecte a la base de datos y ejecute el insert
                insert=connection.cursor()
                if rotacion=='on':
                    insert.execute("INSERT INTO producto (id_producto,Nombre,GramoLitro,Max,Min,rotacion)VALUES("+request.POST.get('codigo')+",'"+request.POST.get('nombre')+"','"+request.POST.get('gramo_litro')+"',"+request.POST.get('Max')+","+request.POST.get('Min')+",'Baja');")
                else:
                    insert.execute("INSERT INTO producto (id_producto,Nombre,GramoLitro,Max,Min)VALUES("+request.POST.get('codigo')+",'"+request.POST.get('nombre')+"','"+request.POST.get('gramo_litro')+"',"+request.POST.get('Max')+","+request.POST.get('Min')+");")
                return redirect('/Producto/lista')
    else:
        grupo_actual= group_iden(request)
        repetido=0
        return render(request,'Producto/insertar.html',{'group':grupo_actual,'repetido':repetido})

@login_required
def viewP(request):
    if request.method == 'POST':
        viewA=connection.cursor()
        viewI=connection.cursor()
        v=request.POST.get("qp")
        vv=[caracter.isdigit() for caracter in v]
        if all(vv):
            viewA.execute("select *, CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End as cantidad from producto where estado=True and id_producto LIKE '%"+str(v)+"%';")
        else:
            viewA.execute("select *, CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End as cantidad from producto where estado=True and Nombre LIKE '%"+str(v)+"%';")
        vv=[caracter.isdigit() for caracter in v]
        if all(vv):
            viewI.execute("select *, CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End as cantidad from producto where estado=False and id_producto LIKE '%"+str(v)+"%';")
        else:
            viewI.execute("select *, CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End as cantidad from producto where estado=False and Nombre LIKE '%"+str(v)+"%';")
        activos=viewA.fetchall()
        busqueda=True
        inactivos=viewI.fetchall()
    else:
        viewA=connection.cursor()
        viewA.execute("select *, CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End as cantidad from producto where estado=True;")
        activos=viewA.fetchall()
        viewI=connection.cursor()
        viewI.execute("select *, CASE when (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and lote.Estado=True )>0 THEN (select SUM(cantidad)  from Lote where producto.id_producto=Lote.id_producto and Lote.Estado=True ) else 0 End as cantidad from producto where estado=False;")
        inactivos=viewI.fetchall()
        busqueda=False
        v=0
    nombre=nombredelusuario2(request)
    print(nombre)
    fechahoy=fecha(request)
    grupo_actual= group_iden(request)
    return render(request,'Producto/lista.html',{'busqueda':busqueda,'productoA':viewA,'productoI':viewI,'activos':activos,'inactivos':inactivos,'group':grupo_actual,'qp':v,'fecha':fechahoy,'Nombre':nombre})
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
    producto=connection.cursor()
    producto.execute(f"select Nombre from producto where id_producto={str(id)}")
    productoN=producto.fetchone()[0]
    grupo_actual= group_iden(request)
    nombre=nombredelusuario2(request)
    fechaH=fecha(request)
    return render(request,'lote/listaL.html',{'LoteA':viewLA,'Diff_L':ListacombinadaI,'Diff_LA':viewLA,'estado':impEA,'fvenci':Lvenci,'activos':activos,'inactivos':inactivos,'group':grupo_actual,'fecha':fechaH,'Nombre':nombre,'Nproducto':productoN})
@login_required
def update(request,id):
    if request.method=="POST":
        if request.POST.get('codigo') and request.POST.get('nombre')  and request.POST.get('gramo_litro')  and request.POST.get('Max') and request.POST.get('Min'):
            codigoO=int(request.POST.get('codigo'))
            rotacion=request.POST.get('rotacion')
            if codigoO==id:
                insert=connection.cursor()
                if rotacion=='on':
                    insert.execute("UPDATE producto SET id_producto="+request.POST.get('codigo')+",Nombre='"+request.POST.get('nombre')+"',GramoLitro='"+request.POST.get('gramo_litro')+"',Fecha_Modificacion=now(),Max="+request.POST.get('Max')+",Min="+request.POST.get('Min')+",rotacion='Baja' where id_producto="+str(id)+";")
                else:
                    insert.execute("UPDATE producto SET id_producto="+request.POST.get('codigo')+",Nombre='"+request.POST.get('nombre')+"',GramoLitro='"+request.POST.get('gramo_litro')+"',Fecha_Modificacion=now(),Max="+request.POST.get('Max')+",Min="+request.POST.get('Min')+",rotacion='Normal' where id_producto="+str(id)+";")
                return redirect('/Producto/lista')
            else:
                consulta=connection.cursor()
                consulta.execute("select COUNT(id_producto) from producto where id_producto="+request.POST.get('codigo')+";")
                existente=consulta.fetchone()[0]
                if existente>0:
                    codigo=str(id)
                    codigoE=request.POST.get('codigo')
                    nombre=request.POST.get('nombre')
                    gramo_litro=request.POST.get('gramo_litro')
                    Max=request.POST.get('Max')
                    Min=request.POST.get('Min')
                    repetido=1
                    nombrep=connection.cursor()
                    nombrep.execute("select nombre from producto where id_producto="+codigoE+";")
                    nombrep2=nombrep.fetchone()[0]
                    grupo_actual= group_iden(request)
                    return render(request,'Producto/actualizar.html',{'group':grupo_actual,'codigo':codigo,'codigoE':codigoE,'nombre':nombre,'nombrep':nombrep2,'gramo_litro':gramo_litro,'Max':Max,'Min':Min,'rotacion':rotacion,'repetido':repetido})
                else:
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
#endregion
#region Proveedor
#proveedor
@login_required
def viewProveedor(request):
    if request.method=='POST':
        viewA=connection.cursor()    
        viewI=connection.cursor()
        proveedor=request.POST.get('NP')
        busqueda=True
        #saber si son letras o numeros
        vv=[caracter.isdigit() for caracter in proveedor]
        if all(vv):
            viewA.execute("select * from proveedor where Estado=1 and NIT LIKE '%"+str(proveedor)+"%';")
            viewI.execute("select * from proveedor where Estado=0 and NIT LIKE '%"+str(proveedor)+"%';")
        else:
            viewA.execute("select * from proveedor where Estado=1 and Nombre LIKE '%"+str(proveedor)+"%';")
            viewI.execute("select * from proveedor where Estado=0 and Nombre LIKE '%"+str(proveedor)+"%';")
    else:
        viewA=connection.cursor()
        viewA.execute("select * from proveedor where Estado=1;")
        viewI=connection.cursor()
        viewI.execute("select * from proveedor where Estado=0;")
        busqueda=False
        proveedor=0
    activos=viewA.fetchall()
    inactivos=viewI.fetchall()
    grupo_actual= group_iden(request)
    return render(request,'Proveedor/lista.html',{'proveedorA':viewA,'proveedorI':viewI,'activos':activos,'inactivos':inactivos,'group':grupo_actual,'busqueda':busqueda,'NP':proveedor})
@login_required
def updateProveedor(request,id):
    if request.method=="POST":
        if request.POST.get('nit') and request.POST.get('nombre') and  request.POST.get('telefono') and request.POST.get('horario_atencion') and request.POST.get('politica_devolucion'):
            nit=int(request.POST.get('nit'))
            if nit==id:
                insert=connection.cursor()
                insert.execute("UPDATE proveedor SET NIT="+request.POST.get('nit')+",Nombre='"+request.POST.get('nombre')+"',Telefono="+request.POST.get('telefono')+",Horario_Atencion='"+request.POST.get('horario_atencion')+"',Politica_Devolucion='"+request.POST.get('politica_devolucion')+"' where NIT="+str(id)+";")
                return redirect('/Proveedor/lista')
            else:
                consulta=connection.cursor()
                consulta.execute("select COUNT(NIT) from proveedor   where NIT="+request.POST.get('nit')+";")
                existencia=consulta.fetchone()[0]
                if existencia>0:
                    nit=str(id)
                    nitE=request.POST.get('nit')
                    nombre=request.POST.get('nombre')
                    telefono=request.POST.get('telefono')
                    horario=request.POST.get('horario_atencion')
                    politica=request.POST.get('politica_devolucion')
                    repetido=1
                    nombrep=connection.cursor()
                    nombrep.execute("select Nombre from Proveedor where NIT="+nitE+";")
                    nombrepr=nombrep.fetchone()[0]
                    grupo_actual= group_iden(request)
                    return render(request,'Proveedor/actualizar.html',{'group':grupo_actual,'repetido':repetido,'nit':nit,'nitE':nitE,'nombre':nombre,'telefono':telefono,'horario':horario,'politica':politica,'nombrepr':nombrepr})       
                else:
                    insert=connection.cursor()
                    insert.execute("UPDATE proveedor SET NIT="+request.POST.get('nit')+",Nombre='"+request.POST.get('nombre')+"',Telefono="+request.POST.get('telefono')+",Horario_Atencion='"+request.POST.get('horario_atencion')+"',Politica_Devolucion='"+request.POST.get('politica_devolucion')+"' where NIT="+str(id)+";")
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
            consulta=connection.cursor()
            consulta.execute("select COUNT(NIT) from proveedor   where NIT="+request.POST.get('nit')+";")
            existencia=consulta.fetchone()[0]
            if existencia>0:
                nit=request.POST.get('nit')
                nombre=request.POST.get('nombre')
                telefono=request.POST.get('telefono')
                horario=request.POST.get('horario_atencion')
                politica=request.POST.get('politica_devolucion')
                repetido=1
                nombrep=connection.cursor()
                nombrep.execute("select Nombre from Proveedor where NIT="+request.POST.get('nit')+";")
                nombrepr=nombrep.fetchone()[0]
                grupo_actual= group_iden(request)
                return render(request,'Proveedor/insertar.html',{'group':grupo_actual,'repetido':repetido,'nit':nit,'nombre':nombre,'telefono':telefono,'horario':horario,'politica':politica,'nombrepr':nombrepr})       
            else:
                insert=connection.cursor()
                insert.execute("INSERT INTO proveedor (NIT,Nombre,Telefono,Horario_Atencion,Politica_Devolucion) VALUES("+request.POST.get('nit')+",'"+request.POST.get('nombre')+"',"+request.POST.get('telefono')+",'"+request.POST.get('horario_atencion')+"','"+request.POST.get('politica_devolucion')+"')")
                return redirect('/Proveedor/lista')
    else:
        repetido=0
        grupo_actual= group_iden(request)
        return render(request,'Proveedor/insertar.html',{'group':grupo_actual,'repetido':repetido})
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
#endregion
#region Lote
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
            loteOO=request.POST.get('codigo')
            if loteOO==lote:
                insert=connection.cursor()
                insert.execute("UPDATE lote SET Loteid='"+request.POST.get('codigo')+"',Cantidad='"+request.POST.get('cantidad')+"',PrecioC="+request.POST.get('precioC')+",PrecioV='"+request.POST.get('precioV')+"',fechaVenci='"+request.POST.get('fechaVenci')+"' where Loteid='"+str(lote)+"'")
                return redirect('/Producto/listal/'+str(id)+'')
            else:
                consulta=connection.cursor()
                consulta.execute("select COUNT(Loteid) from lote where Loteid='"+request.POST.get('codigo')+"';")
                existente=consulta.fetchone()[0]
                if existente>0:
                    consulta=connection.cursor()
                    consulta.execute("select * from lote where Loteid='"+str(lote)+"';")
                    repetido=True
                    codigoO=lote
                    codigor=request.POST.get('codigo')
                    cantidad=request.POST.get('cantidad')
                    precioC=request.POST.get('precioC')
                    precioV=request.POST.get('precioV')
                    fechaVenci=request.POST.get('fechaVenci')
                    grupo_actual= group_iden(request)
                    return render(request,'lote/actualizar.html',{'datos':consulta,'repetido':repetido,'codigoO':codigoO,'codigor':codigor,'cantidad':cantidad,'precioC':precioC,'precioV':precioV,'fechaVenci':fechaVenci,'group':grupo_actual})
                else:
                    insert=connection.cursor()
                    insert.execute("UPDATE lote SET Loteid='"+request.POST.get('codigo')+"',Cantidad='"+request.POST.get('cantidad')+"',PrecioC="+request.POST.get('precioC')+",PrecioV='"+request.POST.get('precioV')+"',fechaVenci='"+request.POST.get('fechaVenci')+"' where Loteid='"+str(lote)+"'")
                    return redirect('/Producto/listal/'+str(id)+'')
    else:
        repetido=False
        consulta=connection.cursor()
        consulta.execute("select * from lote where Loteid='"+str(lote)+"';")
        grupo_actual= group_iden(request)
        return render(request,'lote/actualizar.html',{'datos':consulta,'group':grupo_actual,'repetido':repetido})
#endregion   
#region pedidos especiales
#pedidos especiales
@login_required
def viewPedidos(request):
    if request.method=='POST':
        busqueda=True
        medicamento=request.POST.get('NM')
        viewA=connection.cursor()
        viewA.execute("SELECT *,(SELECT first_name FROM auth_user WHERE pedidos_especiales.Cedula=auth_user.username) FROM pedidos_especiales where estadoPe=1 and descripcion LIKE '%"+str(medicamento)+"%';")
        activos=viewA.fetchall()
        viewI=connection.cursor()
        viewI.execute("SELECT *,(SELECT first_name FROM auth_user WHERE pedidos_especiales.Cedula=auth_user.username) FROM pedidos_especiales where estadoPe=0 and descripcion LIKE '%"+str(medicamento)+"%';")
        inactivos=viewI.fetchall()    
    else:
        viewA=connection.cursor()
        viewA.execute("SELECT *,(SELECT first_name FROM auth_user WHERE pedidos_especiales.Cedula=auth_user.username) FROM pedidos_especiales where estadoPe=1;")
        activos=viewA.fetchall()
        viewI=connection.cursor()
        viewI.execute("SELECT *,(SELECT first_name FROM auth_user WHERE pedidos_especiales.Cedula=auth_user.username) FROM pedidos_especiales where estadoPe=0;")
        inactivos=viewI.fetchall()
        busqueda=False
        medicamento=0
    grupo_actual= group_iden(request)
    return render(request,'Pedidos/lista.html',{'pedidosA':viewA,'pedidosI':viewI,'activos':activos,'inactivos':inactivos,'group':grupo_actual,'busqueda':busqueda,'NM':medicamento})
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
    estadoI.execute("UPDATE pedidos_especiales SET estadoPe=0,fechaM=now() where id_pedido="+str(id)+"")
    return redirect('/Pedidos/lista')
@login_required
def pedidosEstadoA(request,id):
    estadoA=connection.cursor()
    estadoA.execute("UPDATE pedidos_especiales SET estadoPe=1, fechaM=now() where id_pedido="+str(id)+"")
    return redirect('/Pedidos/lista')
@login_required
def pedidosEstadoC(request,id):
    estadoA=connection.cursor()
    estadoA.execute("UPDATE pedidos_especiales SET estadoPe=2,fechaM=now() where id_pedido="+str(id)+"")
    return redirect('/Pedidos/lista')
@login_required
def pedidosEstadoR(request,id):
    estadoA=connection.cursor()
    estadoA.execute("UPDATE pedidos_especiales SET estadoPe=0,fechaM=now() where id_pedido="+str(id)+"")
    return redirect('/Pedidos/listaC')
@login_required
def viewPedidosC(request):
    viewC=connection.cursor()
    if request.method=='POST':
        busqueda=True
        medicamento=request.POST.get('NM')
        viewC.execute("SELECT *,(SELECT first_name FROM auth_user WHERE pedidos_especiales.Cedula=auth_user.username),timestampdiff(day,fechaM,now()) FROM pedidos_especiales where estadoPe=2 and descripcion LIKE '%"+medicamento+"%';")
        Concluidos=viewC.fetchall()
    else:
        viewC.execute("SELECT *,(SELECT first_name FROM auth_user WHERE pedidos_especiales.Cedula=auth_user.username),timestampdiff(day,fechaM,now()) FROM pedidos_especiales where estadoPe=2;")
        Concluidos=viewC.fetchall()
        busqueda=False
        medicamento=0
    grupo_actual= group_iden(request)
    return render(request,'Pedidos/listaC.html',{'pedidosC':viewC,'concluidos':Concluidos,'group':grupo_actual,'busqueda':busqueda,'NM':medicamento})
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
#endregion    
#region usuarios
#usuarios
@login_required
def viewUsuario(request):
    if request.method=='POST':
        viewA=connection.cursor()
        viewI=connection.cursor()
        nombre_cedulausuario=request.POST.get('NCU')
        busqueda=True
        validar=[caracter.isdigit() for caracter in nombre_cedulausuario]
        if all(validar):
            viewA.execute("SELECT auth_user.*, auth_group.name FROM auth_user INNER JOIN auth_user_groups ON auth_user.id=auth_user_groups.user_id INNER JOIN auth_group on auth_group.id=auth_user_groups.group_id WHERE auth_user.is_active=True and auth_user.username LIKE'%"+str(nombre_cedulausuario)+"%';")
            viewI.execute("SELECT auth_user.*, auth_group.name FROM auth_user INNER JOIN auth_user_groups ON auth_user.id=auth_user_groups.user_id INNER JOIN auth_group on auth_group.id=auth_user_groups.group_id WHERE auth_user.is_active=False and auth_user.username LIKE'%"+str(nombre_cedulausuario)+"%';")        
        else:
            viewA.execute("SELECT auth_user.*, auth_group.name FROM auth_user INNER JOIN auth_user_groups ON auth_user.id=auth_user_groups.user_id INNER JOIN auth_group on auth_group.id=auth_user_groups.group_id WHERE auth_user.is_active=True and (auth_user.first_name LIKE'%"+str(nombre_cedulausuario)+"%' or auth_user.last_name LIKE'%"+str(nombre_cedulausuario)+"%');")
            viewI.execute("SELECT auth_user.*, auth_group.name FROM auth_user INNER JOIN auth_user_groups ON auth_user.id=auth_user_groups.user_id INNER JOIN auth_group on auth_group.id=auth_user_groups.group_id WHERE auth_user.is_active=False and (auth_user.first_name LIKE'%"+str(nombre_cedulausuario)+"%' or auth_user.last_name LIKE'%"+str(nombre_cedulausuario)+"%');")
    else:
        viewA=connection.cursor()
        viewA.execute("SELECT auth_user.*, auth_group.name FROM auth_user INNER JOIN auth_user_groups ON auth_user.id=auth_user_groups.user_id INNER JOIN auth_group on auth_group.id=auth_user_groups.group_id WHERE auth_user.is_active=True;")
        viewI=connection.cursor()
        viewI.execute("SELECT auth_user.*, auth_group.name FROM auth_user INNER JOIN auth_user_groups ON auth_user.id=auth_user_groups.user_id INNER JOIN auth_group on auth_group.id=auth_user_groups.group_id WHERE auth_user.is_active=False;")
        busqueda=False
        nombre_cedulausuario=0
    grupo_actual= group_iden(request)
    usuario=nombredelusuario(request)
    activos=viewA.fetchall()
    inactivos=viewI.fetchall()
    return render(request,'Usuario/lista.html',{'usuarioA':viewA,'usuarioI':viewI,'activos':activos,'inactivos':inactivos,'group':grupo_actual,'usuario':usuario,'busqueda':busqueda,'NCU':nombre_cedulausuario})
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
            consultac=connection.cursor()#consultar si la cedula se repite
            consultac.execute("select COUNT(id) from auth_user where username='"+request.POST.get('cedula')+"'")
            consultan=connection.cursor()#consultar si el telefono se repite
            consultan.execute("select COUNT(id) from auth_user where Telefono='"+request.POST.get('telefono')+"'")
            consultae=connection.cursor()#consultar si el email se repite
            consultae.execute("select COUNT(id) from auth_user where email='"+request.POST.get('correo')+"'")
            existentec=consultac.fetchone()[0]
            existenten=consultan.fetchone()[0]
            existentee=consultae.fetchone()[0]
            if existentec>0 or existenten>0 or existentee>0: #si se repite alguna almacenamos los datos y verificamos cual de ellos se repite y mandar el respectivo mensaje 
                cedula=request.POST.get('cedula')
                nombre=request.POST.get('nombre')
                apellido=request.POST.get('apellido')
                telefono=request.POST.get('telefono')
                correo=request.POST.get('correo')
                direccion=request.POST.get('direccion')
                fecha=request.POST.get('fecha_nacimiento')
                rol=request.POST.get('Id_rol')
                contraseña=request.POST.get('contraseña')
                if existentec>0:
                    nombreuc=connection.cursor()#nombre usuario con la cedula registrada 'nombreuc:nombre usuario cedula'
                    nombreuc.execute("select first_name from auth_user where username='"+cedula+"';")
                    apellidouc=connection.cursor()
                    apellidouc.execute("select last_name from auth_user where username='"+cedula+"';")
                    nombreuac=nombreuc.fetchone()[0]#nombre del usuario actual con la cedula
                    apellidouac=apellidouc.fetchone()[0]#el apellido
                    cc=True
                else:
                    cc=False
                    nombreuac="ninguno"
                    apellidouac="ninguno"
                if existenten>0:
                    nombreut=connection.cursor()#nombre del usuario que ta tiene asignado el nuemero de telefono 'nombreut:nombre usuario telefono'
                    nombreut.execute("select first_name from auth_user where Telefono='"+telefono+"';")
                    apellidout=connection.cursor()#el apellido
                    apellidout.execute("select last_name from auth_user where Telefono='"+telefono+"';")
                    nombreuat=nombreut.fetchone()[0]#nombre del usuario actual con el numero de telefono
                    apellidouat=apellidout.fetchone()[0]#el apellido
                    tt=True
                else:
                    tt=False
                    nombreuat="ninguno"
                    apellidouat="ninguno"
                if existentee>0:
                    nombreuce=connection.cursor()#nombre del usuario que ya tiene registrado el correo 'nombreuce: nombre usuario correo electronico'
                    nombreuce.execute("select first_name from auth_user where email='"+correo+"';")
                    apellidouce=connection.cursor()#el apellido
                    apellidouce.execute("select last_name from auth_user where email='"+correo+"';")
                    nombreuace=nombreuce.fetchone()[0]#nombre del usuario actual con el correo
                    apellidouace=apellidouce.fetchone()[0]#el apellido
                    ce=True
                else:
                    ce=False
                    nombreuace="ninguno"
                    apellidouace="ninguno"
                repetido=True
                grupo_actual= group_iden(request)
                return render(request,'Usuario/insertar.html',{'group':grupo_actual,'repetido':repetido,'cedulaR':cc,'telefonoR':tt,'correoR':ce,'cedula':cedula,'nombrerc':nombreuac,'apellidorc':apellidouac,'nombrert':nombreuat,'apellidort':apellidouat,'nombrerce':nombreuace,'apellidorce':apellidouace,'nombre':nombre,'apellido':apellido,'telefono':telefono,'correo':correo,'direccion':direccion,'fecha':fecha,'rol':rol})
            else:
                usuario=User.objects.create_user(request.POST.get('cedula'),request.POST.get('correo'),request.POST.get('contrasena'))
                usuario.first_name=request.POST.get('nombre')
                usuario.last_name=request.POST.get('apellido')
                usuario.save()
                insertgroup=connection.cursor()
                insertgroup.execute("CALL User_group("+request.POST.get('cedula')+","+request.POST.get('Id_rol')+","+request.POST.get('telefono')+","+request.POST.get('fecha_nacimiento')+",'"+request.POST.get('direccion')+"');")
                return redirect('/Usuario/lista')
    else:
        grupo_actual= group_iden(request)
        return render(request,'Usuario/insertar.html',{'group':grupo_actual})
@login_required
def updateUsuario(request,id):
    if request.method=="POST":
        if request.POST.get('cedula') and request.POST.get('nombre') and request.POST.get('apellido') and  request.POST.get('telefono') and request.POST.get('correo') and request.POST.get('direccion') and request.POST.get('fecha_nacimiento'):
            consultac=connection.cursor()#consultar si la cedula se repite
            consultac.execute("select COUNT(id) from auth_user where username='"+request.POST.get('cedula')+"' and username!='"+str(id)+"';")
            consultan=connection.cursor()#consultar si el telefono se repite
            consultan.execute("select COUNT(id) from auth_user where Telefono='"+request.POST.get('telefono')+"' and username!='"+str(id)+"';")
            consultae=connection.cursor()#consultar si el email se repite
            consultae.execute("select COUNT(id) from auth_user where email='"+request.POST.get('correo')+"' and username!='"+str(id)+"';")
            existentec=consultac.fetchone()[0]
            existenten=consultan.fetchone()[0]
            existentee=consultae.fetchone()[0]
            if existentec>0 or existenten>0 or existentee>0: #si se repite alguna almacenamos los datos y verificamos cual de ellos se repite y mandar el respectivo mensaje 
                cedula=request.POST.get('cedula')
                nombre=request.POST.get('nombre')
                apellido=request.POST.get('apellido')
                telefono=request.POST.get('telefono')
                correo=request.POST.get('correo')
                direccion=request.POST.get('direccion')
                fecha=request.POST.get('fecha_nacimiento')
                rol=request.POST.get('Id_rol')
                contraseña=request.POST.get('contraseña')
                if existentec>0:
                    nombreuc=connection.cursor()#nombre usuario con la cedula registrada 'nombreuc:nombre usuario cedula'
                    nombreuc.execute("select first_name from auth_user where username='"+cedula+"';")
                    apellidouc=connection.cursor()
                    apellidouc.execute("select last_name from auth_user where username='"+cedula+"';")
                    nombreuac=nombreuc.fetchone()[0]#nombre del usuario actual con la cedula
                    apellidouac=apellidouc.fetchone()[0]#el apellido
                    cc=True
                else:
                    cc=False
                    nombreuac="ninguno"
                    apellidouac="ninguno"
                if existenten>0:
                    nombreut=connection.cursor()#nombre del usuario que ta tiene asignado el nuemero de telefono 'nombreut:nombre usuario telefono'
                    nombreut.execute("select first_name from auth_user where Telefono='"+telefono+"';")
                    apellidout=connection.cursor()#el apellido
                    apellidout.execute("select last_name from auth_user where Telefono='"+telefono+"';")
                    nombreuat=nombreut.fetchone()[0]#nombre del usuario actual con el numero de telefono
                    apellidouat=apellidout.fetchone()[0]#el apellido
                    tt=True
                else:
                    tt=False
                    nombreuat="ninguno"
                    apellidouat="ninguno"
                if existentee>0:
                    nombreuce=connection.cursor()#nombre del usuario que ya tiene registrado el correo 'nombreuce: nombre usuario correo electronico'
                    nombreuce.execute("select first_name from auth_user where email='"+correo+"';")
                    apellidouce=connection.cursor()#el apellido
                    apellidouce.execute("select last_name from auth_user where email='"+correo+"';")
                    nombreuace=nombreuce.fetchone()[0]#nombre del usuario actual con el correo
                    apellidouace=apellidouce.fetchone()[0]#el apellido
                    ce=True
                else:
                    ce=False
                    nombreuace="ninguno"
                    apellidouace="ninguno"
                repetido=True
                grupo_actual= group_iden(request)
                print(existentec)
                print(existentee)
                print(existenten)
                return render(request,'Usuario/actualizar.html',{'group':grupo_actual,'repetido':repetido,'cedulaR':cc,'telefonoR':tt,'correoR':ce,'cedula':cedula,'nombrerc':nombreuac,'apellidorc':apellidouac,'nombrert':nombreuat,'apellidort':apellidouat,'nombrerce':nombreuace,'apellidorce':apellidouace,'nombre':nombre,'apellido':apellido,'telefono':telefono,'correo':correo,'direccion':direccion,'fecha':fecha,'rol':rol})
            else:
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
            password1=request.POST.get('contrasena')
            password2=request.POST.get('confirmar_contrasena')
            count=0
            if password1 != password2:
                nConiciden=True
                count=+1
            else:
                nConiciden=False
            numeros=[caracter.isdigit() for caracter in password1]
            if all(numeros):
                todonumeros=True
                count=+1
            else:
                todonumeros=False
            if len(password1)<8:
                corta=True
                count=+1
            else:
                corta=False
            with connection.cursor()as cursor:
                cursor.execute("select COUNT(id) from auth_user where first_name LIKE'%"+password1+"%' and username='"+id+"';")
                nombre=cursor.fetchone()[0]
                cursor.execute("select COUNT(id) from auth_user where last_name LIKE'%"+password1+"%' and username='"+id+"';")
                apellido=cursor.fetchone()[0]
                cursor.execute("select COUNT(id) from auth_user where email LIKE'%"+password1+"%' and username='"+id+"';")
                email=cursor.fetchone()[0]
                cursor.execute("select COUNT(id) from auth_user where username ='"+password1+"' and username='"+id+"';")
                cedula=cursor.fetchone()[0]
            if nombre>0:
                nombrep=True
                count=+1
            else:
                nombrep=False
            if apellido>0:
                apellidop=True
                count=+1
            else:
                apellidop=False
            if email>0:
                emailp=True
                count=+1
            else:
                emailp=False
            if cedula>0:
                cedulap=True
                count=+1
            else:
                cedulap=False
            if nConiciden or todonumeros or corta or nombrep or apellidop or emailp or cedulap:
                usuariodata=connection.cursor()
                usuariodata.execute("select username,first_name,last_name from auth_user where username="+str(id)+";")
                grupo_actual= group_iden(request)
                return render(request, "Usuario/insertar_contra.html",{'coinciden':nConiciden,'corta':corta,'numero':todonumeros,'nombre':nombrep,'apellido':apellidop,'email':emailp,'cedula':cedulap,'count':count,'datos':usuariodata,'group':grupo_actual}) 
            else:
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
#endregion
#region Notificaciones
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
#endregion
#region recibo compra
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
    if request.method=='POST':
        proveedores=connection.cursor()    
        proveedor=request.POST.get('NP')
        busqueda=True
        #saber si son letras o numeros
        vv=[caracter.isdigit() for caracter in proveedor]
        if all(vv):
            proveedores.execute("select * from proveedor where Estado=1 and NIT LIKE '%"+str(proveedor)+"%';")
        else:
            proveedores.execute("select * from proveedor where Estado=1 and Nombre LIKE '%"+str(proveedor)+"%';")
    else:
        proveedores=connection.cursor()
        proveedores.execute("select NIT,Nombre from proveedor  where proveedor.Estado=True;")
        busqueda=False
        proveedor=0
    grupo_actual= group_iden(request)
    return render(request,'ReciboCompra/Proveedor.html',{'PROV':proveedores,'group':grupo_actual,'busqueda':busqueda,'NP':proveedor})
@login_required
def Cproveedor(request):
    if request.method=="POST":
        if request.POST.get('nit') and request.POST.get('nombre') and  request.POST.get('telefono') and request.POST.get('horario_atencion') and request.POST.get('politica_devolucion'):
            consulta=connection.cursor()
            consulta.execute("select COUNT(NIT) from proveedor where NIT="+request.POST.get('nit')+" union select COUNT(NIT) from temp_proveedor where NIT="+request.POST.get('nit')+";")
            existencia=consulta.fetchone()[0]
            if existencia>0:
                nitO=connection.cursor()
                nitO.execute("select NIT from proveedor where NIT="+request.POST.get('nit')+";")
                nit=nitO.fetchone()[0]
                nitE=request.POST.get('nit')
                nombre=request.POST.get('nombre')
                telefono=request.POST.get('telefono')
                horario=request.POST.get('horario_atencion')
                politica=request.POST.get('politica_devolucion')
                repetido=1
                nombrep=connection.cursor()
                nombrep.execute("select Nombre,NIT from Proveedor where NIT="+nitE+";")
                nombrepr=nombrep.fetchone()[0]
                grupo_actual= group_iden(request)
                return render(request,'ReciboCompra/Nproveedor.html',{'group':grupo_actual,'repetido':repetido,'nit':nit,'nitE':nitE,'nombre':nombre,'telefono':telefono,'horario':horario,'politica':politica,'nombrepr':nombrepr})
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
    if request.method == 'POST':
        viewA=connection.cursor()
        v=request.POST.get("qp")
        vv=[caracter.isdigit() for caracter in v]
        if all(vv):
            viewA.execute("select id_producto,Nombre from Producto where Estado=True and id_producto LIKE '%"+str(v)+"%'  union select id_producto, Nombre from temp_producto where Estado=True and id_producto LIKE '%"+str(v)+"%';")
        else:
            viewA.execute("select id_producto,Nombre from Producto where Estado=True and Nombre LIKE '%"+str(v)+"%'  union select id_producto, Nombre from temp_producto where Estado=True and Nombre LIKE '%"+str(v)+"%';")
        prod=viewA.fetchall()
        busqueda=True
    else:
        v=0
        busqueda=False
        prod=connection.cursor()
        prod.execute("select id_producto,Nombre from Producto where Estado=True union select id_producto, Nombre from temp_producto where Estado=True;")
    info=connection.cursor ()
    info.execute("select * from temp_compra where id_compra="+str(idc)+";")
    prov=connection.cursor()
    prov.execute("Select Nombre from proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+") union Select Nombre from temp_proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+");")
    ListacombinadaI=list(zip(info,prov))
    grupo_actual= group_iden(request)
    return render(request,'ReciboCompra/Producto.html',{'PROD':prod,'RC':str(idc),'info':ListacombinadaI,'group':grupo_actual,'busqueda':busqueda,'qp':v})
@login_required
def Cproducto(request,idc):
   if request.method=="POST":
        if request.POST.get('codigo') and request.POST.get('nombre')  and request.POST.get('gramo_litro')  and request.POST.get('Max') and request.POST.get('Min'):
            consulta=connection.cursor()
            consulta.execute("select COUNT(nombre) from producto where id_producto="+request.POST.get('codigo')+";")
            consulta2=connection.cursor()
            consulta2.execute("select COUNT(nombre) from temp_producto where id_producto="+request.POST.get('codigo')+";")
            existente=consulta.fetchone()[0]
            existente2=consulta2.fetchone()[0]
            if existente>0 or existente2>0:
                codigoAA=connection.cursor()
                codigoAA.execute("select id_producto from producto where id_producto="+request.POST.get('codigo')+" union select id_producto from temp_producto where id_producto="+request.POST.get('codigo')+";")
                codigoA=codigoAA.fetchone()[0]
                codigo=request.POST.get('codigo')
                nombre=request.POST.get('nombre')
                gramo_litro=request.POST.get('gramo_litro')
                Max=request.POST.get('Max')
                Min=request.POST.get('Min')
                repetido=1
                nombrep=connection.cursor()
                nombrep.execute("select nombre from producto where id_producto="+codigo+" union select nombre from temp_producto where id_producto="+request.POST.get('codigo')+";")
                nombrep2=nombrep.fetchone()[0]
                info=connection.cursor ()
                info.execute("select * from temp_compra where id_compra="+str(idc)+";")
                prov=connection.cursor()
                prov.execute("Select Nombre from proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+") union Select Nombre from temp_proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+");")
                ListacombinadaI=list(zip(info,prov))
                grupo_actual= group_iden(request)
                return render(request,'ReciboCompra/Nproducto.html',{'RC':idc,'info':ListacombinadaI,'codigoA':codigoA,'group':grupo_actual,'codigo':codigo,'nombre':nombre,'nombrep':nombrep2,'gramo_litro':gramo_litro,'Max':Max,'Min':Min,'repetido':repetido})
            else:
                id=request.POST.get('codigo')
                insert=connection.cursor()
                insert.execute("INSERT INTO temp_producto (id_producto,Nombre,GramoLitro,Max,Min)VALUES("+request.POST.get('codigo')+",'"+request.POST.get('nombre')+"','"+request.POST.get('gramo_litro')+"',"+request.POST.get('Max')+","+request.POST.get('Min')+")")
                return redirect(f'/Compra/lote/{idc}/{id}')
   else:
        info=connection.cursor ()
        info.execute("select * from temp_compra where id_compra="+str(idc)+";")
        prov=connection.cursor()
        prov.execute("Select Nombre from proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+") union Select Nombre from temp_proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+");")
        ListacombinadaI=list(zip(info,prov))
        grupo_actual= group_iden(request)
        repetido=0
        return render(request,'ReciboCompra/Nproducto.html',{'repetido':repetido,'RC':idc,'info':ListacombinadaI,'group':grupo_actual})
@login_required
def LoteInsert(request,idc,idp):
    if request.method == 'POST':
        if request.POST.get('Lote') and request.POST.get('Cantidad') and request.POST.get('PrecioC') and request.POST.get('PrecioV') and request.POST.get('FechaVenci'):
            consulta=connection.cursor()
            consulta2=connection.cursor()
            consulta.execute("select COUNT(Loteid) from lote where Loteid='"+request.POST.get('Lote')+"';")
            consulta2.execute("select COUNT(Loteid) from temp_lote where Loteid='"+request.POST.get('Lote')+"';")
            existente=consulta.fetchone()[0]
            existente2=consulta2.fetchone()[0]
            if existente>0 or existente2>0:
                repetido=True
                codigor=request.POST.get('Lote')
                cantidad=request.POST.get('Cantidad')
                precioC=request.POST.get('PrecioC')
                precioV=request.POST.get('PrecioV')
                fechaVenci=request.POST.get('FechaVenci')
                info=connection.cursor ()
                info.execute("select * from temp_compra where id_compra="+str(idc)+";")
                prov=connection.cursor()
                prov.execute("Select Nombre from proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+") union Select Nombre from temp_proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+");")
                ListacombinadaI=list(zip(info,prov))
                grupo_actual= group_iden(request)
                fecha=connection.cursor()
                fecha.execute("select CURDATE();")
                fechaa=fecha.fetchone()[0]
                fechau=fechaa.strftime("%Y-%m-%d")
                return render(request,'ReciboCompra/Loteinsertar.html',{'RC':idc,'info':ListacombinadaI,'datos':consulta,'repetido':repetido,'codigor':codigor,'cantidad':cantidad,'precioC':precioC,'precioV':precioV,'fechaVenci':fechaVenci,'group':grupo_actual,'fecha':fechau})
            else:
                lote=connection.cursor()
                lote.execute("Insert into temp_lote (id_producto,Loteid,Cantidad,PrecioC,Estado,fechaVenci,fechaModify,fechaCreate) values("+str(idp)+",'"+request.POST.get('Lote')+"',"+request.POST.get('Cantidad')+","+request.POST.get('PrecioC')+",True,'"+request.POST.get('FechaVenci')+"',Now(),now());")
                detalle=connection.cursor()
                detalle.execute("Insert into temp_detalle_compra values('"+request.POST.get('Lote')+"',"+request.POST.get('PrecioC')+","+request.POST.get('PrecioV')+","+request.POST.get('Cantidad')+","+str(idc)+");")
                return redirect (f'/Compra/Lista/{idc}')
    else:
        info=connection.cursor ()
        info.execute("select * from temp_compra where id_compra="+str(idc)+";")
        prov=connection.cursor()
        prov.execute("Select Nombre from proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+") union Select Nombre from temp_proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+");")
        fecha=connection.cursor()
        fecha.execute("select CURDATE();")
        fechaa=fecha.fetchone()[0]
        fechau=fechaa.strftime("%Y-%m-%d")
        print(fechau)
        ListacombinadaI=list(zip(info,prov))
        grupo_actual= group_iden(request)
        repetido=False
        return render(request,'ReciboCompra/Loteinsertar.html',{'repetido':repetido,'RC':idc,'info':ListacombinadaI,'group':grupo_actual,'fecha':fechau})
@login_required   
def reciboCompraView(request,idc):
    idc2=idc
    max=connection.cursor()
    lote=connection.cursor()
    lote.execute("select temp_detalle_compra.*,temp_lote.fechaVenci,temp_lote.id_producto,(select nombre from producto where id_producto=temp_lote.id_producto union select nombre from temp_producto where id_producto=temp_lote.id_producto),(select max from producto where id_producto=temp_lote.id_producto union select max from temp_producto where id_producto=temp_lote.id_producto),((select SUM(CantidadProductos) from temp_detalle_compra where (select id_producto from producto where id_producto=temp_lote.id_producto union select id_producto from temp_producto where id_producto=temp_lote.id_producto)=(select id_producto from temp_lote where Loteid=temp_detalle_compra.Lote))+(CASE when (select SUM(Cantidad) from lote where id_producto=temp_lote.id_producto and Estado=True)>0 then (select SUM(Cantidad) from lote where id_producto=temp_lote.id_producto and Estado=True) else 0 end)) from temp_detalle_compra inner join temp_lote on temp_detalle_compra.Lote=temp_lote.loteid where temp_detalle_compra.id_compra="+str(idc2)+";")
    lote2=lote.fetchall()
    info=connection.cursor()
    info.execute("select * from temp_compra where id_compra="+str(idc)+";")
    prov=connection.cursor()
    prov.execute("Select Nombre from proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+") union Select Nombre from temp_proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+");")
    ListacombinadaI=list(zip(info,prov))
    grupo_actual= group_iden(request)
    return render(request,'ReciboCompra/CompraVisualizar.html',{'RC':lote2,'info':ListacombinadaI,'idc':idc2,'group':grupo_actual})
@login_required
def Recibos(request,pag):
    recibos=connection.cursor()
    pagination=connection.cursor()
    if request.method=='POST':
        paginasT=[1,2]
        busqueda=True
        proveedor=request.POST.get('NP')
        recibos.execute("select compra.*,Proveedor.Nombre,format(Compra.Total,'###.###.###.###') from compra inner join proveedor on compra.NIT=Proveedor.NIT where Proveedor.Nombre LIKE '%"+str(proveedor)+"%';")    
    else:
        paginasT=[]
        pagination.execute("select count(id_compra) from compra;")
        paginationN=pagination.fetchone()[0]
        numeroPaginas=paginationN/10
        if paginationN%10 <5 and paginationN%10 !=0:
            numeroPaginas+=1
            numeroPaginas=round(numeroPaginas)
            print(numeroPaginas)
        else:
            numeroPaginas+=0.1
            numeroPaginas=round(numeroPaginas)
            print(numeroPaginas)
        for i in range(numeroPaginas):
            paginasT.append(i+1)
        desd=pag-1
        desde=str(desd)+"0"
        recibos.execute(f"select compra.*,Proveedor.Nombre,format(Compra.Total,'###.###.###.###') from compra inner join proveedor on compra.NIT=Proveedor.NIT order by id_compra asc limit {desde},10;")
        busqueda=False
        proveedor=0
    grupo_actual= group_iden(request)
    return render(request,'ReciboCompra/ListaR.html',{'RC':recibos,'group':grupo_actual,'busqueda':busqueda,'NP':proveedor,'paginas':paginasT,'pagina':pag})
@login_required
def RecibosD(request,idc):
    info=connection.cursor()
    info.execute(f"select compra.*,proveedor.Nombre from compra inner join proveedor on compra.NIT=proveedor.NIT where compra.id_compra={idc}")
    recibo=connection.cursor()
    recibo.execute("select detalle_compra.*,Producto.Nombre,Lote.fechaVenci,Lote.id_producto,format(detalle_compra.Precio,'###.###.###.###'),format(detalle_compra.PrecioU,'###.###.###.###') from detalle_compra inner join Lote on detalle_compra.Lote=Lote.loteid inner join producto on Lote.id_producto=Producto.id_producto where detalle_compra.id_compra="+str(idc)+";")
    grupo_actual= group_iden(request)
    return render(request,'ReciboCompra/ListaRD.html',{'RC':recibo,'group':grupo_actual,'info':info})
@login_required
def LoteUpdate(request,idc,idl):
    if request.method == 'POST':
        if request.POST.get('Lote') and request.POST.get('Cantidad') and request.POST.get('PrecioC') and request.POST.get('PrecioV') and request.POST.get('FechaVenci'):
            loteOO=request.POST.get('Lote')
            if loteOO==idl:
                insert=connection.cursor()
                insert.execute("Update temp_lote set Loteid='"+request.POST.get('Lote')+"',Cantidad="+request.POST.get('Cantidad')+",PrecioC="+request.POST.get('PrecioC')+",fechaVenci='"+request.POST.get('FechaVenci')+"',fechaModify=now() where Loteid='"+str(idl)+"';")
                insert=connection.cursor()
                insert.execute("Update temp_detalle_Compra set Lote='"+request.POST.get('Lote')+"' ,Precio="+request.POST.get('PrecioC')+",PrecioU="+request.POST.get('PrecioV')+",CantidadProductos="+request.POST.get('Cantidad')+" where id_compra="+str(idc)+" and Lote='"+str(idl)+"';")
                return redirect(f'/Compra/Lista/{idc}')
            else:
                consulta=connection.cursor()
                consulta.execute("select COUNT(Loteid) from lote where Loteid='"+request.POST.get('Lote')+"';")
                consulta2=connection.cursor()
                consulta2.execute("select COUNT(Loteid) from temp_lote where Loteid='"+request.POST.get('Lote')+"';")
                existente=consulta.fetchone()[0]
                existente2=consulta2.fetchone()[0]
                if existente>0 or existente2>0:
                    repetido=True
                    codigoO=idl
                    codigor=request.POST.get('Lote')
                    cantidad=request.POST.get('Cantidad')
                    precioC=request.POST.get('PrecioC')
                    precioV=request.POST.get('PrecioV')
                    fechaVenci=request.POST.get('FechaVenci')
                    info=connection.cursor ()
                    info.execute("select * from temp_compra where id_compra="+str(idc)+";")
                    prov=connection.cursor()
                    prov.execute("Select Nombre from proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+") union Select Nombre from temp_proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+");")
                    ListacombinadaI=list(zip(info,prov))
                    grupo_actual= group_iden(request)
                    return render(request,"ReciboCompra/LoteActualizar.html",{'info':ListacombinadaI,'repetido':repetido,'codigoO':codigoO,'codigor':codigor,'cantidad':cantidad,'precioC':precioC,'precioV':precioV,'fechaVenci':fechaVenci,'group':grupo_actual})
                else:
                    insert=connection.cursor()
                    insert.execute("Update temp_lote set Loteid='"+request.POST.get('Lote')+"',Cantidad="+request.POST.get('Cantidad')+",PrecioC="+request.POST.get('PrecioC')+",fechaVenci='"+request.POST.get('FechaVenci')+"',fechaModify=now() where Loteid='"+str(idl)+"';")
                    insert=connection.cursor()
                    insert.execute("Update temp_detalle_Compra set Lote='"+request.POST.get('Lote')+"' ,Precio="+request.POST.get('PrecioC')+",PrecioU="+request.POST.get('PrecioV')+",CantidadProductos="+request.POST.get('Cantidad')+" where id_compra="+str(idc)+" and Lote='"+str(idl)+"';")
                    return redirect(f'/Compra/Lista/{idc}')
    else:
        lote=connection.cursor()
        lote.execute("select temp_lote.*,temp_detalle_compra.PrecioU from temp_lote inner join temp_detalle_compra on temp_lote.Loteid=temp_detalle_compra.Lote where Loteid='"+str(idl)+"';")
        info=connection.cursor ()
        info.execute("select * from temp_compra where id_compra="+str(idc)+";")
        prov=connection.cursor()
        prov.execute("Select Nombre from proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+") union Select Nombre from temp_proveedor where NIT=(select NIT from temp_compra where id_compra="+str(idc)+");")
        ListacombinadaI=list(zip(info,prov))
        grupo_actual= group_iden(request)
        return render(request,"ReciboCompra/LoteActualizar.html",{'lote':lote,'info':ListacombinadaI,'group':grupo_actual})
@login_required
def Recibos_Finalizar(request):
    proveedor=connection.cursor()
    proveedor.execute("INSERT INTO proveedor SELECT * FROM temp_proveedor;")
    producto=connection.cursor()
    producto.execute("INSERT INTO producto SELECT * FROM temp_producto;")
    lote=connection.cursor()
    lote.execute("INSERT INTO lote SELECT *FROM temp_lote;")
    compra=connection.cursor()
    compra.execute("INSERT INTO compra SELECT * FROM temp_compra;")
    detalle_compra=connection.cursor()
    detalle_compra.execute("INSERT INTO detalle_compra SELECT * FROM temp_detalle_compra;")

    delete=connection.cursor()
    delete.execute("call Delete_Temp;")
    return redirect('/Compra/Recibos/1')
@login_required
def Recibos_Cancelar(request):
    delete=connection.cursor()
    delete.execute("call Delete_Temp;")
    return redirect('/Compra/Recibos/1')
#endregion
#region Venta
@login_required
def registro_venta(request):
    grupo_actual=group_iden(request)
    return render(request, 'Venta/registro.html',{'group':grupo_actual})
def venta_crear_factura(request,user):
    procedimiento=connection.cursor()
    procedimiento.execute(f"call Venta_id({str(user)});")
    datos=procedimiento.fetchone()[0]
    iDV=dict([('id_venta',datos)])
    return JsonResponse(iDV,safe=False)
def registo_detalleVenta(request,idP,Cant,Posi):
    procedimiento=connection.cursor()
    procedimiento.execute(f"call Venta_Registo({str(idP)},{str(Cant)},{str(Posi)});")
    datos=procedimiento.fetchone()[0]
    subtotal=dict([('Subtotal',datos)])
    return JsonResponse(subtotal,safe=False)
def venta_eliminar_API(request,idV,posi):
    procedimiento=connection.cursor()
    procedimiento.execute(f"call Borrar_producto_venta({str(idV)},{str(posi)})")
    HttpResponse('Se a Eliminado correctamente')
def venta_Cancelar_API(request,idV):
    procedimiento=connection.cursor()
    procedimiento.execute(f"call Cancelar_venta({str(idV)})")
    HttpResponse('Se a cancelado Correctamente')
def venta_DONE(request,idV,efectivo):
    with connection.cursor() as consulta:
        consulta.execute(f"select TotalCompra from venta where id_venta={str(idV)}")
        total=consulta.fetchone()[0]
        consulta.execute(f"update venta set Efectivo_Recibido={str(efectivo)} where id_venta={str(idV)};")
    devolver=efectivo-int(total)
    entregado=connection.cursor()
    entregado.execute(f"update venta set Efectivo_Entregado={str(devolver)}, Hora=Now() where id_venta={str(idV)};")
    json=dict([('Devolver',devolver)])
    return JsonResponse(json,safe=False)
def venta_dias(request):
    dias=connection.cursor()
    dias.execute("call Dias_Venta()")
    group=group_iden(request)
    return render(request, "Venta/Dias.html",{'dias':dias,'group':group})
def venta_Info(request,fecha):
    info=connection.cursor()
    print(fecha)
    info.execute(f"Select venta.* ,auth_user.first_name, auth_user.last_name from venta inner join auth_user on venta.Cedula=auth_user.username where Fecha='{fecha}' and TotalCompra>0;")
    infoV=connection.cursor()
    infoV.execute("select detalle_venta.id_venta, lote.id_producto,producto.Nombre,detalle_venta.PrecioU,detalle_venta.Cantidad,detalle_venta.TotalProducto from detalle_venta inner join lote on lote.Loteid=detalle_venta.id_Lote INNER join producto on lote.id_producto=producto.id_producto  GROUP by detalle_venta.id_venta, detalle_venta.PosicionTabla;")
    group=group_iden(request)
    return render(request, "Venta/Infor_Ventas.html",{'info':info,'infoV':infoV,'group':group})
#endregion
#logout
def salir(request):
    username= nombredelusuario(request)
    with connection.cursor() as cursor:
        cursor.execute(f"update auth_user set hora_logout=now() where username={username};")
        cursor.execute(f"call calcularHoras('{username}');")
    logout(request)
    return redirect('login')