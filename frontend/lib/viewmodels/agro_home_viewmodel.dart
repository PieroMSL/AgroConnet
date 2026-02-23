import 'package:flutter/material.dart';
import '../models/agro_categoria.dart';
import '../models/agro_producto.dart';
import '../repositories/agro_repository.dart';

/// Estados posibles de la pantalla Home.
enum AgroHomeEstado { inicial, cargando, exito, error, vacio }

/// ViewModel para la pantalla principal de AgroConnect (Home).
///
/// Responsabilidades:
/// - Carga categorías y productos desde el repository.
/// - Mantiene el estado de filtrado (categoría seleccionada).
/// - Aplica búsqueda local por texto sobre la lista ya cargada.
class AgroHomeViewModel extends ChangeNotifier {
  final AgroRepository _repository;

  AgroHomeViewModel({AgroRepository? repository})
    : _repository = repository ?? AgroRepository();

  // ── Estado ──────────────────────────────────────────────────────────────
  AgroHomeEstado _estado = AgroHomeEstado.inicial;
  AgroHomeEstado get estado => _estado;

  String _mensajeError = '';
  String get mensajeError => _mensajeError;

  // ── Datos ────────────────────────────────────────────────────────────────
  List<AgroCategoria> _categorias = [];
  List<AgroCategoria> get categorias => _categorias;

  List<AgroProducto> _todosLosProductos = [];

  List<AgroProducto> _productosFiltrados = [];
  List<AgroProducto> get productos => _productosFiltrados;

  // ── Filtros ──────────────────────────────────────────────────────────────
  int? _categoriaSeleccionada; // null = "Todos"
  int? get categoriaSeleccionada => _categoriaSeleccionada;

  String _query = '';
  String get query => _query;

  // ── Carga inicial ────────────────────────────────────────────────────────

  /// Carga categorías y todos los productos en paralelo.
  /// [forzar]: si true limpia la caché (útil para pull-to-refresh).
  Future<void> cargarDatos({bool forzar = false}) async {
    if (forzar) {
      _todosLosProductos = [];
      _categorias = [];
    }
    _estado = AgroHomeEstado.cargando;
    _mensajeError = '';
    notifyListeners();

    try {
      // Carga en paralelo para mayor velocidad de respuesta
      final resultados = await Future.wait([
        _repository.obtenerCategorias(),
        _repository.obtenerProductos(),
      ]);

      _categorias = resultados[0] as List<AgroCategoria>;
      _todosLosProductos = resultados[1] as List<AgroProducto>;

      // Aplica los filtros activos sobre los datos recién cargados
      _aplicarFiltros();

      _estado = _productosFiltrados.isEmpty
          ? AgroHomeEstado.vacio
          : AgroHomeEstado.exito;
    } catch (e) {
      _mensajeError = e.toString();
      _estado = AgroHomeEstado.error;
      print('❌ [AgroHomeViewModel] Error al cargar datos: $e');
    }

    notifyListeners();
  }

  // ── Filtrado por categoría ────────────────────────────────────────────────

  /// Selecciona una categoría. Pasar null para "Todos".
  Future<void> filtrarPorCategoria(int? idCategoria) async {
    if (_categoriaSeleccionada == idCategoria) return;

    _categoriaSeleccionada = idCategoria;
    _estado = AgroHomeEstado.cargando;
    notifyListeners();

    try {
      if (idCategoria == null) {
        // Sin filtro: si ya tenemos todos los productos usamos la caché
        if (_todosLosProductos.isEmpty) {
          _todosLosProductos = await _repository.obtenerProductos();
        }
      } else {
        // Con filtro: pedimos al backend solo los de esa categoría
        final filtrados = await _repository.obtenerProductos(
          idCategoria: idCategoria,
        );
        // Actualiza solo los de esa categoría en la lista completa para coherencia
        _todosLosProductos
          ..removeWhere((p) => p.idCategoria == idCategoria)
          ..addAll(filtrados);
      }

      _aplicarFiltros();
      _estado = _productosFiltrados.isEmpty
          ? AgroHomeEstado.vacio
          : AgroHomeEstado.exito;
    } catch (e) {
      _mensajeError = e.toString();
      _estado = AgroHomeEstado.error;
    }

    notifyListeners();
  }

  // ── Búsqueda local ────────────────────────────────────────────────────────

  /// Filtra los productos cargados por texto (búsqueda local, sin red).
  void buscar(String texto) {
    _query = texto.trim().toLowerCase();
    _aplicarFiltros();
    notifyListeners();
  }

  // ── Lógica interna ────────────────────────────────────────────────────────

  void _aplicarFiltros() {
    List<AgroProducto> resultado = List.from(_todosLosProductos);

    // Filtro por categoría seleccionada
    if (_categoriaSeleccionada != null) {
      resultado = resultado
          .where((p) => p.idCategoria == _categoriaSeleccionada)
          .toList();
    }

    // Filtro por texto de búsqueda
    if (_query.isNotEmpty) {
      resultado = resultado
          .where(
            (p) =>
                p.titulo.toLowerCase().contains(_query) ||
                (p.descripcion?.toLowerCase().contains(_query) ?? false),
          )
          .toList();
    }

    _productosFiltrados = resultado;
  }
}
