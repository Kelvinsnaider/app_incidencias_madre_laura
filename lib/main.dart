import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'presentation/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MadreLauraApp(),
    ),
  );
}

class MadreLauraApp extends StatelessWidget {
  const MadreLauraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Incidencias U.E. Madre Laura',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
    );
  }
}