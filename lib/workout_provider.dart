import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';
import 'package:flutter/foundation.dart'; 

// --- DATA MODELS ---
class Workout {
  final String id;
  final String title;
  final int calories;
  final DateTime date;
  Workout({required this.id, required this.title, required this.calories, required this.date});
  factory Workout.fromMap(Map<String, dynamic> data, String documentId) {
    return Workout(id: documentId, title: data['title'] ?? '', calories: data['calories'] ?? 0, date: (data['date'] as Timestamp).toDate());
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
    return FoodLog(id: documentId, name: data['name'] ?? '', calories: data['calories'] ?? 0, protein: data['protein'] ?? 0, carbs: data['carbs'] ?? 0, fat: data['fat'] ?? 0, date: (data['date'] as Timestamp).toDate());
  }
}

class StepLog {
  final String id;
  final int steps;
  final DateTime date;
  StepLog({required this.id, required this.steps, required this.date});
  factory StepLog.fromMap(Map<String, dynamic> data, String documentId) {
    return StepLog(id: documentId, steps: data['steps'] ?? 0, date: (data['date'] as Timestamp).toDate());
  }
}

// --- STATE MANAGEMENT ---
class WorkoutProvider extends ChangeNotifier {
  List<Workout> _workouts = [];
  List<FoodLog> _foodLogs = []; 
  List<StepLog> _stepHistory = []; 
  
  StreamSubscription? _workoutSubscription;
  StreamSubscription? _foodSubscription;
  StreamSubscription? _userProfileSubscription;
  StreamSubscription? _stepHistorySubscription; 
  
  StreamSubscription<StepCount>? _stepCountStream;
  int _lastKnownDeviceSteps = 0; 

  // --- Midnight Reset Timer ---
  Timer? _midnightTimer;

  double _height = 0.0; 
  double _weight = 0.0; 
  DateTime? _birthday; 
  String _gender = 'Male';
  int _calorieGoal = 500; 
  int _intakeGoal = 2000; 
  double _targetWeight = 0.0;
  String _goalType = 'Maintain Weight';
  
  int _dailySteps = 0;
  int _stepGoal = 10000;
  DateTime? _lastStepDate; 

  int _dailyWorkoutDuration = 0; 
  int _workoutDurationGoal = 30; 

  bool _isInitialized = false;
  bool _isDarkMode = false;

  // --- UPDATED GETTERS FOR HISTORY LOGIC ---
  List<Workout> get workouts => _workouts; // All workouts
  List<FoodLog> get foodLogs => _foodLogs; // All food
  List<StepLog> get stepHistory => _stepHistory; 
  
  // Gets only today's workouts (Resets at midnight)
  List<Workout> get todaysWorkouts {
    final today = DateTime.now();
    return _workouts.where((w) => w.date.year == today.year && w.date.month == today.month && w.date.day == today.day).toList();
  }
  
  // Gets everything EXCEPT today's workouts (History)
  List<Workout> get pastWorkouts {
    final today = DateTime.now();
    return _workouts.where((w) => w.date.year != today.year || w.date.month != today.month || w.date.day != today.day).toList();
  }

  // Gets only today's food (Resets at midnight)
  List<FoodLog> get todaysFood {
    final today = DateTime.now();
    return _foodLogs.where((f) => f.date.year == today.year && f.date.month == today.month && f.date.day == today.day).toList();
  }

  // Gets everything EXCEPT today's food (History)
  List<FoodLog> get pastFoodLogs {
    final today = DateTime.now();
    return _foodLogs.where((f) => f.date.year != today.year || f.date.month != today.month || f.date.day != today.day).toList();
  }

