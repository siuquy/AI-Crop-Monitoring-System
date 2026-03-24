import 'package:flutter/material.dart';
import 'package:acmms/screens/features/auth/welcome_screen.dart';

import 'core/service/notifiactionservice.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}
