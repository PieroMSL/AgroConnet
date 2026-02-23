import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/agro_producto.dart';
import '../repositories/chat_repository.dart';

/// ViewModel del chat de AgroConnect.
///
/// Responsabilidades:
/// - Gestiona el historial de mensajes.
/// - Inyecta contexto invisible de los productos agro antes de enviar al backend.
/// - La UI solo ve el mensaje original del usuario (no el contexto inyectado).
class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repository;

  ChatViewModel({ChatRepository? repository})
    : _repository = repository ?? ChatRepository();

  // ── Estado público ─────────────────────────────────────────────────────────
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedModel = 'gpt-4o';

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedModel => _selectedModel;

  // ── Contexto de productos (se actualiza desde AgroHomeViewModel) ────────────
  List<AgroProducto> _productosDisponibles = [];

  /// Actualiza la lista de productos disponibles.
  /// Se llama desde la UI (o desde AgroMainScreen) cuando hay nuevos datos.
  void actualizarProductos(List<AgroProducto> productos) {
    _productosDisponibles = productos;
    // No notifyListeners: los productos son contexto interno, no afectan la UI del chat
  }

  // ── Construcción del contexto oculto ──────────────────────────────────────

  /// Convierte la lista de productos en un string legible para la IA.
  /// Ej: "Papas nativas a S/3.50/kg, Miel de abeja a S/12.00/frasco"
  String _generarResumenProductos() {
    if (_productosDisponibles.isEmpty) {
      return 'Sin productos disponibles actualmente.';
    }

    final partes = _productosDisponibles.take(20).map((p) {
      final precio = 'S/. ${p.precio.toStringAsFixed(2)}';
      final unidad = p.unidadMedida != null ? '/${p.unidadMedida}' : '';
      return '${p.titulo} a $precio$unidad';
    });

    return partes.join(', ');
  }

  /// Construye el mensaje enriquecido que se envía al backend.
  /// El usuario nunca verá este texto; solo aparece en el request HTTP.
  String _construirMensajeConContexto(String mensajeOriginal) {
    final resumenProductos = _generarResumenProductos();

    return '''Contexto del sistema (NO mostrar al usuario): Eres el asistente agrícola de AgroConnect, una aplicación de comercio justo y mercado local (alineado con ODS 8 y ODS 2). \
Conectas a productores locales con consumidores. Tienes acceso a los siguientes productos disponibles en el mercado: $resumenProductos. \
Responde siempre en español, de forma amable, breve y como un experto agrícola. Si preguntan por precios o disponibilidad, usa solo los datos anteriores. No inventes productos.

Pregunta del usuario: $mensajeOriginal''';
  }

  // ── Acciones ───────────────────────────────────────────────────────────────

  void setModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }

  /// Envía un mensaje al backend con contexto agro inyectado.
  ///
  /// [text]: el mensaje original que escribió el usuario.
  /// - La UI muestra solo [text].
  /// - El backend recibe el mensaje con el contexto prepend.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Mostrar mensaje original del usuario (optimistic UI)
    _messages.add(
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
    );
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 2. Construir el mensaje enriquecido (invisible para el usuario)
      final mensajeConContexto = _construirMensajeConContexto(text);

      // 3. Enviar el mensaje enriquecido al backend
      final aiMsg = await _repository.sendMessage(
        mensajeConContexto,
        _selectedModel,
      );

      // 4. Mostrar la respuesta de la IA normalmente
      _messages.add(aiMsg);
    } catch (e) {
      _errorMessage =
          'No se pudo conectar con el asistente. Verifica tu conexión.';
      print('❌ [ChatViewModel] Error al enviar mensaje: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
