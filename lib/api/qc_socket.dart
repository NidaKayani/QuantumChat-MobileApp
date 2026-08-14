import 'package:socket_io_client/socket_io_client.dart' as io;

class QcSocket {
  io.Socket? _socket;

  io.Socket? get socket => _socket;
  bool get connected => _socket?.connected == true;

  void connect({required String url, required String token}) {
    disconnect();
    if (url.isEmpty) return;
    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(15000)
          .setTimeout(8000)
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
  }

  void on(String event, void Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  void joinGroup(String groupId) => emit('group:join', {'groupId': groupId});
  void leaveGroup(String groupId) => emit('group:leave', {'groupId': groupId});

  void typingStart({String? to, String? groupId}) {
    emit('typing:start', {
      if (to != null) 'to': to,
      if (groupId != null) 'groupId': groupId,
    });
  }

  void typingStop({String? to, String? groupId}) {
    emit('typing:stop', {
      if (to != null) 'to': to,
      if (groupId != null) 'groupId': groupId,
    });
  }

  void markDelivered(String messageId) {
    emit('message:delivered', {'messageId': messageId});
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
