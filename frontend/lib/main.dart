import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'viewmodels/chat_viewmodel.dart';
// ── ViewModels del módulo AgroConnect ─────────────────────────────────────────
import 'viewmodels/agro_home_viewmodel.dart';
import 'viewmodels/agro_subir_viewmodel.dart';
import 'views/login_screen.dart';
// ── Pantalla principal con tabs de AgroConnect ────────────────────────────────
import 'views/agro_main_screen.dart';

// Configuración Web proporcionada por el usuario
const firebaseOptionsWeb = FirebaseOptions(
  apiKey: "AIzaSyBjI9WLITTr5ttMIu_9YfyUCKKlBquNFag",
  authDomain: "u4exa-33c28.firebaseapp.com",
  projectId: "u4exa-33c28",
  storageBucket: "u4exa-33c28.firebasestorage.app",
  messagingSenderId: "17851172844",
  appId: "1:17851172844:web:6b093a9441da8921b6e2c9",
  measurementId: "G-56XKG4J0H0",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización condicional (Web usa options, Android usa google-services.json automático)
  // Nota: Si google-services.json está bien, en Android no hace falta options.
  // Sin embargo, para web es obligatorio.
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey:
            "AIzaSyBjI9WLITTr5ttMIu_9YfyUCKKlBquNFag", // Replicamos web config como fallback/default si null
        authDomain: "u4exa-33c28.firebaseapp.com",
        projectId: "u4exa-33c28",
        storageBucket: "u4exa-33c28.firebasestorage.app",
        messagingSenderId: "17851172844",
        appId: "1:17851172844:web:6b093a9441da8921b6e2c9",
        measurementId: "G-56XKG4J0H0",
      ),
    );
    // En un setup ideal, usaríamos Platform.isAndroid ? null : optionsWeb
    // Pero flutterfire configure genera un firebase_options.dart.
    // Aquí hardcodeamos web como pidió el usuario para Web, y dejamos que Android use el json si el plugin funciona.
    // Ojo: Firebase.initializeApp() sin argumentos usa el json en Android.
    // Si pasamos opciones manuales, sobreescribe.
    // Vamos a intentar una lógica híbrida simple.
  } catch (e) {
    // Si ya estaba inicializada (hot restart) ignoramos
    print("Firebase init error (o ya inicializado): $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        // ── Módulo AgroConnect ─────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => AgroHomeViewModel()),
        ChangeNotifierProvider(create: (_) => AgroSubirViewModel()),
      ],
      child: MaterialApp(
        title: 'Uni4exa',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32), // Verde AgroConnect
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.outfitTextTheme(),
          scaffoldBackgroundColor: const Color(0xFFF4FAF4),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD0BCFF),
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
          scaffoldBackgroundColor: const Color(0xFF141218),
        ),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // AgroMainScreen contiene ChatScreen en su tab 2
          return const AgroMainScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
