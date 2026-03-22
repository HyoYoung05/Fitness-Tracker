import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../workout_provider.dart';
import 'package:intl/intl.dart';

// =============================================================================
// DESIGN TOKENS (mirrors profile_screen.dart, activity_screen.dart, etc.)
// =============================================================================

class _AppColors {
  static const teal = Color(0xFF00897B);
  static const green = Color(0xFF43A047);
  static const greenLight = Color(0xFFE8F5E9);
  static const blue = Color(0xFF1E88E5);
  static const orange = Color(0xFFFB8C00);
  static const red = Color(0xFFE53935);
}

class _AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xxl = 48.0;
}

// =============================================================================
// 1. MAIN NUTRITION SCREEN
// =============================================================================

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
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

  void _editIntakeGoal(BuildContext context, WorkoutProvider provider) {
    final controller =
        TextEditingController(text: provider.intakeGoal.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Daily Intake Goal',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Target Calories',
            suffixText: 'kcal',
            prefixIcon:
                const Icon(Icons.restaurant_rounded, size: 20),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
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
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateGoalField(
                'intakeGoal',
                int.tryParse(controller.text) ?? provider.intakeGoal,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _AppColors.green,
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

  Widget _buildMacroChip(
      String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: _AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartToggle(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _showWeekly = (label == 'Wk')),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: _AppSpacing.md, vertical: _AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? _AppColors.green : Colors.transparent,
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
    final todaysFood = provider.todaysFood;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chartData =
        _showWeekly ? provider.weeklyNutrition : provider.monthlyNutrition;
    int maxCalories = 1;
    for (var data in chartData) {
      if ((data['calories'] as int) > maxCalories) {
        maxCalories = data['calories'] as int;
      }
    }

    double progress = provider.intakeGoal > 0
        ? (provider.dailyCaloriesEaten / provider.intakeGoal)
            .clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text(
          'Nutrition & Diet',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded,
                size: 24, color: _AppColors.green),
            onPressed: () => Navigator.push(
                context, _smoothPageRoute(const FoodHistoryScreen())),
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
                onTap: () => _editIntakeGoal(context, provider),
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
                                "Calories Eaten",
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Daily nutrition fuel",
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: _AppSpacing.sm + 4,
                                vertical: _AppSpacing.xs + 2),
                            decoration: BoxDecoration(
                              color: _AppColors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${provider.dailyCaloriesEaten} / ${provider.intakeGoal} kcal',
                              style: const TextStyle(
                                color: _AppColors.green,
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
                                : _AppColors.greenLight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 1.0
                                  ? _AppColors.red
                                  : _AppColors.green,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: _AppSpacing.lg),

                      // Macro chips
                      Row(
                        children: [
                          _buildMacroChip('Protein',
                              '${provider.dailyProtein}g', _AppColors.blue, isDark),
                          const SizedBox(width: _AppSpacing.sm),
                          _buildMacroChip('Carbs',
                              '${provider.dailyCarbs}g', _AppColors.orange, isDark),
                          const SizedBox(width: _AppSpacing.sm),
                          _buildMacroChip('Fat',
                              '${provider.dailyFat}g', _AppColors.red, isDark),
                        ],
                      ),

                      const SizedBox(height: _AppSpacing.lg),

                      // Chart controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Intake Chart',
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
                            int eatenCal = data['calories'] as int;
                            double fillPercent = maxCalories == 0
                                ? 0
                                : eatenCal / maxCalories;
                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (eatenCal > 0)
                                    Text(
                                      '$eatenCal',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: _AppColors.green,
                                      ),
                                    ),
                                  const SizedBox(height: _AppSpacing.xs),
                                  Flexible(
                                    child: FractionallySizedBox(
                                      heightFactor: fillPercent > 0
                                          ? fillPercent.clamp(0.08, 1.0)
                                          : 0.08,
                                      alignment: Alignment.bottomCenter,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 600),
                                        curve: Curves.easeOutBack,
                                        width: _showWeekly ? 16 : 10,
                                        decoration: BoxDecoration(
                                          color: eatenCal > 0
                                              ? _AppColors.green
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
                                      color: Colors.grey,
                                    ),
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

            // ── Today's Meals header ──────────────────────────────────
            _smoothEntry(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: _AppSpacing.lg, vertical: _AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Meals",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (todaysFood.isNotEmpty)
                      Text(
                        '${todaysFood.length} logged',
                        style: const TextStyle(
                          color: _AppColors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: _AppSpacing.sm),

            // ── Meal list ─────────────────────────────────────────────
            todaysFood.isEmpty
                ? _smoothEntry(
                    index: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: _AppSpacing.xxl),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restaurant_rounded,
                              size: 56,
                              color: Colors.grey.withOpacity(0.25),
                            ),
                            const SizedBox(height: _AppSpacing.md),
                            Text(
                              'No meals logged today',
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
                    itemCount: todaysFood.length,
                    itemBuilder: (context, index) {
                      final food = todaysFood[index];
                      return _smoothEntry(
                        index: index + 2,
                        child: Container(
                          margin: const EdgeInsets.only(
                              bottom: _AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color:
                                          Colors.black.withOpacity(0.03),
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
                                    color: _AppColors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_rounded,
                                    color: _AppColors.green,
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
                                        food.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatTime(food.date),
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${food.protein}P · ${food.carbs}C · ${food.fat}F',
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+${food.calories}',
                                      style: const TextStyle(
                                        color: _AppColors.green,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: _AppSpacing.xs),
                                    GestureDetector(
                                      onTap: () => context
                                          .read<WorkoutProvider>()
                                          .deleteFood(food.id),
                                      child: Icon(
                                        Icons.delete_outline_rounded,
                                        color: _AppColors.red.withOpacity(0.45),
                                        size: 20,
                                      ),
                                    ),
                                  ],
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
            context, _smoothPageRoute(const AddFoodScreen())),
        backgroundColor: _AppColors.green,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Log Meal',
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
// 2. FOOD HISTORY SCREEN
// =============================================================================

class FoodHistoryScreen extends StatelessWidget {
  const FoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Map<String, List<FoodLog>> groupedFood = {};
    for (var food in provider.pastFoodLogs) {
      String dateKey = DateFormat('EEEE, MMM d').format(food.date);
      groupedFood.putIfAbsent(dateKey, () => []).add(food);
    }

    final sortedDates = groupedFood.keys.toList();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text(
          'Diet History',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: sortedDates.isEmpty
          ? _buildEmptyState(
              Icons.restaurant_rounded, 'No meal logs yet')
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: _AppSpacing.lg, vertical: _AppSpacing.md),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final String date = sortedDates[index];
                final List<FoodLog> logs = groupedFood[date]!;
                final int dailyTotal =
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
                              color: _AppColors.green,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...logs.asMap().entries.map((entry) {
                      return TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, val, child) => Opacity(
                          opacity: val,
                          child: Transform.translate(
                              offset: Offset(0, 18 * (1 - val)),
                              child: child),
                        ),
                        child: _buildFoodHistoryCard(entry.value, isDark),
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
          Icon(icon, size: 56, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: _AppSpacing.md),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodHistoryCard(FoodLog food, bool isDark) {
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
                color: _AppColors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fastfood_rounded,
                  color: _AppColors.green, size: 18),
            ),
            const SizedBox(width: _AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${food.protein}P · ${food.carbs}C · ${food.fat}F',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '+${food.calories} kcal',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _AppColors.green,
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
// 3. ADD FOOD SCREEN
// =============================================================================

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

  @override
  void dispose() {
    _nameController.dispose();
    _calController.dispose();
    _proteinController.dispose();
    _carbController.dispose();
    _fatController.dispose();
    super.dispose();
  }

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

  Widget _buildMacroInput(
      TextEditingController controller, String label, Color fillColor) {
    return Expanded(
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          labelStyle: TextStyle(
              fontSize: 12, color: Colors.grey.shade500),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: _AppSpacing.sm, vertical: 14),
        ),
      ),
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
          'Log Meal',
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

            // ── Food name ────────────────────────────────────────────
            _smoothEntry(
              index: 0,
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Food Name',
                  hintText: 'e.g., Avocado Toast',
                  prefixIcon: const Icon(
                      Icons.restaurant_menu_rounded,
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

            const SizedBox(height: _AppSpacing.md),

            // ── Calories ─────────────────────────────────────────────
            _smoothEntry(
              index: 1,
              child: TextField(
                controller: _calController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Calories',
                  suffixText: 'kcal',
                  prefixIcon:
                      const Icon(Icons.bolt_rounded, size: 20),
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

            const SizedBox(height: _AppSpacing.lg),

            // ── Macronutrients label ─────────────────────────────────
            _smoothEntry(
              index: 2,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: _AppSpacing.xs, bottom: _AppSpacing.sm),
                child: Text(
                  'MACRONUTRIENTS (OPTIONAL)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),

            // ── Macro inputs row ─────────────────────────────────────
            _smoothEntry(
              index: 3,
              child: Row(
                children: [
                  _buildMacroInput(
                      _proteinController, 'Prot (g)', fillColor),
                  const SizedBox(width: _AppSpacing.sm),
                  _buildMacroInput(
                      _carbController, 'Carbs (g)', fillColor),
                  const SizedBox(width: _AppSpacing.sm),
                  _buildMacroInput(_fatController, 'Fat (g)', fillColor),
                ],
              ),
            ),

            const SizedBox(height: _AppSpacing.xxl),

            // ── Save button ──────────────────────────────────────────
            _smoothEntry(
              index: 4,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _AppColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Save Meal',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
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