import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../workout_provider.dart';
import 'package:intl/intl.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _showWeekly = true; 

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime.toLocal());
  }

  void _editIntakeGoal(BuildContext context, WorkoutProvider provider) {
    final controller = TextEditingController(text: provider.intakeGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Intake Goal'),
        content: TextField(
          controller: controller, 
          keyboardType: TextInputType.number, 
          decoration: const InputDecoration(labelText: 'Target Calories', suffixText: 'kcal')
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.updateGoalField('intakeGoal', int.tryParse(controller.text) ?? provider.intakeGoal);
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
    final todaysFood = provider.todaysFood;
    
    final chartData = _showWeekly ? provider.weeklyNutrition : provider.monthlyNutrition;
    int maxCalories = 1; 
    for (var data in chartData) {
      if ((data['calories'] as int) > maxCalories) maxCalories = data['calories'] as int;
    }

    double progress = provider.intakeGoal > 0 ? (provider.dailyCaloriesEaten / provider.intakeGoal).clamp(0.0, 1.0) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition & Diet', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0, backgroundColor: Colors.transparent, foregroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FoodHistoryScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            InkWell(
              onTap: () => _editIntakeGoal(context, provider),
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
                    // --- RESPONSIVE FIX: Calories Header ---
                    Row(
                      children: [
                        const Expanded(
                          child: Text("Calories Eaten", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            children: [
                              Text('${provider.dailyCaloriesEaten} / ${provider.intakeGoal} kcal', style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              const Icon(Icons.edit, size: 12, color: Colors.grey),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: isDark ? Colors.grey.shade800 : Colors.green.shade50,
                        valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? Colors.redAccent : Colors.green), 
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // --- RESPONSIVE FIX: Macro Cards (Using Expanded instead of fixed width) ---
                    Row(
                      children: [
                        _buildMacroCard('Protein', '${provider.dailyProtein}g', Colors.blue, isDark),
                        const SizedBox(width: 10),
                        _buildMacroCard('Carbs', '${provider.dailyCarbs}g', Colors.orange, isDark),
                        const SizedBox(width: 10),
                        _buildMacroCard('Fat', '${provider.dailyFat}g', Colors.red, isDark),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // --- RESPONSIVE FIX: Chart Header ---
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Intake Chart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                        ),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('Wk', style: TextStyle(fontSize: 11))),
                            ButtonSegment(value: false, label: Text('Mo', style: TextStyle(fontSize: 11))),
                          ],
                          selected: {_showWeekly},
                          onSelectionChanged: (Set<bool> newSelection) => setState(() => _showWeekly = newSelection.first),
                          style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact, selectedBackgroundColor: Colors.green, selectedForegroundColor: Colors.white),
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
                          int eatenCal = data['calories'] as int;
                          double fillPercent = maxCalories == 0 ? 0 : eatenCal / maxCalories;
                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(eatenCal > 0 ? '$eatenCal' : '', style: TextStyle(fontSize: 9, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: FractionallySizedBox(
                                    heightFactor: fillPercent > 0 ? fillPercent.clamp(0.05, 1.0) : 0.05,
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: _showWeekly ? 18 : 24, 
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: eatenCal > 0 ? [Colors.green.shade300, Colors.green.shade600] : [isDark ? Colors.grey.shade800 : Colors.green.shade50, isDark ? Colors.grey.shade800 : Colors.green.shade50],
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
            
            todaysFood.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(child: Text("No food logged today.\nCheck History for past logs.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 16))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), 
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: todaysFood.length,
                    itemBuilder: (context, index) {
                      final food = todaysFood[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark? 0.3 : 0.03), blurRadius: 8, offset: const Offset(0, 3))]),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.restaurant, color: Colors.green)),
                          title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text('${_formatTime(food.date)}\n${food.protein}P • ${food.carbs}C • ${food.fat}F', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min, 
                            children: [
                              Text('+${food.calories} kcal', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              IconButton(icon: Icon(Icons.delete_outline, color: Colors.grey.shade400), onPressed: () => context.read<WorkoutProvider>().deleteFood(food.id)),
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
        backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 4,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddFoodScreen())),
        icon: const Icon(Icons.add), label: const Text('Meal', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- RESPONSIVE FIX: Wrap card in Expanded ---
  Widget _buildMacroCard(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.1) : color.withOpacity(0.05), 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: color.withOpacity(0.3))
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// --- FOOD HISTORY SCREEN ---
class FoodHistoryScreen extends StatelessWidget {
  const FoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final history = provider.pastFoodLogs;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition History', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0, backgroundColor: Colors.transparent, foregroundColor: Colors.green,
      ),
      body: history.isEmpty
          ? Center(child: Text('No past meals found.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final food = history[index];
                String dateStr = DateFormat('EEE, MMM d • h:mm a').format(food.date.toLocal());
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark? 0.3 : 0.03), blurRadius: 8, offset: const Offset(0, 3))]),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.history, color: Colors.green)),
                    title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('$dateStr\n${food.protein}P • ${food.carbs}C • ${food.fat}F', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    isThreeLine: true,
                    trailing: Text('${food.calories} kcal', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                );
              },
            ),
    );
  }
}

// ... AddFoodScreen ...
class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});
  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}
class _AddFoodScreenState extends State<AddFoodScreen> {
  final _nameController = TextEditingController();
  final _calController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbController = TextEditingController();
  final _fatController = TextEditingController();
  void _submitData() {
    final name = _nameController.text.trim();
    final cals = int.tryParse(_calController.text) ?? 0;
    final p = int.tryParse(_proteinController.text) ?? 0;
    final c = int.tryParse(_carbController.text) ?? 0;
    final f = int.tryParse(_fatController.text) ?? 0;
    if (name.isEmpty || cals <= 0) return;
    context.read<WorkoutProvider>().addFood(name, cals, p, c, f);
    Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Meal'), backgroundColor: Colors.green),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Food Name (e.g., Chicken)', prefixIcon: Icon(Icons.restaurant_menu))),
            const SizedBox(height: 20),
            TextField(controller: _calController, decoration: const InputDecoration(labelText: 'Total Calories', prefixIcon: Icon(Icons.bolt)), keyboardType: TextInputType.number),
            const SizedBox(height: 30),
            const Text('Macronutrients (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: TextField(controller: _proteinController, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number)),
                const SizedBox(width: 15),
                Expanded(child: TextField(controller: _carbController, decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: TextInputType.number)),
                const SizedBox(width: 15),
                Expanded(child: TextField(controller: _fatController, decoration: const InputDecoration(labelText: 'Fat (g)'), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _submitData, child: const Text('Save Meal', style: TextStyle(color: Colors.white, fontSize: 18))))
          ],
        ),
      ),
    );
  }
}