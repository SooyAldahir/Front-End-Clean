import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../network/api_client.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  Completer<void>? _connectedCompleter;

  IO.Socket get socket {
    if (_socket == null) throw StateError('Socket no inicializado. Llama initSocket() primero.');
    return _socket!;
  }

  bool get isReady     => _socket != null;
  bool get isConnected => _socket?.connected == true;

  void initSocket() {
    if (_socket != null) return;

    _connectedCompleter = Completer<void>();

    _socket = IO.io(
      ApiClient.baseUrl,
      IO.OptionBuilder()
          .setPath('/socket.io')
          .setTransports(['polling'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999)
          .setReconnectionDelay(500)
          .setReconnectionDelayMax(2000)
          .setTimeout(8000)
          .build(),
    );

    _socket!.onConnect((_) {
      if (_connectedCompleter != null && !_connectedCompleter!.isCompleted) {
        _connectedCompleter!.complete();
      }
    });

    _socket!.onDisconnect((_) {
      _connectedCompleter = Completer<void>();
    });

    _socket!.onConnectError((e) => print('Socket connect_error: $e'));
    _socket!.onError((e) => print('Socket error: $e'));
    _socket!.connect();
  }

  Future<void> ensureConnected({Duration timeout = const Duration(seconds: 10)}) async {
    initSocket();
    if (isConnected) return;
    try {
      await (_connectedCompleter?.future ?? Future.value()).timeout(timeout);
    } catch (_) {}
  }

  Future<void> joinRoom(String roomId) async {
    await ensureConnected();
    if (!isConnected) return;
    _socket!.emit('join_room', roomId);
  }

  Future<void> joinFamilyRoom(int familyId)      => joinRoom('familia_$familyId');
  Future<void> joinChatRoom(int salaId)           => joinRoom('sala_$salaId');
  Future<void> joinInstitucionalRoom()            => joinRoom('institucional');
  Future<void> joinUserRoom(int userId)           => joinRoom('user_$userId');

  void leaveRoom(String roomId) {
    if (!isConnected) return;
    _socket!.emit('leave_room', roomId);
  }

  void on(String event, Function(dynamic) handler) => _socket?.on(event, handler);
  void off(String event) => _socket?.off(event);

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectedCompleter = null;
  }
}
