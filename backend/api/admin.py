from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth.models import User
from .models import Usuario, Proveedor, CategoriaInsumo, Insumo, MovimientoInventario, Dieta, DietaInsumo, Lote, PesajeLote, AlimentacionDiaria, Animal, CicloReproductivo, RegistroPeso, EventoSanitario

# Custom User Admin to include groups (groups ya está en Permissions, pero aseguramos)
class CustomUserAdmin(UserAdmin):
    pass  # Por ahora, solo para extender si es necesario

# Unregister the default User admin and register the custom one
admin.site.unregister(User)
admin.site.register(User, CustomUserAdmin)

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
# Bovion models
admin.site.register(Animal)
admin.site.register(CicloReproductivo)
admin.site.register(RegistroPeso)
admin.site.register(EventoSanitario)
