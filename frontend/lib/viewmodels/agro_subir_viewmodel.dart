import 'package:flutter/material.dart';
import '../models/agro_categoria.dart';
import '../models/agro_producto.dart';
import '../repositories/agro_repository.dart';

/// Estados posibles del formulario de subida.
enum AgroSubirEstado {
  inicial,
  cargandoCategorias,
  listo,
  enviando,
  exito,
  error,
}

/// ViewModel para la pantalla "Subir Producto" (vista del productor).
///
/// Responsabilidades:
/// - Carga categorías para el dropdown.
/// - Valida el formulario.
/// - Envía el POST al backend vía repository.
/// - Expone el estado al formulario (loading, error, éxito).
class AgroSubirViewModel extends ChangeNotifier {
  final AgroRepository _repository;

  AgroSubirViewModel({AgroRepository? repository})
    : _repository = repository ?? AgroRepository();

  // ── Estado ──────────────────────────────────────────────────────────────
  AgroSubirEstado _estado = AgroSubirEstado.inicial;
  AgroSubirEstado get estado => _estado;

  String _mensajeError = '';
  String get mensajeError => _mensajeError;

  // ── Datos del formulario ─────────────────────────────────────────────────
  final formKey = GlobalKey<FormState>();

  String titulo = '';
  String descripcion = '';
  String precioTexto = '';
  String stockTexto = '';

  // Setters con notifyListeners para que el Dropdown se actualice visualmente
  String? _unidadMedida;
  String? get unidadMedida => _unidadMedida;
  set unidadMedida(String? v) {
    _unidadMedida = v;
    notifyListeners();
  }

  int? _idCategoriaSeleccionada;
  int? get idCategoriaSeleccionada => _idCategoriaSeleccionada;
  set idCategoriaSeleccionada(int? v) {
    _idCategoriaSeleccionada = v;
    notifyListeners();
  }

  // ID fijo del productor para el demo (se puede vincular con Firebase Auth)
  static const int _idProductorDemo = 1;

  // ── Categorías para el dropdown ───────────────────────────────────────────
  List<AgroCategoria> _categorias = [];
  List<AgroCategoria> get categorias => _categorias;

  // ── Carga de categorías ──────────────────────────────────────────────────

  /// Llama al backend para llenar el dropdown de categorías.
  Future<void> cargarCategorias() async {
    if (_categorias.isNotEmpty) return; // Evitar recarga innecesaria

    _estado = AgroSubirEstado.cargandoCategorias;
    notifyListeners();

    try {
      _categorias = await _repository.obtenerCategorias();
      _estado = AgroSubirEstado.listo;
    } catch (e) {
      _mensajeError = 'No se pudieron cargar las categorías: $e';
      _estado = AgroSubirEstado.error;
      print('❌ [AgroSubirViewModel] Error al cargar categorías: $e');
    }

    notifyListeners();
  }

  // ── Publicar producto ─────────────────────────────────────────────────────

  /// Valida el formulario y envía el POST al backend.
  Future<void> subirProducto({String? base64Image}) async {
    if (!formKey.currentState!.validate()) return;
    if (idCategoriaSeleccionada == null) {
      _mensajeError = 'Selecciona una categoría.';
      notifyListeners();
      return;
    }

    formKey.currentState!.save();

    _estado = AgroSubirEstado.enviando;
    _mensajeError = '';
    notifyListeners();

    try {
      final precio = double.parse(precioTexto.replaceAll(',', '.'));
      int? stock;
      if (stockTexto.trim().isNotEmpty) {
        stock = int.tryParse(stockTexto.trim());
      }

      final nuevoProducto = AgroProductoCreate(
        titulo: titulo.trim(),
        descripcion: descripcion.trim().isEmpty ? null : descripcion.trim(),
        precio: precio,
        stock: stock,
        unidadMedida: unidadMedida,
        idCategoria: idCategoriaSeleccionada!,
        idVendedor: _idProductorDemo,
        urlImagen: base64Image,
      );

      await _repository.publicarProducto(nuevoProducto);

      // Limpiar formulario tras éxito
      _limpiarFormulario();
      _estado = AgroSubirEstado.exito;
      print('✅ [AgroSubirViewModel] Producto publicado correctamente.');
    } catch (e) {
      _mensajeError = 'Error al publicar: ${e.toString()}';
      _estado = AgroSubirEstado.error;
      print('❌ [AgroSubirViewModel] Error al subir producto: $e');
    }

    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void _limpiarFormulario() {
    titulo = '';
    descripcion = '';
    precioTexto = '';
    stockTexto = '';
    _unidadMedida = null; // sin notifyListeners (ya se notifica en exito)
    _idCategoriaSeleccionada = null;
    formKey.currentState?.reset();
  }

  /// Reinicia el estado a listo (para poder publicar otro producto).
  void reiniciar() {
    _estado = AgroSubirEstado.listo;
    notifyListeners();
  }
}
