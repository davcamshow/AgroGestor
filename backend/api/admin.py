from django.contrib import admin
from .models import Usuario, Proveedor, CategoriaInsumo, Insumo, MovimientoInventario, Dieta, DietaInsumo, Lote, PesajeLote, AlimentacionDiaria
# Register your models here.

admin.site.register(Usuario)
admin.site.register(Proveedor) 
admin.site.register(CategoriaInsumo)
admin.site.register(Insumo)
admin.site.register(MovimientoInventario)
admin.site.register(Dieta)
admin.site.register(DietaInsumo)
admin.site.register(Lote)
admin.site.register(PesajeLote)
admin.site.register(AlimentacionDiaria)
