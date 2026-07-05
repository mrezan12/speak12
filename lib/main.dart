import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: Speak12App()));
}

class Speak12App extends StatelessWidget {
  const Speak12App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speak12',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const Scaffold(
        body: Center(
          child: Text('Speak12'),
        ),
      ),
    );
  }
}
