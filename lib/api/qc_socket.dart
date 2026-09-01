import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

typedef SocketEventHandler = void Function(dynamic data);

class QcSocket {
  io.Socket? _socket;
  final Map<String, List<SocketEventHandler>> _handlers = {};
  final List<void Function()> _connectListeners = [];

  io.Socket? get socket => _socket;
  bool get connected => _socket?.connected == true;

  /// Fires after every successful connect/reconnect (not after [disconnect]).
  void addConnectListener(void Function() listener) {
    if (!_connectListeners.contains(listener)) {
      _connectListeners.add(listener);
    }
  }

  void removeConnectListener(void Function() listener) {
    _connectListeners.remove(listener);
  }

  void connect({required String url, required String token}) {
    disconnect();
    if (url.isEmpty) {
      debugPrint('[QcSocket] skipped connect: empty signal URL');
      return;
    }
    debugPrint('[QcSocket] connecting to $url');
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
    _socket!.onConnect((_) {
      debugPrint('[QcSocket] connected');
      for (final listener in List<void Function()>.from(_connectListeners)) {
        listener();
      }
    });
    _socket!.onDisconnect((_) => debugPrint('[QcSocket] disconnected'));
    _socket!.onConnectError((err) => debugPrint('[QcSocket] connect error: $err'));
    _socket!.onError((err) => debugPrint('[QcSocket] error: $err'));
    for (final entry in _handlers.entries) {
      for (final handler in entry.value) {
        _socket!.on(entry.key, handler);
      }
    }
    _socket!.connect();
  }

  void on(String event, SocketEventHandler handler) {
    final list = _handlers.putIfAbsent(event, () => []);
    if (!list.contains(handler)) {
      list.add(handler);
    }
    _socket?.on(event, handler);
  }

  void off(String event, [SocketEventHandler? handler]) {
    if (handler != null) {
      _handlers[event]?.remove(handler);
      _socket?.off(event, handler);
      return;
    }
    _handlers.remove(event);
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
