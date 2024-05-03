# middleware.py



class SessionExpirationMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        
        # Verifica si el usuario está autenticado
        if request.user.is_authenticated:
            # Configura la expiración de la sesión al cerrar la ventana del navegador
            request.session.set_expiry(0)
        
        return response
