import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../workout_provider.dart';
import 'package:intl/intl.dart';

// =============================================================================
// DESIGN TOKENS (mirrors profile_screen.dart)
// =============================================================================

class _AppColors {
  static const teal = Color(0xFF00897B);
  static const tealLight = Color(0xFFE0F2F1);
  static const tealDark = Color(0xFF00695C);
  static const orange = Color(0xFFFB8C00);
  static const orangeLight = Color(0xFFFFF3E0);
  static const red = Color(0xFFE53935);
  static const redLight = Color(0xFFFFEBEE);
}

class _AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xxl = 48.0;
}

// =============================================================================
// ACTIVITY SCREEN
// =============================================================================

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

  Widget _smoothEntry({required Widget child, required int index}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + index * 60),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Route _smoothPageRoute(Widget destination) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        var tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeInOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  void _editBurnGoal(BuildContext context, WorkoutProvider provider) {
    final controller =
        TextEditingController(text: provider.calorieGoal.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Daily Burn Goal',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Target Calories',
            suffixText: 'kcal',
            prefixIcon: const Icon(Icons.local_fire_department_rounded, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: _AppSpacing.md, vertical: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateGoalField(
                  'calorieGoal',
                  int.tryParse(controller.text) ?? provider.calorieGoal);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _AppColors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildChartToggle(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _showWeekly = (label == 'Wk')),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: _AppSpacing.md, vertical: _AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? _AppColors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final chartData =
        _showWeekly ? provider.weeklyActivity : provider.monthlyActivity;
    final todaysWorkouts = provider.todaysWorkouts;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int maxCalories = 1;
    for (var data in chartData) {
      if ((data['calories'] as int) > maxCalories)
        maxCalories = data['calories'] as int;
    }

    double progress = provider.calorieGoal > 0
        ? (provider.dailyCaloriesBurned / provider.calorieGoal).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text(
          'Activity',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 24, color: _AppColors.teal),
            onPressed: () => Navigator.push(
                context, _smoothPageRoute(const WorkoutHistoryScreen())),
          ),
          const SizedBox(width: _AppSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary / Chart Card ──────────────────────────────────
            _smoothEntry(
              index: 0,
              child: GestureDetector(
                onTap: () => _editBurnGoal(context, provider),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: _AppSpacing.lg, vertical: _AppSpacing.sm),
                  padding: const EdgeInsets.all(_AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Today's Burn",
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Active calories",
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 12),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: _AppSpacing.sm + 4, vertical: _AppSpacing.xs + 2),
                            decoration: BoxDecoration(
                              color: _AppColors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${provider.dailyCaloriesBurned} / ${provider.calorieGoal} kcal',
                              style: const TextStyle(
                                color: _AppColors.teal,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: _AppSpacing.lg),

                      // Progress bar
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutCubic,
                        tween: Tween(begin: 0, end: progress),
                        builder: (context, val, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: val,
                            minHeight: 10,
                            backgroundColor: isDark
                                ? Colors.grey.shade800
                                : _AppColors.tealLight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              val >= 1.0 ? _AppColors.orange : _AppColors.teal,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: _AppSpacing.lg),

                      // Stats label + toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Stats',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          Container(
                            height: 32,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black26
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                _buildChartToggle('Wk', _showWeekly),
                                _buildChartToggle('Mo', !_showWeekly),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: _AppSpacing.md),

                      // Bar chart
                      SizedBox(
                        height: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: chartData.map((data) {
                            int burnedCal = data['calories'] as int;
                            double fillPercent = maxCalories == 0
                                ? 0
                                : burnedCal / maxCalories;
                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (burnedCal > 0)
                                    Text(
                                      '$burnedCal',
                                      style: const TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: _AppColors.teal),
                                    ),
                                  const SizedBox(height: _AppSpacing.xs),
                                  Flexible(
                                    child: FractionallySizedBox(
                                      heightFactor: fillPercent > 0
                                          ? fillPercent.clamp(0.08, 1.0)
                                          : 0.08,
                                      alignment: Alignment.bottomCenter,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 600),
                                        curve: Curves.easeOutBack,
                                        width: _showWeekly ? 16 : 10,
                                        decoration: BoxDecoration(
                                          color: burnedCal > 0
                                              ? _AppColors.teal
                                              : (isDark
                                                  ? Colors.grey.shade800
                                                  : Colors.grey.shade200),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: _AppSpacing.sm),
                                  Text(
                                    data['day'] as String,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: _AppSpacing.md),

            // ── Today's Workouts Header ──────────────────────────────
            _smoothEntry(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: _AppSpacing.lg, vertical: _AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Workouts",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (todaysWorkouts.isNotEmpty)
                      Text(
                        '${todaysWorkouts.length} logged',
                        style: const TextStyle(
                            color: _AppColors.teal,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: _AppSpacing.sm),

            // ── Workout List ─────────────────────────────────────────
            todaysWorkouts.isEmpty
                ? _smoothEntry(
                    index: 2,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: _AppSpacing.xxl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              size: 56,
                              color: Colors.grey.withOpacity(0.25),
                            ),
                            const SizedBox(height: _AppSpacing.md),
                            Text(
                              'No workouts logged today',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: _AppSpacing.lg),
                    itemCount: todaysWorkouts.length,
                    itemBuilder: (context, index) {
                      final workout = todaysWorkouts[index];
                      return _smoothEntry(
                        index: index + 2,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: _AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: _AppSpacing.md, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _AppColors.teal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center_rounded,
                                    color: _AppColors.teal,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: _AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        workout.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatTime(workout.date),
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${workout.calories} kcal',
                                  style: const TextStyle(
                                    color: _AppColors.orange,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: _AppSpacing.xs),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: _AppColors.red.withOpacity(0.45),
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => context
                                      .read<WorkoutProvider>()
                                      .deleteWorkout(workout.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context, _smoothPageRoute(const AddWorkoutScreen())),
        backgroundColor: _AppColors.teal,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Log Workout',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// WORKOUT HISTORY SCREEN
// =============================================================================

class WorkoutHistoryScreen extends StatelessWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Map<String, List<Workout>> groupedWorkouts = {};
    for (var workout in provider.pastWorkouts) {
      String dateKey = DateFormat('EEEE, MMM d').format(workout.date);
      groupedWorkouts.putIfAbsent(dateKey, () => []).add(workout);
    }

    var sortedDates = groupedWorkouts.keys.toList();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text(
          'Workout History',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: sortedDates.isEmpty
          ? _buildEmptyState(
              Icons.fitness_center_rounded, 'No past workouts yet')
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: _AppSpacing.lg, vertical: _AppSpacing.md),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                String date = sortedDates[index];
                List<Workout> logs = groupedWorkouts[date]!;
                int dailyTotal =
                    logs.fold(0, (sum, item) => sum + item.calories);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date group header
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: _AppSpacing.sm,
                          top: index == 0 ? 0 : _AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            date.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          Text(
                            '$dailyTotal kcal',
                            style: const TextStyle(
                              color: _AppColors.teal,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...logs.asMap().entries.map((entry) {
                      final workout = entry.value;
                      return TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, val, child) => Opacity(
                          opacity: val,
                          child: Transform.translate(
                              offset: Offset(0, 18 * (1 - val)),
                              child: child),
                        ),
                        child: _buildHistoryCard(
                          workout.title,
                          '${workout.calories} kcal',
                          DateFormat('h:mm a').format(workout.date),
                          isDark,
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: _AppSpacing.md),
          Text(message,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
      String title, String calories, String time, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: _AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: _AppSpacing.md, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _AppColors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_rounded,
                  color: _AppColors.teal, size: 18),
            ),
            const SizedBox(width: _AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              calories,
              style: const TextStyle(
                color: _AppColors.orange,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ADD WORKOUT SCREEN
// =============================================================================

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
  void dispose() {
    _titleController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Widget _smoothEntry({required Widget child, required int index}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + index * 60),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)), child: child),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text(
          'Log Workout',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: _AppSpacing.sm),

            // ── Workout Title ────────────────────────────────────────
            _smoothEntry(
              index: 0,
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Workout Title',
                  hintText: 'e.g., Evening Run',
                  prefixIcon: const Icon(Icons.directions_run_rounded, size: 20),
                  filled: true,
                  fillColor: fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: _AppSpacing.md, vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: _AppSpacing.md),

            // ── Calories Burned ──────────────────────────────────────
            _smoothEntry(
              index: 1,
              child: TextField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Calories Burned',
                  suffixText: 'kcal',
                  prefixIcon: const Icon(
                      Icons.local_fire_department_rounded,
                      size: 20),
                  filled: true,
                  fillColor: fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: _AppSpacing.md, vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: _AppSpacing.xxl),

            // ── Save Button ──────────────────────────────────────────
            _smoothEntry(
              index: 2,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _AppColors.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Save Workout',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}