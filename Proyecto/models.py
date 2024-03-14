from django.db import models

class Producto(models.Model):
    id_producto=models.CharField(max_length=20)
    Nombre=models.CharField(max_length=30)
    estado=models.CharField(max_length=30)
    GramoLitro=models.CharField(max_length=30)
    Fecha_Modificacion=models.CharField(max_length=230)
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
