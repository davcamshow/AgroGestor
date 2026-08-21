from api.models import UsuarioInvitado


def get_account_owner(auth_user):
    """Resuelve la cuenta propietaria para el perfil autenticado."""
    profile = auth_user.perfil
    invitation = (
        UsuarioInvitado.objects.filter(usuario=profile, activo=True)
        .select_related('cuenta_principal')
        .order_by('id')
        .first()
    )
    return invitation.cuenta_principal if invitation else profile
