import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/agro_categoria.dart';
import '../models/agro_producto.dart';
import '../models/agro_usuario.dart';

/// Servicio HTTP para comunicarse con el backend FastAPI - módulo AgroConnect.
///
/// Regla MVVM: este servicio SOLO hace HTTP, no toma decisiones de negocio.
/// Toda la lógica vive en el Repository y el ViewModel.
class AgroApiService {
  // ── URL base del backend (Render) ──────────────────────────────────────
  // Sin slash al final: los paths ya los incluye cada método.
  static const String _baseUrl =
      'https://backend-zh2s.onrender.com'; // https://backend-zh2s.onrender.com

  // ── Cabeceras estándar ──────────────────────────────────────────────────
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // ── CATEGORÍAS ──────────────────────────────────────────────────────────

  /// GET /api/agro/categorias
  Future<List<AgroCategoria>> getCategorias() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/agro/categorias');
      print('📤 [AgroApiService] GET $uri');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 60)); // cold start Render ~50s

      print('📥 [AgroApiService] Categorías status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        // Maneja lista plana o envuelta en {data: [...]}
        final List<dynamic> lista = decoded is List
            ? decoded
            : (decoded['data'] as List);
        return lista.map((e) => AgroCategoria.fromJson(e)).toList();
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [AgroApiService] getCategorias: $e');
      rethrow;
    }
  }

  // ── PRODUCTOS ───────────────────────────────────────────────────────────

  /// GET /api/agro/productos?id_categoria=X&solo_activos=true
  Future<List<AgroProducto>> getProductos({int? idCategoria}) async {
    try {
      final queryParams = {
        if (idCategoria != null) 'id_categoria': idCategoria.toString(),
      };
      final uri = Uri.parse(
        '$_baseUrl/api/agro/productos',
      ).replace(queryParameters: queryParams);

      print('📤 [AgroApiService] GET $uri');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 60)); // cold start Render ~50s

      print('📥 [AgroApiService] Productos status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> lista = decoded is List
            ? decoded
            : (decoded['data'] as List);
        return lista.map((e) => AgroProducto.fromJson(e)).toList();
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [AgroApiService] getProductos: $e');
      rethrow;
    }
  }

  /// POST /api/agro/productos
  ///
  /// Acepta 200 (FastAPI custom) o 201 (Supabase Prefer:return).
  /// Maneja tres formatos de respuesta:
  ///   [{...}]                   → lista directa (Supabase)
  ///   {"data": [{...}], ...}    → wrapper personalizado
  ///   {...}                     → objeto directo
  Future<AgroProducto> crearProducto(AgroProductoCreate producto) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/agro/productos');
      final body = jsonEncode(producto.toJson());

      print('📤 [AgroApiService] POST $uri | body: $body');

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 60)); // cold start Render ~50s

      print('📥 [AgroApiService] POST status: ${response.statusCode}');
      print('📥 [AgroApiService] body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));

        Map<String, dynamic> productoJson;

        if (decoded is List) {
          // [{...}] → toma el primer elemento
          if (decoded.isEmpty) throw Exception('Respuesta lista vacía.');
          productoJson = decoded[0] as Map<String, dynamic>;
        } else if (decoded is Map && decoded.containsKey('data')) {
          // {"data": [{...}]} → extrae data[0]
          final dataList = decoded['data'] as List;
          if (dataList.isEmpty) throw Exception('Campo data vacío.');
          productoJson = dataList[0] as Map<String, dynamic>;
        } else {
          // {...} → objeto directo
          productoJson = decoded as Map<String, dynamic>;
        }

        print(
          '✅ Producto creado: id=${productoJson['id']} '
          '| titulo="${productoJson['titulo']}"',
        );
        return AgroProducto.fromJson(productoJson);
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [AgroApiService] crearProducto: $e');
      rethrow;
    }
  }

  // ── USUARIOS ────────────────────────────────────────────────────────────

  Future<AgroUsuario> crearUsuario(AgroUsuarioCreate usuario) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/agro/usuarios');
      final body = jsonEncode(usuario.toJson());

      print('📤 [AgroApiService] POST $uri | body: $body');

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 60));

      print('📥 [AgroApiService] Usuarios status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        // Supabase REST en FastApi devuelve objeto directo
        return AgroUsuario.fromJson(decoded);
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [AgroApiService] crearUsuario: $e');
      rethrow;
    }
  }
}
