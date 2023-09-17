from django.db import models

class Producto(models.Model):
    id_producto=models.CharField(max_length=20)
    Nombre=models.CharField(max_length=30)
    Estado=models.CharField(max_length=30)
    PrecioC=models.CharField(max_length=11)
    PrecioT=models.CharField(max_length=11)
    GramoLitro=models.CharField(max_length=30)
    Cantidad=models.CharField(max_length=11)
    Fecha_Modificacion=models.CharField(max_length=230)
    Lote=models.CharField(max_length=7)
    Max=models.CharField(max_length=11)
    Min=models.CharField(max_length=11)
    class Meta():
        db_table='producto'
class Vencimiento(models.Model):
    fechaV=models.CharField(max_length=230)
    id_producto=models.CharField(max_length=20)
    Lote=models.CharField(max_length=7)
    class Meta():
        db_table='vencimiento'