  // --- STANDARD GETTERS ---
  double get height => _height;
  double get weight => _weight;
  DateTime? get birthday => _birthday;
  String get gender => _gender;
  int get calorieGoal => _calorieGoal;
  int get intakeGoal => _intakeGoal;
  double get targetWeight => _targetWeight;
  String get goalType => _goalType;
  bool get isDarkMode => _isDarkMode;
  int get dailySteps => _dailySteps;
  int get stepGoal => _stepGoal;
  int get dailyWorkoutDuration => _dailyWorkoutDuration;
  int get workoutDurationGoal => _workoutDurationGoal;
  bool get isInitialized => _isInitialized;

  void toggleTheme(bool value) {
    _isDarkMode = value;
    notifyListeners();
    
    // --- NEW: Save theme preference to Firebase ---
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isDarkMode': value,
      }, SetOptions(merge: true));
    }
  }

  int get age {
    if (_birthday == null) return 0;
    final today = DateTime.now();
    int calculatedAge = today.year - _birthday!.year;
    if (today.month < _birthday!.month || (today.month == _birthday!.month && today.day < _birthday!.day)) calculatedAge--;
    return calculatedAge;
  }
  int get totalCaloriesBurned => _workouts.fold(0, (sum, item) => sum + item.calories);
  int get dailyCaloriesBurned {
    final today = DateTime.now();
    return _workouts.where((w) => w.date.year == today.year && w.date.month == today.month && w.date.day == today.day).fold(0, (sum, item) => sum + item.calories);
  }
  int get streak {
    if (_workouts.isEmpty) return 0;
    List<DateTime> dates = _workouts.map((w) => DateTime(w.date.year, w.date.month, w.date.day)).toSet().toList();
    dates.sort((a, b) => b.compareTo(a)); 
    int currentStreak = 0;
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    if (!dates.contains(today) && !dates.contains(yesterday)) return 0;
    DateTime checkDate = dates.contains(today) ? today : yesterday;
    for (DateTime d in dates) {
      if (d == checkDate) { currentStreak++; checkDate = checkDate.subtract(const Duration(days: 1)); } else if (d.isBefore(checkDate)) break; 
    }
    return currentStreak;
  }
  
  int get dailyCaloriesEaten => todaysFood.fold(0, (sum, item) => sum + item.calories);
  int get dailyProtein => todaysFood.fold(0, (sum, item) => sum + item.protein);
  int get dailyCarbs => todaysFood.fold(0, (sum, item) => sum + item.carbs);
  int get dailyFat => todaysFood.fold(0, (sum, item) => sum + item.fat);
  
  double get bmi {
    if (_height == 0 || _weight == 0) return 0.0;
    return _weight / ((_height / 100) * (_height / 100));
  }
String get bmiCategory {
    double currentBmi = bmi;
    if (currentBmi == 0.0) return 'No Data';
    if (currentBmi < 18.5) return 'Underweight';
    if (currentBmi < 25.0) return 'Healthy'; 
    if (currentBmi < 30.0) return 'Overweight'; 
    return 'Obesity'; 
  }

