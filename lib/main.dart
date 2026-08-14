import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api/qc_socket.dart';
import 'app.dart';
import 'crypto/key_storage.dart';
import 'state/auth_controller.dart';
import 'state/chat_controller.dart';
import 'state/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = KeyStorage.instance;
  await storage.init();
  final socket = QcSocket();
  final theme = ThemeController(storage);
  await theme.load();
  final auth = AuthController(storage: storage, socket: socket);
  await auth.bootstrap();
  final chat = ChatController(auth: auth, storage: storage, socket: socket);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: theme),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: chat),
      ],
      child: const QuantumChatApp(),
    ),
  );
}
