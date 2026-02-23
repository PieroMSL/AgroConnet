import '../services/api_service.dart';
import '../services/ai_service.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final ApiService _apiService;
  final AiService _aiService;

  ChatRepository({ApiService? apiService, AiService? aiService})
    : _apiService = apiService ?? ApiService(),
      _aiService = aiService ?? AiService();

  Future<ChatMessage> sendMessage(String message, String model) async {
    try {
      String responseText;

      // Si el modelo es Gemini, usar el SDK de Firebase Vertex AI
      if (model.contains("gemini")) {
        responseText = await _aiService.sendMessage(message);
      } else {
        // Para otros modelos (GPT-4o, DeepSeek), usar el Backend tradicional
        responseText = await _apiService.sendMessage(message, model);
      }

      return ChatMessage.fromApiResponse(responseText);
    } catch (e) {
      rethrow;
    }
  }
}
