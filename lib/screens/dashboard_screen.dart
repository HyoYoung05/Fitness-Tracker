import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../workout_provider.dart';
import 'home_screen.dart';        
import 'activity_screen.dart';
import 'nutrition_screen.dart';
import 'goals_screen.dart';   
import 'profile_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  
  // --- UPDATED: Now includes 5 screens ---
  final List<Widget> _screens = [
    const HomeScreen(),      
    const ActivityScreen(),  
    const ProgressScreen(), 
    const GoalsScreen(),     // New Goals Tab
    const ProfileScreen()    // Settings Tab
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().initializeListener();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed, // Required when you have more than 3 tabs
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Nutrition'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Goals'), // --- NEW TAB ---
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}