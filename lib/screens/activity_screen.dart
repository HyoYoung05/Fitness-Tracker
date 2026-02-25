import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../workout_provider.dart';
import 'package:intl/intl.dart'; 

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _showWeekly = true; 

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime.toLocal());
  }

  void _editBurnGoal(BuildContext context, WorkoutProvider provider) {
    final controller = TextEditingController(text: provider.calorieGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Burn Goal'),
        content: TextField(
          controller: controller, 
          keyboardType: TextInputType.number, 
          decoration: const InputDecoration(labelText: 'Target Calories', suffixText: 'kcal')
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.updateGoalField('calorieGoal', int.tryParse(controller.text) ?? provider.calorieGoal);
              Navigator.pop(context);
            }, 
            child: const Text('Save')
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final chartData = _showWeekly ? provider.weeklyActivity : provider.monthlyActivity;
    
    // Use the new getter that resets at midnight
    final todaysWorkouts = provider.todaysWorkouts; 
    
    int maxCalories = 1; 
    for (var data in chartData) {
      if ((data['calories'] as int) > maxCalories) maxCalories = data['calories'] as int;
    }

    double progress = provider.calorieGoal > 0 ? (provider.dailyCaloriesBurned / provider.calorieGoal).clamp(0.0, 1.0) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.teal,
        actions: [
          // --- NEW: History Button, Streak Removed ---
          IconButton(
            icon: const Icon(Icons.history, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutHistoryScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            InkWell(
              onTap: () => _editBurnGoal(context, provider),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Today's Burn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          children: [
                            Text('${provider.dailyCaloriesBurned} / ${provider.calorieGoal} kcal', style: TextStyle(color: Colors.teal.shade500, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 8),
                            const Icon(Icons.edit, size: 12, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: isDark ? Colors.grey.shade800 : Colors.teal.shade50,
                        valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? Colors.orangeAccent : Colors.teal), 
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Activity Chart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('Wk', style: TextStyle(fontSize: 11))),
                            ButtonSegment(value: false, label: Text('Mo', style: TextStyle(fontSize: 11))),
                          ],
                          selected: {_showWeekly},
                          onSelectionChanged: (Set<bool> newSelection) => setState(() => _showWeekly = newSelection.first),
                          style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact, selectedBackgroundColor: Colors.teal, selectedForegroundColor: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 110, 
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: chartData.map((data) {
                          int burnedCal = data['calories'] as int;
                          double fillPercent = maxCalories == 0 ? 0 : burnedCal / maxCalories;
                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(burnedCal > 0 ? '$burnedCal' : '', style: TextStyle(fontSize: 9, color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: FractionallySizedBox(
                                    heightFactor: fillPercent > 0 ? fillPercent.clamp(0.05, 1.0) : 0.05,
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: _showWeekly ? 18 : 24, 
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: burnedCal > 0 ? [Colors.teal.shade300, Colors.teal.shade600] : [isDark ? Colors.grey.shade800 : Colors.teal.shade50, isDark ? Colors.grey.shade800 : Colors.teal.shade50],
                                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(4)
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(data['day'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  ],
                ),
              ),
            ),
            
            // --- NOW ONLY SHOWS TODAY'S LOGS ---
            todaysWorkouts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(child: Text("No workouts logged today.\nCheck History for past logs.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 16))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: todaysWorkouts.length,
                    itemBuilder: (context, index) {
                      final workout = todaysWorkouts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark? 0.3 : 0.03), blurRadius: 8, offset: const Offset(0, 3))]),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.fitness_center, color: Colors.teal)),
                          title: Text(workout.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text(_formatTime(workout.date), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min, 
                            children: [
                              Text('${workout.calories} kcal', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              IconButton(icon: Icon(Icons.delete_outline, color: Colors.grey.shade400), onPressed: () => context.read<WorkoutProvider>().deleteWorkout(workout.id)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal, foregroundColor: Colors.white, elevation: 4,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddWorkoutScreen())),
        icon: const Icon(Icons.add), label: const Text('Workout', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// --- NEW: WORKOUT HISTORY SCREEN ---
class WorkoutHistoryScreen extends StatelessWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final history = provider.pastWorkouts;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0, backgroundColor: Colors.transparent, foregroundColor: Colors.teal,
      ),
      body: history.isEmpty
          ? Center(child: Text('No past workouts found.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final workout = history[index];
                String dateStr = DateFormat('EEE, MMM d • h:mm a').format(workout.date.toLocal());
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark? 0.3 : 0.03), blurRadius: 8, offset: const Offset(0, 3))]),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.history, color: Colors.teal)),
                    title: Text(workout.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(dateStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    trailing: Text('${workout.calories} kcal', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                );
              },
            ),
    );
  }
}

// ... AddWorkoutScreen ...
class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({super.key});
  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}
class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final _titleController = TextEditingController();
  final _caloriesController = TextEditingController();
  void _submitData() {
    final enteredTitle = _titleController.text;
    final enteredCalories = int.tryParse(_caloriesController.text) ?? 0;
    if (enteredTitle.isEmpty || enteredCalories <= 0) return;
    context.read<WorkoutProvider>().addWorkout(enteredTitle, enteredCalories);
    Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Workout')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Workout Title (e.g., Running)', prefixIcon: Icon(Icons.directions_run))),
            const SizedBox(height: 20),
            TextField(controller: _caloriesController, decoration: const InputDecoration(labelText: 'Calories Burned', prefixIcon: Icon(Icons.local_fire_department)), keyboardType: TextInputType.number),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _submitData, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Save Workout', style: TextStyle(fontSize: 18, color: Colors.white))))
          ],
        ),
      ),
    );
  }
}