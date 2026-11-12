import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorku/providers/app_state_provider.dart';
import 'package:tutorku/views/main_shell_view.dart';
import 'package:tutorku/views/theme.dart';

void main() {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: const TutorKuApp(),
    ),
  );
}

class TutorKuApp extends StatelessWidget {
  const TutorKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TutorKu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Forces light theme (white & green) to avoid dark backgrounds
      home: const MainShellView(),
    );
  }
}
