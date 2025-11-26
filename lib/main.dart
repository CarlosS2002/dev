import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'auth_screen.dart';
import 'register_screen.dart';
import 'theme_provider.dart';
import 'agenda_provider.dart';

/// Handler para mensajes en background (debe ser top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Mensaje en background: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print('✅ Firebase inicializado correctamente');
    
    // Configurar handler de mensajes en background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
  } catch (e) {
    print('⚠️ Error al inicializar Firebase: $e');
    print('⚠️ La app funcionará sin Firebase Authentication');
  }
  
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
