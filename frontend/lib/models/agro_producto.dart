/// Modelo de dominio para un producto agrícola.
/// Coincide con la respuesta del endpoint GET/POST /api/agro/productos.
class AgroProducto {
  final int id;
  final String titulo;
  final String? descripcion;
  final double precio;
  final int? stock;
  final String? unidadMedida;
  final String? urlImagen;
  final int idCategoria;
  final int idVendedor;
  final bool disponible;

  const AgroProducto({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.precio,
    this.stock,
    this.unidadMedida,
    this.urlImagen,
    required this.idCategoria,
    required this.idVendedor,
    this.disponible = true,
  });

  /// Deserializa un mapa JSON proveniente del backend.
  factory AgroProducto.fromJson(Map<String, dynamic> json) {
    return AgroProducto(
      id: json['id_producto'] as int,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      // El backend puede devolver precio como int o double
      precio: (json['precio'] as num).toDouble(),
      stock: json['stock'] as int?,
      unidadMedida: json['unidad_medida'] as String?,
      urlImagen: json['url_imagen'] as String?,
      idCategoria: json['id_categoria'] as int,
      idVendedor: json['id_vendedor'] as int,
      disponible: json['disponible'] as bool? ?? true,
    );
  }
}

/// DTO para crear un nuevo producto (body del POST /api/agro/productos).
class AgroProductoCreate {
  final String titulo;
  final String? descripcion;
  final double precio;
  final int? stock;
  final String? unidadMedida;
  final String? urlImagen;
  final int idCategoria;
  final int idVendedor;

  const AgroProductoCreate({
    required this.titulo,
    this.descripcion,
    required this.precio,
    this.stock,
    this.unidadMedida,
    this.urlImagen,
    required this.idCategoria,
    required this.idVendedor,
  });

  /// Serializa a JSON para el body de la petición POST.
  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      if (descripcion != null) 'descripcion': descripcion,
      'precio': precio,
      if (stock != null) 'stock': stock,
      if (unidadMedida != null) 'unidad_medida': unidadMedida,
      if (urlImagen != null) 'url_imagen': urlImagen,
      'id_categoria': idCategoria,
      'id_vendedor': idVendedor,
    };
  }
}
