from rest_framework.permissions import BasePermission, SAFE_METHODS

ADMIN_GROUP = 'Administrador'
GERENTE_PRODUCCION_GROUP = 'Gerente de Producción'
VETERINARIO_GROUP = 'Veterinario'
NUTRICIONISTA_GROUP = 'Nutricionista'
OPERARIO_CAMPO_GROUP = 'Operario de Campo'
CONTADOR_GROUP = 'Contador'

class HasGroupPermission(BasePermission):
    """
    Permiso personalizado que verifica si el usuario pertenece a un grupo específico.
    Los administradores tienen acceso a todo.
    """
    def __init__(self, allowed_groups):
        self.allowed_groups = allowed_groups

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        # Administradores tienen acceso a todo
        if request.user.groups.filter(name=ADMIN_GROUP).exists():
            return True
        return request.user.groups.filter(name__in=self.allowed_groups).exists()


# Declaremos clases de solo lectura para cada grupo, pero acceso total para administradores 
class IsGroupViewOnly(BasePermission):
    """Permiso de solo lectura para un grupo específico."""
    def __init__(self, group_name):
        self.group_name = group_name

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.groups.filter(name=ADMIN_GROUP).exists():
            return True
        return request.method in SAFE_METHODS and request.user.groups.filter(name=self.group_name).exists()

class IsGerenteViewOnly(IsGroupViewOnly):
    def __init__(self):
        super().__init__(GERENTE_PRODUCCION_GROUP)

class IsVeterinarioViewOnly(IsGroupViewOnly):
    def __init__(self):
        super().__init__(VETERINARIO_GROUP)

class IsNutricionistaViewOnly(IsGroupViewOnly):
    def __init__(self):
        super().__init__(NUTRICIONISTA_GROUP)

class IsOperarioCampoViewOnly(IsGroupViewOnly):
    def __init__(self):
        super().__init__(OPERARIO_CAMPO_GROUP)

class IsContadorViewOnly(IsGroupViewOnly):
    def __init__(self):
        super().__init__(CONTADOR_GROUP)


# Clases combinadas para permisos de solo lectura para un grupo específico, pero acceso total para otro grupo
class IsGerenteReadOnlyOrNutricionista(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.groups.filter(name=ADMIN_GROUP).exists():
            return True
        if request.user.groups.filter(name=NUTRICIONISTA_GROUP).exists():
            return True
        if request.method in SAFE_METHODS and request.user.groups.filter(name=GERENTE_PRODUCCION_GROUP).exists():
            return True
        return False
    
class IsContadorReadOnlyOrGerenteOrOperario(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.groups.filter(name=ADMIN_GROUP).exists():
            return True
        if request.user.groups.filter(name=GERENTE_PRODUCCION_GROUP).exists():
            return True
        if request.user.groups.filter(name=OPERARIO_CAMPO_GROUP).exists():
            return True
        if request.method in SAFE_METHODS and request.user.groups.filter(name=CONTADOR_GROUP).exists():
            return True
        return False
    
class IsGerenteReadOnlyOrOperarioReadOnlyOrVeterinario(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.groups.filter(name=ADMIN_GROUP).exists():
            return True
        if request.user.groups.filter(name=VETERINARIO_GROUP).exists():
            return True
        if request.method in SAFE_METHODS and (request.user.groups.filter(name=GERENTE_PRODUCCION_GROUP).exists() or request.user.groups.filter(name=OPERARIO_CAMPO_GROUP).exists()):
            return True
        return False

class IsOperarioReadOnlyOrGerenteReadOnlyOrContador(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.groups.filter(name=ADMIN_GROUP).exists():
            return True
        if request.user.groups.filter(name=GERENTE_PRODUCCION_GROUP).exists():
            return True
        if request.method in SAFE_METHODS and (request.user.groups.filter(name=OPERARIO_CAMPO_GROUP).exists() or request.user.groups.filter(name=CONTADOR_GROUP).exists()):
            return True
        return False

class IsGerenteReadOnlyOrOperarioReadOnlyOrVeterinarioOrNutricionista(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.groups.filter(name=ADMIN_GROUP).exists():
            return True
        if request.user.groups.filter(name=VETERINARIO_GROUP).exists():
            return True
        if request.user.groups.filter(name=NUTRICIONISTA_GROUP).exists():
            return True
        if request.method in SAFE_METHODS and (request.user.groups.filter(name=GERENTE_PRODUCCION_GROUP).exists() or request.user.groups.filter(name=OPERARIO_CAMPO_GROUP).exists()):
            return True
        return False

class AnyoneReadOnlyExceptContador(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.groups.filter(name=ADMIN_GROUP).exists():
            return True
        if request.method in SAFE_METHODS and request.user.groups.filter(name=GERENTE_PRODUCCION_GROUP).exists() or request.method in SAFE_METHODS and request.user.groups.filter(name=OPERARIO_CAMPO_GROUP).exists() or request.method in SAFE_METHODS and request.user.groups.filter(name=VETERINARIO_GROUP).exists() or request.method in SAFE_METHODS and request.user.groups.filter(name=NUTRICIONISTA_GROUP).exists():
            return True
        return False

# Clases de permisos por rol
class IsVeterinario(HasGroupPermission):
    def __init__(self):
        super().__init__([VETERINARIO_GROUP])

class IsNutricionista(HasGroupPermission):
    def __init__(self):
        super().__init__([NUTRICIONISTA_GROUP])

class IsOperarioCampo(HasGroupPermission):
    def __init__(self):
        super().__init__([OPERARIO_CAMPO_GROUP])

class IsGerenteProduccion(HasGroupPermission):
    def __init__(self):
        super().__init__([GERENTE_PRODUCCION_GROUP])

class IsContador(HasGroupPermission):
    def __init__(self):
        super().__init__([CONTADOR_GROUP])

class IsAdministrador(HasGroupPermission):
    def __init__(self):
        super().__init__([ADMIN_GROUP])



# Clases combinadas para múltiples roles
class IsGerenteOrContador(HasGroupPermission):
    def __init__(self):
        super().__init__([GERENTE_PRODUCCION_GROUP, CONTADOR_GROUP])

class IsGerenteOrOperarioOrVeterinarioOrNutricionista(HasGroupPermission):
    def __init__(self):
        super().__init__([GERENTE_PRODUCCION_GROUP, OPERARIO_CAMPO_GROUP, VETERINARIO_GROUP, NUTRICIONISTA_GROUP])

class AnyoneExceptContador(HasGroupPermission):
    def __init__(self):
        super().__init__([GERENTE_PRODUCCION_GROUP, OPERARIO_CAMPO_GROUP, VETERINARIO_GROUP, NUTRICIONISTA_GROUP, ADMIN_GROUP])

class IsGerenteOrVeterinarioOrOperario(HasGroupPermission):
    def __init__(self):
        super().__init__([GERENTE_PRODUCCION_GROUP, VETERINARIO_GROUP, OPERARIO_CAMPO_GROUP])