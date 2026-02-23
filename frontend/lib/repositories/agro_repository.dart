import '../models/agro_categoria.dart';
import '../models/agro_producto.dart';
import '../services/agro_api_service.dart';

/// Repository del módulo AgroConnect.
///
/// Regla MVVM: abstrae la fuente de datos de los ViewModels.
/// Si en el futuro hay caché local o múltiples fuentes, solo cambia aquí.
class AgroRepository {
  final AgroApiService _apiService;

  AgroRepository({AgroApiService? apiService})
    : _apiService = apiService ?? AgroApiService();

  // ── Categorías ──────────────────────────────────────────────────────────

  /// Obtiene todas las categorías agrícolas del backend.
  Future<List<AgroCategoria>> obtenerCategorias() {
    return _apiService.getCategorias();
  }

  // ── Productos ───────────────────────────────────────────────────────────

  /// Obtiene productos, filtrando opcionalmente por categoría.
  Future<List<AgroProducto>> obtenerProductos({int? idCategoria}) {
    return _apiService.getProductos(idCategoria: idCategoria);
  }

  /// Publica un nuevo producto en el mercado.
  Future<AgroProducto> publicarProducto(AgroProductoCreate producto) {
    return _apiService.crearProducto(producto);
  }
}
