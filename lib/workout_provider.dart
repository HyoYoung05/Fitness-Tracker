import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health/health.dart'; 
import 'package:pedometer/pedometer.dart'; // Brought back Pedometer

// ==========================================
// DATA MODELS
// ==========================================

class Workout {
  final String id;
  final String title;
  final int calories;
  final DateTime date;

  Workout({required this.id, required this.title, required this.calories, required this.date});

  factory Workout.fromMap(Map<String, dynamic> data, String documentId) {
    return Workout(
      id: documentId,
      title: data['title'] ?? '',
      calories: data['calories'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}

class FoodLog {
  final String id;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final DateTime date;

  FoodLog({required this.id, required this.name, required this.calories, required this.protein, required this.carbs, required this.fat, required this.date});

  factory FoodLog.fromMap(Map<String, dynamic> data, String documentId) {
    return FoodLog(
      id: documentId,
      name: data['name'] ?? '',
      calories: data['calories'] ?? 0,
      protein: data['protein'] ?? 0,
      carbs: data['carbs'] ?? 0,
      fat: data['fat'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}

class StepLog {
  final String id;
  final int steps;
  final DateTime date;

  StepLog({required this.id, required this.steps, required this.date});

  factory StepLog.fromMap(Map<String, dynamic> data, String documentId) {
    return StepLog(
      id: documentId,
      steps: data['steps'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}

// ==========================================
// STATE MANAGEMENT PROVIDER
// ==========================================

class WorkoutProvider extends ChangeNotifier {
  // --- Private State ---
  List<Workout> _workouts = [];
  List<FoodLog> _foodLogs = [];
  List<StepLog> _stepHistory = [];

  StreamSubscription? _workoutSubscription;
  StreamSubscription? _foodSubscription;
  StreamSubscription? _userProfileSubscription;
  StreamSubscription? _stepHistorySubscription;
  
  // Hybrid Step Tracking Subscriptions
  final Health _health = Health();
  StreamSubscription<StepCount>? _pedometerSubscription;

  double _height = 0.0;
  double _weight = 0.0;
  DateTime? _birthday;
  String _gender = 'Male';
  int _calorieGoal = 500;
  int _intakeGoal = 2000;
  double _targetWeight = 0.0;
  String _goalType = 'Maintain Weight';
  String _email = '';

  int _dailySteps = 0;
  int _stepGoal = 10000;
  DateTime? _lastStepDate;
  int _savedDeviceTotalSteps = 0; // Needed to calculate live pedometer deltas

  bool _isInitialized = false;
  bool _isDarkMode = false;

  // --- Getters ---
  List<Workout> get workouts => _workouts;
  List<FoodLog> get foodLogs => _foodLogs;
  List<StepLog> get stepHistory => _stepHistory;

  List<Workout> get todaysWorkouts {
    final now = DateTime.now();
    return _workouts.where((w) => w.date.year == now.year && w.date.month == now.month && w.date.day == now.day).toList();
  }

  List<FoodLog> get todaysFood {
    final now = DateTime.now();
    return _foodLogs.where((f) => f.date.year == now.year && f.date.month == now.month && f.date.day == now.day).toList();
  }

  List<FoodLog> get pastFoodLogs {
    final now = DateTime.now();
    return _foodLogs.where((f) => f.date.year != now.year || f.date.month != now.month || f.date.day != now.day).toList();
  }

  List<Workout> get pastWorkouts {
    final now = DateTime.now();
    return _workouts.where((w) => w.date.year != now.year || w.date.month != now.month || w.date.day != now.day).toList();
  }

  double get height => _height;
  double get weight => _weight;
  DateTime? get birthday => _birthday;
  String get gender => _gender;
  int get calorieGoal => _calorieGoal;
  int get intakeGoal => _intakeGoal;
  double get targetWeight => _targetWeight;
  String get goalType => _goalType;
  String get email => _email;
  bool get isDarkMode => _isDarkMode;
  int get dailySteps => _dailySteps;
  int get stepGoal => _stepGoal;
  bool get isInitialized => _isInitialized;

  // --- Calculated Metrics ---
  int get age {
    if (_birthday == null) return 0;
    final today = DateTime.now();
    int calculatedAge = today.year - _birthday!.year;
    if (today.month < _birthday!.month || (today.month == _birthday!.month && today.day < _birthday!.day)) calculatedAge--;
    return calculatedAge;
  }

  double get bmi => (_height == 0 || _weight == 0) ? 0.0 : _weight / ((_height / 100) * (_height / 100));

  String get bmiCategory => switch (bmi) {
        0.0 => 'No Data',
        < 18.5 => 'Underweight',
        < 25.0 => 'Healthy',
        < 30.0 => 'Overweight',
        _ => 'Obesity',
      };

  String get bmiRecommendation {
    final currentBmi = bmi;
    if (currentBmi == 0.0) return "Please update your height and weight to get a personalized recommendation.";
    return switch (currentBmi) {
      < 18.5 => "You are currently underweight. Focus on a nutrient-rich caloric surplus and strength training.",
      < 25.0 => "Great job! You are at a healthy weight. Maintain this with regular exercise and a balanced diet.",
      < 30.0 => "You are currently overweight. Focus on a slight caloric deficit and consistent cardio.",
      _ => "You are in the obesity category. Consider consulting a healthcare provider to create a safe plan."
    };
  }

  int get maintenanceCalories {
    if (_height == 0 || _weight == 0 || age == 0) return 0;
    double bmr = _gender == 'Male'
        ? (10 * _weight) + (6.25 * _height) - (5 * age) + 5
        : (10 * _weight) + (6.25 * _height) - (5 * age) - 161;
    return (bmr * 1.375).round();
  }

  int get dailyCaloriesBurned => todaysWorkouts.fold(0, (sum, w) => sum + w.calories);
  int get dailyCaloriesEaten => todaysFood.fold(0, (sum, f) => sum + f.calories);
  int get dailyProtein => todaysFood.fold(0, (sum, f) => sum + f.protein);
  int get dailyCarbs => todaysFood.fold(0, (sum, f) => sum + f.carbs);
  int get dailyFat => todaysFood.fold(0, (sum, f) => sum + f.fat);

  // --- Initialization & Listeners ---
  void initializeListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _workoutSubscription?.cancel();
    _workoutSubscription = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('workouts').orderBy('date', descending: true).snapshots().listen((snap) {
      _workouts = snap.docs.map((doc) => Workout.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    });

    _foodSubscription?.cancel();
    _foodSubscription = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('food').orderBy('date', descending: true).snapshots().listen((snap) {
      _foodLogs = snap.docs.map((doc) => FoodLog.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    });

    _stepHistorySubscription?.cancel();
    _stepHistorySubscription = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('stepHistory').orderBy('date', descending: true).snapshots().listen((snap) {
      _stepHistory = snap.docs.map((doc) => StepLog.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    });

    _userProfileSubscription?.cancel();
    _userProfileSubscription = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _email = (data['email'] ?? user.email ?? '').toString();
        _height = (data['height'] ?? 0.0).toDouble();
        _weight = (data['weight'] ?? 0.0).toDouble();
        _birthday = data['birthday'] != null ? (data['birthday'] as Timestamp).toDate() : null;
        _gender = data['gender'] ?? 'Male';
        _calorieGoal = (data['calorieGoal'] ?? 500).toInt();
        _intakeGoal = (data['intakeGoal'] ?? 2000).toInt();
        _targetWeight = (data['targetWeight'] ?? 0.0).toDouble();
        _goalType = data['goalType'] ?? 'Maintain Weight';
        _stepGoal = (data['stepGoal'] ?? 10000).toInt();
        _isDarkMode = data['isDarkMode'] ?? false;
        
        _dailySteps = (data['dailySteps'] ?? 0).toInt();
        _lastStepDate = data['lastStepDate'] != null ? (data['lastStepDate'] as Timestamp).toDate() : null;
        _savedDeviceTotalSteps = (data['savedDeviceTotalSteps'] ?? 0).toInt();

        bool wasAlreadyInitialized = _isInitialized;
        _isInitialized = true;
        notifyListeners();

        // Start Hybrid Step Tracking
        if (!wasAlreadyInitialized && !kIsWeb) {
          _initStepTracking();
        }
      }
    });
  }

  // ==========================================
  // HYBRID STEP TRACKING (HEALTH + PEDOMETER)
  // ==========================================

  Future<void> _initStepTracking() async {
    // 1. Ask for Activity Recognition Permissions First
    await requestActivityPermission();

    // 2. Fetch bulk background/historical steps via Health Connect
    await _initHealth();

    // 3. Start live stream pedometer for smooth foreground updates
    _initPedometer();
  }

  Future<void> requestActivityPermission() async {
    if (kIsWeb) return;
    var status = await Permission.activityRecognition.status;
    if (status.isDenied) {
      status = await Permission.activityRecognition.request();
    }
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _initHealth() async {
    final types = [HealthDataType.STEPS];
    bool hasPermissions = await _health.hasPermissions(types) ?? false;
    
    if (!hasPermissions) {
      try {
        hasPermissions = await _health.requestAuthorization(types);
      } catch (e) {
        debugPrint("Health Auth Error: $e");
      }
    }

    if (hasPermissions) {
      await _syncTodaySteps();
      await _syncHistoricalSteps();
    }
  }

  Future<void> _syncTodaySteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      int? steps = await _health.getTotalStepsInInterval(midnight, now);
      if (steps != null && steps > _dailySteps) {
        _dailySteps = steps;
        notifyListeners();
        _saveStepsToFirebase();
      }
    } catch (e) {
      debugPrint("Health Sync Steps Error: $e");
    }
  }

  Future<void> _syncHistoricalSteps() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    for (int i = 1; i <= 7; i++) {
      final targetDate = now.subtract(Duration(days: i));
      final start = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final end = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);

      int? steps = await _health.getTotalStepsInInterval(start, end);
      if (steps != null && steps > 0) {
        bool exists = _stepHistory.any((log) => log.date.year == start.year && log.date.month == start.month && log.date.day == start.day);
        if (!exists) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('stepHistory').add({
            'steps': steps,
            'date': Timestamp.fromDate(start)
          });
        }
      }
    }
  }

  void _initPedometer() {
    _pedometerSubscription?.cancel();
    _pedometerSubscription = Pedometer.stepCountStream.listen((StepCount event) async {
      final now = DateTime.now();
      
      // Handle Midnight Reset
      if (_lastStepDate != null && _lastStepDate!.day != now.day) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && _dailySteps > 0) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('stepHistory').add({
            'steps': _dailySteps,
            'date': Timestamp.fromDate(_lastStepDate!)
          });
        }
        _dailySteps = 0;
        _lastStepDate = now;
      }

      // Calculate live steps
      if (_savedDeviceTotalSteps == 0) {
        // App just opened, set the baseline to avoid adding historical steps twice
        _savedDeviceTotalSteps = event.steps;
      } else {
        int newStepsTaken = event.steps - _savedDeviceTotalSteps;
        if (newStepsTaken > 0) {
          _dailySteps += newStepsTaken;
          _savedDeviceTotalSteps = event.steps;
          notifyListeners();
          _saveStepsToFirebase();
        } else if (newStepsTaken < 0) {
          // Device was rebooted, hardware chip reset to 0
          _savedDeviceTotalSteps = event.steps;
        }
      }
    }, onError: (error) {
      debugPrint("Pedometer Stream Error: $error");
    });
  }

  void _saveStepsToFirebase() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'dailySteps': _dailySteps,
        'savedDeviceTotalSteps': _savedDeviceTotalSteps,
        'lastStepDate': Timestamp.fromDate(_lastStepDate ?? DateTime.now()),
      }, SetOptions(merge: true));
    }
  }

  // --- Database Actions ---
  Future<void> addWorkout(String title, int calories) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('workouts').add({'title': title, 'calories': calories, 'date': Timestamp.now()});
  }

  Future<void> deleteWorkout(String workoutId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('workouts').doc(workoutId).delete();
  }

  Future<void> addFood(String name, int calories, int protein, int carbs, int fat) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('food').add({
      'name': name, 'calories': calories, 'protein': protein, 'carbs': carbs, 'fat': fat, 'date': Timestamp.now()
    });
  }

  Future<void> deleteFood(String foodId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('food').doc(foodId).delete();
  }

  // --- Profile Updates ---
  Future<void> updateProfileSettings(String name, DateTime? bday, String gen, String mail) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fullName': name, 'birthday': bday != null ? Timestamp.fromDate(bday) : null, 'gender': gen, 'email': mail,
    }, SetOptions(merge: true));
  }

  Future<void> updateFitnessGoals(double h, double w, int cGoal, int iGoal, double tWeight, String gType, int sGoal) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'height': h, 'weight': w, 'calorieGoal': cGoal, 'intakeGoal': iGoal, 'targetWeight': tWeight, 'goalType': gType, 'stepGoal': sGoal
    }, SetOptions(merge: true));
  }

  Future<void> updateSpecificMetric({double? height, double? weight}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    Map<String, dynamic> data = {};
    if (height != null) data['height'] = height;
    if (weight != null) data['weight'] = weight;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
  }

  Future<void> updateGoalField(String field, dynamic value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({field: value}, SetOptions(merge: true));
  }

  // --- Helper Methods ---
  void clearWorkouts() {
    _workoutSubscription?.cancel();
    _foodSubscription?.cancel();
    _userProfileSubscription?.cancel();
    _stepHistorySubscription?.cancel();
    _pedometerSubscription?.cancel();
    _workouts = [];
    _foodLogs = [];
    _stepHistory = [];
    _isInitialized = false;
    notifyListeners();
  }

  void toggleTheme(bool value) {
    _isDarkMode = value;
    notifyListeners();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({'isDarkMode': value}, SetOptions(merge: true));
    }
  }

  int get bestBurnRecord => _workouts.isEmpty ? 0 : _workouts.map((w) => w.calories).reduce((a, b) => a > b ? a : b);

  double get averageWeeklySteps {
    if (_stepHistory.isEmpty) return _dailySteps.toDouble();
    int total = _dailySteps;
    int count = 1;
    for (var i = 0; i < _stepHistory.length && i < 6; i++) {
      total += _stepHistory[i].steps;
      count++;
    }
    return total / count;
  }

  // --- Chart Getters ---
  List<Map<String, dynamic>> get weeklyActivity => _getChartData(_workouts);
  List<Map<String, dynamic>> get weeklyNutrition => _getChartData(_foodLogs);

  List<Map<String, dynamic>> _getChartData(List dynamicLogs) {
    final List<Map<String, dynamic>> data = [];
    final today = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (int i = 6; i >= 0; i--) {
      final target = today.subtract(Duration(days: i));
      int total = dynamicLogs.where((l) => l.date.year == target.year && l.date.month == target.month && l.date.day == target.day).fold(0, (sum, item) => sum + (item.calories as int));
      data.add({'day': days[target.weekday - 1], 'calories': total});
    }
    return data;
  }

  List<Map<String, dynamic>> get monthlyActivity {
    final List<Map<String, dynamic>> activity = [];
    final today = DateTime.now();
    for (int i = 3; i >= 0; i--) {
      final weekEnd = today.subtract(Duration(days: i * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      int total = _workouts.where((w) {
        return w.date.isAfter(weekStart.subtract(const Duration(days: 1))) && w.date.isBefore(weekEnd.add(const Duration(days: 1)));
      }).fold(0, (sum, item) => sum + item.calories);
      activity.add({'day': 'Wk ${4 - i}', 'calories': total});
    }
    return activity;
  }

  List<Map<String, dynamic>> get monthlyNutrition {
    final List<Map<String, dynamic>> nutrition = [];
    final today = DateTime.now();
    for (int i = 3; i >= 0; i--) {
      final weekEnd = today.subtract(Duration(days: i * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      int total = _foodLogs.where((f) {
        return f.date.isAfter(weekStart.subtract(const Duration(days: 1))) && f.date.isBefore(weekEnd.add(const Duration(days: 1)));
      }).fold(0, (sum, item) => sum + item.calories);
      nutrition.add({'day': 'Wk ${4 - i}', 'calories': total});
    }
    return nutrition;
  }
}