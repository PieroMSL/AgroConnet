class AgroUsuarioCreate {
  final String nombre;
  final String email;
  final String? telefono;
  final String? ubicacion;
  final int idRol;

  const AgroUsuarioCreate({
    required this.nombre,
    required this.email,
    this.telefono,
    this.ubicacion,
    required this.idRol,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'email': email,
      if (telefono != null && telefono!.isNotEmpty) 'telefono': telefono,
      if (ubicacion != null && ubicacion!.isNotEmpty) 'ubicacion': ubicacion,
      'id_rol': idRol,
    };
  }
}

class AgroUsuario {
  final int idUsuario;
  final String nombre;
  final String email;
  final String? telefono;
  final String? ubicacion;
  final int idRol;
  final String? fechaRegistro;

  const AgroUsuario({
    required this.idUsuario,
    required this.nombre,
    required this.email,
    this.telefono,
    this.ubicacion,
    required this.idRol,
    this.fechaRegistro,
  });

  factory AgroUsuario.fromJson(Map<String, dynamic> json) {
    return AgroUsuario(
      idUsuario: json['id_usuario'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      telefono: json['telefono'] as String?,
      ubicacion: json['ubicacion'] as String?,
      idRol: json['id_rol'] as int,
      fechaRegistro: json['fecha_registro'] as String?,
    );
  }
}
