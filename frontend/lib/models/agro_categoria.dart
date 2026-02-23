/// Modelo de dominio para una categoría agrícola.
/// Coincide con la respuesta del endpoint GET /api/agro/categorias.
class AgroCategoria {
  final int idCategoria;
  final String nombre;
  final String? urlIcono;

  const AgroCategoria({
    required this.idCategoria,
    required this.nombre,
    this.urlIcono,
  });

  /// Deserializa un mapa JSON proveniente del backend.
  factory AgroCategoria.fromJson(Map<String, dynamic> json) {
    return AgroCategoria(
      idCategoria: json['id_categoria'] as int,
      nombre: json['nombre'] as String,
      urlIcono: json['url_icono'] as String?,
    );
  }
}
