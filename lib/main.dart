import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'auth_screen.dart';
import 'register_screen.dart';
import 'theme_provider.dart';
import 'agenda_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AgendaProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Mi Aplicación',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'ES'),
            Locale('en', 'US'),
          ],
          initialRoute: '/',
          routes: {
            '/': (context) => AuthScreen(),
            '/register': (context) => RegisterScreen(),
          },
        );
      },
    );
  }
}
