import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'workout_provider.dart';
import 'login_signup/login_screen.dart';
import 'screens/dashboard_screen.dart';

// ==========================================
// MAIN ENTRY POINT
// ==========================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDKnJq13a5SwMP_sE7Is6MDXi8o5evBreY",
      appId: "1:942734347525:web:8cdbc99bffad4459c47b6c",
      messagingSenderId: "942734347525",
      projectId: "fitness-tracker-6f98d",
      authDomain: "fitness-tracker-6f98d.firebaseapp.com",
      storageBucket: "fitness-tracker-6f98d.firebasestorage.app",
      measurementId: "G-D7S0XJHFH5",
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => WorkoutProvider(),
      child: const FitnessApp(),
    ),
  );
}

// ==========================================
// ROOT APP WIDGET
// ==========================================

class FitnessApp extends StatefulWidget {
  const FitnessApp({super.key});

  @override
  State<FitnessApp> createState() => _FitnessAppState();
}

class _FitnessAppState extends State<FitnessApp> {
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'Fitness Tracker',
          debugShowCheckedModeBanner: false,
          
          themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          
          home: StreamBuilder<User?>(
            stream: _authStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: Colors.teal)),
                );
              }

              if (snapshot.hasData && snapshot.data!.emailVerified) {
                _initializeUserData(provider);
                return const MainNavigator();
              }

              return const LoginScreen();
            },
          ),
        );
      },
    );
  }

  void _initializeUserData(WorkoutProvider provider) {
    if (!provider.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.initializeListener();
      });
    }
  }

  // ==========================================
  // THEME DEFINITIONS
  // ==========================================

  ThemeData _buildLightTheme() {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.light,
        surface: const Color(0xFFF8FAFA),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFA),
      cardColor: Colors.white,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.teal, width: 2.0),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.tealAccent,
        brightness: Brightness.dark,
        surface: const Color(0xFF0F1111),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F1111),
      cardColor: const Color(0xFF1A1D1D),
      dividerColor: Colors.white10,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF232626),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.tealAccent, width: 2.0),
        ),
      ),
    );
  }
}