// --- NEW: Calculate the target healthy weight range ---
  String get healthyWeightRange {
    if (_height == 0) return "N/A";
    double heightInMeters = _height / 100;
    double minWeight = 18.5 * (heightInMeters * heightInMeters);
    double maxWeight = 24.9 * (heightInMeters * heightInMeters);
    return "${minWeight.toStringAsFixed(1)} - ${maxWeight.toStringAsFixed(1)} kg";
  }

  // --- NEW: Dynamic Recommendation Text ---
  String get bmiRecommendation {
    double currentBmi = bmi;
    if (currentBmi == 0.0) return "Please update your height and weight to get a personalized recommendation.";
    
    if (currentBmi < 18.5) {
      return "You are currently underweight. To reach a healthy BMI (18.5 - 24.9), your target weight should be between $healthyWeightRange. Focus on a nutrient-rich caloric surplus and strength training.";
    } else if (currentBmi < 25.0) {
      return "Great job! You are at a healthy weight. To maintain your current healthy BMI, keep your weight between $healthyWeightRange with regular exercise and a balanced diet.";
    } else if (currentBmi < 30.0) {
      return "You are currently overweight. To reach a healthy BMI (18.5 - 24.9), aim for a target weight between $healthyWeightRange. Focus on a slight caloric deficit and consistent cardio.";
    } else {
      return "You are in the obesity category. To reach a healthy BMI (18.5 - 24.9), aim for a target weight between $healthyWeightRange. Consider consulting a healthcare provider to create a safe, sustainable weight loss plan.";
    }
  }

  int get maintenanceCalories {
    if (_height == 0 || _weight == 0 || age == 0) return 0; 
    double bmr = _gender == 'Male' ? (10 * _weight) + (6.25 * _height) - (5 * age) + 5 : (10 * _weight) + (6.25 * _height) - (5 * age) - 161;
    return (bmr * 1.375).round(); 
  }

  List<Map<String, dynamic>> get weeklyActivity {
    final List<Map<String, dynamic>> activity = [];
    final today = DateTime.now();
    for (int i = 6; i >= 0; i--) { 
      final targetDate = today.subtract(Duration(days: i));
      int dailyCalories = _workouts.where((w) => w.date.year == targetDate.year && w.date.month == targetDate.month && w.date.day == targetDate.day)
                                   .fold(0, (sum, item) => sum + item.calories);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      activity.add({'day': days[targetDate.weekday - 1], 'calories': dailyCalories});
    }
    return activity;
  }
  List<Map<String, dynamic>> get monthlyActivity {
    final List<Map<String, dynamic>> activity = [];
    final today = DateTime.now();
    for (int i = 3; i >= 0; i--) { 
      final weekEnd = today.subtract(Duration(days: i * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      int weeklyCalories = _workouts.where((w) {
        DateTime wDate = DateTime(w.date.year, w.date.month, w.date.day);
        DateTime sDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        DateTime eDate = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
        return wDate.compareTo(sDate) >= 0 && wDate.compareTo(eDate) <= 0;
      }).fold(0, (sum, item) => sum + item.calories);
      activity.add({'day': 'Wk ${4 - i}', 'calories': weeklyCalories});
    }
    return activity;
  }
  List<Map<String, dynamic>> get weeklyNutrition {
    final List<Map<String, dynamic>> nutrition = [];
    final today = DateTime.now();
    for (int i = 6; i >= 0; i--) { 
      final targetDate = today.subtract(Duration(days: i));
      int dailyCalories = _foodLogs.where((f) => f.date.year == targetDate.year && f.date.month == targetDate.month && f.date.day == targetDate.day)
                                   .fold(0, (sum, item) => sum + item.calories);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      nutrition.add({'day': days[targetDate.weekday - 1], 'calories': dailyCalories});
    }
    return nutrition;
  }
  List<Map<String, dynamic>> get monthlyNutrition {
    final List<Map<String, dynamic>> nutrition = [];
    final today = DateTime.now();
    for (int i = 3; i >= 0; i--) { 
      final weekEnd = today.subtract(Duration(days: i * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      int weeklyCalories = _foodLogs.where((f) {
        DateTime fDate = DateTime(f.date.year, f.date.month, f.date.day);
        DateTime sDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        DateTime eDate = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
        return fDate.compareTo(sDate) >= 0 && fDate.compareTo(eDate) <= 0;
      }).fold(0, (sum, item) => sum + item.calories);
      nutrition.add({'day': 'Wk ${4 - i}', 'calories': weeklyCalories});
    }
    return nutrition;
  }

  Future<void> requestActivityPermission() async {
    if (kIsWeb) return; 
    var status = await Permission.activityRecognition.status;
    if (status.isDenied) status = await Permission.activityRecognition.request();
    if (status.isPermanentlyDenied) openAppSettings();
  }

  Future<void> _archiveYesterdaySteps(String uid, int steps, DateTime date) async {
    if (steps > 0) {
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('stepHistory').add({
        'steps': steps,
        'date': Timestamp.fromDate(date),
      });
    }
  }

  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();
    
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = nextMidnight.difference(now);

    _midnightTimer = Timer(timeUntilMidnight, () async {
      final user = FirebaseAuth.instance.currentUser;
      final now = DateTime.now();

      if (user != null && _lastStepDate != null) {
        await _archiveYesterdaySteps(user.uid, _dailySteps, _lastStepDate!);

        _dailySteps = 0;
        _lastStepDate = now;
        notifyListeners(); 

        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'dailySteps': 0,
          'lastStepDate': Timestamp.fromDate(now),
        }, SetOptions(merge: true));
      }

      _scheduleMidnightReset();
    });
  }

  void _initPedometer() {
    if (kIsWeb) return; 
    
    _stepCountStream?.cancel();
    _stepCountStream = Pedometer.stepCountStream.listen(
      (StepCount event) async {
        int deviceTotalSteps = event.steps;
        if (_lastKnownDeviceSteps == 0) { _lastKnownDeviceSteps = deviceTotalSteps; return; }

        int stepsTaken = deviceTotalSteps - _lastKnownDeviceSteps;

        if (stepsTaken > 0) {
          final now = DateTime.now();
          final user = FirebaseAuth.instance.currentUser;
          
          if (_lastStepDate == null || _lastStepDate!.year != now.year || _lastStepDate!.month != now.month || _lastStepDate!.day != now.day) {
            
            if (user != null && _lastStepDate != null) {
              await _archiveYesterdaySteps(user.uid, _dailySteps, _lastStepDate!);
            }

            _dailySteps = 0;
            _lastStepDate = now;
          }

          _dailySteps += stepsTaken;
          _lastKnownDeviceSteps = deviceTotalSteps;
          notifyListeners(); 
          
          if (user != null) {
            FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'dailySteps': _dailySteps,
              'lastStepDate': Timestamp.fromDate(_lastStepDate ?? now),
            }, SetOptions(merge: true));
          }
        }
      },
      onError: (error) => debugPrint("Pedometer Error: $error")
    );
  }

  void initializeListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!kIsWeb) {
      await requestActivityPermission();
      _initPedometer();
    }

    _scheduleMidnightReset();

    _workoutSubscription?.cancel(); 
    _workoutSubscription = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('workouts').orderBy('date', descending: true).snapshots().listen((snapshot) {
      _workouts = snapshot.docs.map((doc) => Workout.fromMap(doc.data(), doc.id)).toList();
      notifyListeners(); 
    });

    _foodSubscription?.cancel();
    _foodSubscription = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('food').orderBy('date', descending: true).snapshots().listen((snapshot) {
      _foodLogs = snapshot.docs.map((doc) => FoodLog.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    });

    _stepHistorySubscription?.cancel();
    _stepHistorySubscription = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('stepHistory').orderBy('date', descending: true).snapshots().listen((snapshot) {
      _stepHistory = snapshot.docs.map((doc) => StepLog.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    });

    _userProfileSubscription?.cancel();
_userProfileSubscription = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) async {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _height = (data['height'] ?? 0.0).toDouble();
        _weight = (data['weight'] ?? 0.0).toDouble();
        _birthday = data['birthday'] != null ? (data['birthday'] as Timestamp).toDate() : null; 
        _gender = data['gender'] ?? 'Male';
        _calorieGoal = (data['calorieGoal'] ?? 500).toInt();
        _intakeGoal = (data['intakeGoal'] ?? 2000).toInt(); 
        _targetWeight = (data['targetWeight'] ?? 0.0).toDouble();
        _goalType = data['goalType'] ?? 'Maintain Weight';
        _stepGoal = (data['stepGoal'] ?? 10000).toInt();
        
        // --- NEW: Load saved theme from Firebase ---
        _isDarkMode = data['isDarkMode'] ?? false;
        
        _dailySteps = (data['dailySteps'] ?? 0).toInt();
        _lastStepDate = data['lastStepDate'] != null ? (data['lastStepDate'] as Timestamp).toDate() : null;

        final now = DateTime.now();
        if (_lastStepDate != null && (_lastStepDate!.year != now.year || _lastStepDate!.month != now.month || _lastStepDate!.day != now.day)) {
          
          await _archiveYesterdaySteps(user.uid, _dailySteps, _lastStepDate!);

          _dailySteps = 0; 
          _lastStepDate = now; 
          
          FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'dailySteps': 0,
            'lastStepDate': Timestamp.fromDate(now),
          }, SetOptions(merge: true));
        } else {
          _lastStepDate ??= now;
        }

        _workoutDurationGoal = (data['workoutDurationGoal'] ?? 30).toInt();
        _dailyWorkoutDuration = (data['dailyWorkoutDuration'] ?? 0).toInt();

        _isInitialized = true; 
        notifyListeners(); 
      }
    });
  }

  Future<void> addWorkout(String title, int calories) async { final user = FirebaseAuth.instance.currentUser; if (user != null) { await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('workouts').add({'title': title, 'calories': calories, 'date': Timestamp.now()}); } }
  Future<void> deleteWorkout(String workoutId) async { final user = FirebaseAuth.instance.currentUser; if (user != null) { await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('workouts').doc(workoutId).delete(); } }
  Future<void> addFood(String name, int calories, int protein, int carbs, int fat) async { final user = FirebaseAuth.instance.currentUser; if (user != null) { await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('food').add({'name': name, 'calories': calories, 'protein': protein, 'carbs': carbs, 'fat': fat, 'date': Timestamp.now()}); } }
  Future<void> deleteFood(String foodId) async { final user = FirebaseAuth.instance.currentUser; if (user != null) { await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('food').doc(foodId).delete(); } }
  Future<void> updateProfileSettings(String fullName, DateTime? birthday, String gender) async { final user = FirebaseAuth.instance.currentUser; if (user == null) return; await user.updateDisplayName(fullName); await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'birthday': birthday != null ? Timestamp.fromDate(birthday) : null, 'gender': gender}, SetOptions(merge: true)); }
  Future<void> updateFitnessGoals(double height, double weight, int calorieGoal, int intakeGoal, double targetWeight, String goalType, int stepGoal) async { final user = FirebaseAuth.instance.currentUser; if (user == null) return; await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'height': height, 'weight': weight, 'calorieGoal': calorieGoal, 'intakeGoal': intakeGoal, 'targetWeight': targetWeight, 'goalType': goalType, 'stepGoal': stepGoal}, SetOptions(merge: true)); }
  Future<void> updateSpecificMetric({double? height, double? weight}) async { final user = FirebaseAuth.instance.currentUser; if (user == null) return; Map<String, dynamic> data = {}; if (height != null) data['height'] = height; if (weight != null) data['weight'] = weight; await FirebaseFirestore.instance.collection('users').doc(user.uid).set(data, SetOptions(merge: true)); }
  Future<void> updateGoalField(String field, dynamic value) async { final user = FirebaseAuth.instance.currentUser; if (user == null) return; await FirebaseFirestore.instance.collection('users').doc(user.uid).set({field: value}, SetOptions(merge: true)); }

  void clearWorkouts() {
    _workoutSubscription?.cancel();
    _foodSubscription?.cancel();
    _userProfileSubscription?.cancel();
    _stepCountStream?.cancel(); 
    _stepHistorySubscription?.cancel(); 
    _midnightTimer?.cancel(); 
    
    _workouts = [];
    _foodLogs = [];
    _stepHistory = [];
    _height = 0.0; _weight = 0.0; _birthday = null; _gender = 'Male'; _calorieGoal = 500; _intakeGoal = 2000;
    _targetWeight = 0.0; _goalType = 'Maintain Weight';
    
    _dailySteps = 0;
    _stepGoal = 10000;
    _lastStepDate = null; 
    _lastKnownDeviceSteps = 0;
    
    _dailyWorkoutDuration = 0;
    _workoutDurationGoal = 30;
    _isInitialized = false;

    notifyListeners();
  }
}