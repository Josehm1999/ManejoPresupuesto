using System.Security.Claims;

namespace ManejoPresupuesto.Servicios
{

    public interface IServicioUsuarios
    {
        int ObtenerUsuarioId();
        string ObtenerUsuarioEmail();
    }

    public class ServicioUsuarios : IServicioUsuarios
    {
        private readonly HttpContext httpContext;

        public ServicioUsuarios(IHttpContextAccessor httpContextAccessor)
        {
            httpContext = httpContextAccessor.HttpContext;
        }

        public int ObtenerUsuarioId()
        {
            if (httpContext.User.Identity.IsAuthenticated)
            {
                var idClaim = httpContext.User
                        .Claims.Where(x => x.Type == ClaimTypes.NameIdentifier).FirstOrDefault();
                var id = int.Parse(idClaim.Value);
                return id;
            }
            else
            {
                throw new ApplicationException("El usuario no está autenticado");
            }
        }

        public string ObtenerUsuarioEmail()
        {
            if (httpContext.User.Identity.IsAuthenticated)
            {
                var emailClaim = httpContext.User
                        .Claims.Where(x => x.Type == ClaimTypes.Email).FirstOrDefault();
                var email = emailClaim.Value;
                return email;
            }
            else
            {
                throw new ApplicationException("El usuario no está autenticado");
            }
        }
    }
}
