import 'dart:async';
import 'package:flutter/material.dart';
import '../data/chat_repository.dart';
import '../../../core/socket/socket_service.dart';
import '../../../core/storage/session_storage.dart';

// ─── MyChatsViewModel ─────────────────────────────────────────────────────────
class MyChatsViewModel {
  final ChatRepository _repo = ChatRepository();
  final chats   = ValueNotifier<List<dynamic>>([]);
  final loading = ValueNotifier<bool>(true);

  Future<void> load() async {
    loading.value = true;
    try { chats.value = await _repo.getMyChats(); }
    finally { loading.value = false; }
  }

  void dispose() { chats.dispose(); loading.dispose(); }
}

// ─── ChatViewModel (sala privada/grupal) ─────────────────────────────────────
class ChatViewModel {
  final ChatRepository _repo   = ChatRepository();
  final SocketService  _socket = SocketService();
  final SessionStorage _session= SessionStorage();

  final messages = ValueNotifier<List<dynamic>>([]);
  final loading  = ValueNotifier<bool>(true);
  final msgCtrl  = TextEditingController();

  int?  _myId;
  Timer? _pollingTimer;

  Future<void> init(int idSala) async {
    _myId = await _session.getUserId();
    await _loadMessages(idSala);
    _startPolling(idSala);

    await _socket.ensureConnected();
    await _socket.joinChatRoom(idSala);
    _socket.off('nuevo_mensaje');
    _socket.on('nuevo_mensaje', (_) => _loadMessages(idSala));
  }

  void _startPolling(int idSala) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _loadMessages(idSala));
  }

  Future<void> _loadMessages(int idSala) async {
    final msgs = await _repo.getMessages(idSala);
    final normalized = msgs.map((m) {
      if (m is! Map) return m;
      final msg = Map<String, dynamic>.from(m);
      final senderId = msg['id_usuario'] is int ? msg['id_usuario'] : int.tryParse((msg['id_usuario'] ?? '').toString());
      msg['es_mio'] = (_myId != null && senderId == _myId) ? 1 : 0;
      return msg;
    }).toList();

    if (normalized.length != messages.value.length) {
      messages.value = normalized;
    }
    loading.value = false;
  }

  Future<bool> sendMessage(int idSala) async {
    final text = msgCtrl.text.trim();
    if (text.isEmpty) return false;
    msgCtrl.clear();

    // Optimistic update
    final temp = {'id_mensaje': -DateTime.now().millisecondsSinceEpoch, 'mensaje': text, 'es_mio': 1, '_temp': true};
    messages.value = [...messages.value, temp];

    final ok = await _repo.sendMessage(idSala, text);
    if (!ok) {
      messages.value = messages.value.where((m) => m['id_mensaje'] != temp['id_mensaje']).toList();
    } else {
      await _loadMessages(idSala);
    }
    return ok;
  }

  void dispose() {
    _pollingTimer?.cancel();
    messages.dispose();
    loading.dispose();
    msgCtrl.dispose();
  }
}

// ─── ChatFamilyViewModel ──────────────────────────────────────────────────────
class ChatFamilyViewModel {
  final ChatRepository _repo   = ChatRepository();
  final SocketService  _socket = SocketService();
  final SessionStorage _session= SessionStorage();

  final messages  = ValueNotifier<List<dynamic>>([]);
  final loading   = ValueNotifier<bool>(true);
  final msgCtrl   = TextEditingController();

  int _miId = 0;
  Timer? _pollingTimer;

  Future<void> init(int idFamilia) async {
    _miId = await _session.getUserId() ?? 0;
    await _loadMessages(idFamilia);
    _startPolling(idFamilia);

    await _socket.ensureConnected();
    await _socket.joinFamilyRoom(idFamilia);
    _socket.off('nuevo_mensaje_familia');
    _socket.on('nuevo_mensaje_familia', (_) => _loadMessages(idFamilia));
  }

  void _startPolling(int idFamilia) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _loadMessages(idFamilia));
  }

  Future<void> _loadMessages(int idFamilia) async {
    final nuevos = await _repo.getFamilyMessages(idFamilia);
    if (nuevos.length != messages.value.length) {
      messages.value = nuevos;
    }
    loading.value = false;
  }

  Future<bool> sendMessage(int idFamilia) async {
    final text = msgCtrl.text.trim();
    if (text.isEmpty) return false;
    msgCtrl.clear();
    final ok = await _repo.sendFamilyMessage(idFamilia, text);
    if (ok) await _loadMessages(idFamilia);
    return ok;
  }

  int get miId => _miId;

  void dispose() {
    _pollingTimer?.cancel();
    messages.dispose();
    loading.dispose();
    msgCtrl.dispose();
  }
}
