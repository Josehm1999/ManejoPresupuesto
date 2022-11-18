using ManejoPresupuesto.Models;
using ManejoPresupuesto.Servicios;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuesto.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class APICategoriasController: ControllerBase
    {
        private readonly IRepositorioCategorias repositorioCategorias;
        private readonly IServicioUsuarios servicioUsuarios;

        public APICategoriasController(IRepositorioCategorias repositorioCategorias,
            IServicioUsuarios servicioUsuarios)
        {
            this.repositorioCategorias = repositorioCategorias;
            this.servicioUsuarios = servicioUsuarios;
        }


        [HttpPost("~/crear")]
        public async Task<IActionResult> Crear(Categoria categoria)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest();
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            categoria.UsuarioId = usuarioId;
            await repositorioCategorias.Crear(categoria);
            return Ok();
        }


        [HttpPut("~/editar")]
        public async Task<IActionResult> Editar(Categoria categoriaEditar)
        {
            if (!ModelState.IsValid)
            {
                return Ok(categoriaEditar);
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var categoria = await repositorioCategorias.ObtenerPorId(categoriaEditar.Id, usuarioId);

            if (categoria is null)
            {
                return BadRequest();
            }

            categoriaEditar.UsuarioId = usuarioId;
            await repositorioCategorias.Actualizar(categoriaEditar);
            return Ok();
        }

        [HttpGet("~/categorias/{usuarioId}")]
        public async Task<IActionResult> ObtenerCategoriasPorUsuario(int usuarioId){
        var categorias = await repositorioCategorias.Obtener(usuarioId);
            if (categorias is null){
                return BadRequest();
            }
            return Ok(categorias);
        }

        [HttpGet("~/categorias/{usuarioId}/{categoriaId}")]
        public async Task<IActionResult> ObtenerCategoria(int categoriaId, int usuarioId){
        var categoria = await repositorioCategorias.ObtenerPorId(categoriaId,usuarioId);
            if (categoria is null){
                return BadRequest();
            }
            return Ok(categoria);
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerCategorias(int usuarioId,
            TipoOperacion tipoOperacion)
        {
            var categorias = await repositorioCategorias.Obtener(usuarioId, tipoOperacion);
            return categorias.Select(x => new SelectListItem(x.Nombre, x.Id.ToString()));
        }

        [HttpPost("~/categorias/tipoOperacion")]
        public async Task<IActionResult> ObtenerCategorias([FromBody] TipoOperacion tipoOperacion)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var categorias = await ObtenerCategorias(usuarioId, tipoOperacion);
            return Ok(categorias);
        }



        [HttpDelete("~/borrar")]
        public async Task<IActionResult> BorrarCategoria(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var categoria = await repositorioCategorias.ObtenerPorId(id, usuarioId);

            if (categoria is null)
            {
                return BadRequest();
            }

            await repositorioCategorias.Borrar(id);
            return Ok();
        }
    }
}
