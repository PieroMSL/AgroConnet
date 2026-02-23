import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // IMPORTANTE: Usar la IP de red cuando el backend corre en otro host o
  // cuando flutter corre en un dispositivo físico.
  // Para flutter run -d chrome en la misma máquina: 'http://localhost:8000/api/chat'
  // Para acceso desde dispositivo físico en la misma red: 'http://192.168.18.21:8000/api/chat'
  static const String _baseUrl = 'http://192.168.18.21:8000/api/chat';

  Future<String> sendMessage(String message, String model) async {
    try {
      // Intentar obtener token de Firebase (opcional en modo demo)
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken(true);

      print("📤 [ApiService] Enviando POST a $_baseUrl");
      print("📤 [ApiService] Modelo: $model");
      print(
        "📤 [ApiService] Token Firebase: ${token != null ? 'SÍ (${token.substring(0, 10)}...)' : 'NO (modo demo)'}",
      );

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': message, 'model': model}),
      );

      print("📥 [ApiService] Status code: ${response.statusCode}");
      print("📥 [ApiService] Body raw: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // El backend retorna {"response": "...", "status": "success"}
        if (data['response'] == null) {
          throw Exception(
            'El campo "response" vino vacío en el JSON: ${response.body}',
          );
        }

        print("✅ [ApiService] Respuesta de IA recibida correctamente.");
        return data['response'] as String;
      } else {
        // Imprimir body del error para diagnóstico
        print(
          "❌ [ApiService] Error HTTP ${response.statusCode}: ${response.body}",
        );
        throw Exception(
          'Error del servidor ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      // Log del error REAL antes de relanzar
      print("❌ [ApiService] Error exacto en Flutter: $e");
      rethrow; // Relanzar sin envolver para que el ViewModel lo vea completo
    }
  }
}
