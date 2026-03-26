import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class ChatRepository {
  final ApiClient _api = ApiClient();

  Future<int?> initPrivateChat(int targetUserId) async {
    final res = await _api.postJson(ApiEndpoints.chatPrivado, data: {'targetUserId': targetUserId});
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body)['id_sala'] as int?;
    }
    return null;
  }

  Future<List<dynamic>> getMyChats() async {
    final res = await _api.getJson(ApiEndpoints.misChats);
    if (res.statusCode == 200) return List<dynamic>.from(jsonDecode(res.body));
    return [];
  }

  Future<List<dynamic>> getMessages(int idSala) async {
    final res = await _api.getJson(ApiEndpoints.chatMensajes(idSala));
    if (res.statusCode == 200) return List<dynamic>.from(jsonDecode(res.body));
    return [];
  }

  Future<bool> sendMessage(int idSala, String mensaje) async {
    final res = await _api.postJson(ApiEndpoints.chatMensaje, data: {'id_sala': idSala, 'mensaje': mensaje});
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<List<dynamic>> getFamilyMessages(int idFamilia) async {
    final res = await _api.getJson(ApiEndpoints.mensajesByFamilia(idFamilia));
    if (res.statusCode == 200) return List<dynamic>.from(jsonDecode(res.body));
    return [];
  }

  Future<bool> sendFamilyMessage(int idFamilia, String mensaje) async {
    final res = await _api.postJson(ApiEndpoints.mensajes, data: {'id_familia': idFamilia, 'mensaje': mensaje});
    return res.statusCode == 201 || res.statusCode == 200;
  }
}
