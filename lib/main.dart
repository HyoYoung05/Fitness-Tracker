import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

import 'workout_provider.dart';
import 'login_signup/login_screen.dart';
import 'screens/dashboard_screen.dart'; // Ensure this points to your MainNavigator

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
      create: (context) => WorkoutProvider(), // Initialization handled safely inside the StreamBuilder now
      child: const FitnessApp(),
    ),
  );
}

// --- CONVERTED TO STATEFUL WIDGET TO FIX THE GLITCH ---
class FitnessApp extends StatefulWidget {
  const FitnessApp({super.key});

  @override
  State<FitnessApp> createState() => _FitnessAppState();
}

class _FitnessAppState extends State<FitnessApp> {
  // We declare the stream variable here
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    // We cache the stream once. This prevents the StreamBuilder from resetting 
    // every time WorkoutProvider calls notifyListeners().
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
          
          theme: ThemeData(
            primarySwatch: Colors.teal,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardColor: Colors.white,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.teal, width: 2.0),
              ),
            ),
          ),
          
          darkTheme: ThemeData(
            primarySwatch: Colors.teal,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F1F1F),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardColor: const Color(0xFF1E1E1E),
            dividerColor: Colors.white24,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.tealAccent, width: 2.0),
              ),
            ),
          ),
          
          home: StreamBuilder<User?>(
            stream: _authStream, // Uses the cached stream to ensure stability
            builder: (context, snapshot) {
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.teal)));
              }
              
              if (snapshot.hasData && snapshot.data!.emailVerified) {
                // Safe data fetching trigger
                if (!provider.isInitialized) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<WorkoutProvider>().initializeListener();
                  });
                }
                return const MainNavigator(); 
              }
              
              return const LoginScreen();
            },
          ), 
        );
      },
    );
  }
}