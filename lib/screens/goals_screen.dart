import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../workout_provider.dart';

// =============================================================================
// DESIGN TOKENS (mirrors profile_screen.dart & activity_screen.dart)
// =============================================================================

class _AppColors {
  static const teal = Color(0xFF00897B);
  static const tealLight = Color(0xFFE0F2F1);
  static const blue = Color(0xFF1E88E5);
  static const orange = Color(0xFFFB8C00);
  static const purple = Color(0xFF8E24AA);
  static const success = Color(0xFF43A047);
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
// GOALS SCREEN
// =============================================================================

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

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

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _editWeightGoalDialog(BuildContext context, WorkoutProvider provider) {
    bool isKg = true;
    String localGoalType = provider.goalType;
    final kgController =
        TextEditingController(text: provider.targetWeight.toStringAsFixed(1));
    final lbsController = TextEditingController(
        text: (provider.targetWeight / 0.453592).toStringAsFixed(1));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Edit Weight Goal',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: localGoalType,
                  decoration: InputDecoration(
                    labelText: 'Goal Type',
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: _AppSpacing.md, vertical: 16),
                  ),
                  items: ['Lose Weight', 'Maintain Weight', 'Gain Weight']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => localGoalType = v!),
                ),
                const SizedBox(height: _AppSpacing.md),
                _buildUnitToggle(
                    isKg,
                    (val) => setDialogState(() => isKg = val),
                    'kg',
                    'lbs',
                    isDark),
                const SizedBox(height: _AppSpacing.md),
                TextField(
                  controller: isKg ? kgController : lbsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isKg
                        ? 'Target Weight (kg)'
                        : 'Target Weight (lbs)',
                    suffixText: isKg ? 'kg' : 'lbs',
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                double targetKg = 0;
                if (isKg) {
                  targetKg = double.tryParse(kgController.text) ??
                      provider.targetWeight;
                } else {
                  double lbs = double.tryParse(lbsController.text) ??
                      (provider.targetWeight / 0.453592);
                  targetKg = lbs * 0.453592;
                }
                provider.updateGoalField('goalType', localGoalType);
                provider.updateGoalField('targetWeight', targetKg);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHeightEditDialog(BuildContext context, WorkoutProvider provider) {
    bool isCm = true;
    final cmController =
        TextEditingController(text: provider.height.toStringAsFixed(0));
    double totalInches = provider.height / 2.54;
    int initialFeet = (totalInches / 12).floor();
    int initialInches = (totalInches % 12).round();
    final ftController =
        TextEditingController(text: initialFeet.toString());
    final inController =
        TextEditingController(text: initialInches.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Update Height',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUnitToggle(
                  isCm,
                  (val) => setDialogState(() => isCm = val),
                  'cm',
                  'ft/in',
                  isDark),
              const SizedBox(height: _AppSpacing.lg),
              if (isCm)
                TextField(
                  controller: cmController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Centimeters',
                    suffixText: 'cm',
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: _AppSpacing.md, vertical: 16),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ftController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Feet',
                          suffixText: 'ft',
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
                    const SizedBox(width: _AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: inController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Inches',
                          suffixText: 'in',
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
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                double finalCm = 0;
                if (isCm) {
                  finalCm = double.tryParse(cmController.text) ??
                      provider.height;
                } else {
                  int ft = int.tryParse(ftController.text) ?? 0;
                  int inch = int.tryParse(inController.text) ?? 0;
                  finalCm = (ft * 30.48) + (inch * 2.54);
                }
                provider.updateSpecificMetric(height: finalCm);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeightEditDialog(BuildContext context, WorkoutProvider provider) {
    bool isKg = true;
    final kgController =
        TextEditingController(text: provider.weight.toStringAsFixed(1));
    final lbsController = TextEditingController(
        text: (provider.weight / 0.453592).toStringAsFixed(1));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Update Weight',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUnitToggle(
                  isKg,
                  (val) => setDialogState(() => isKg = val),
                  'kg',
                  'lbs',
                  isDark),
              const SizedBox(height: _AppSpacing.lg),
              TextField(
                controller: isKg ? kgController : lbsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isKg ? 'Weight (kg)' : 'Weight (lbs)',
                  suffixText: isKg ? 'kg' : 'lbs',
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                double finalKg = 0;
                if (isKg) {
                  finalKg =
                      double.tryParse(kgController.text) ?? provider.weight;
                } else {
                  double lbs = double.tryParse(lbsController.text) ??
                      (provider.weight / 0.453592);
                  finalKg = lbs * 0.453592;
                }
                provider.updateSpecificMetric(weight: finalKg);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────────────────

  static Widget _buildUnitToggle(bool isPrimary, Function(bool) onToggle,
      String label1, String label2, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isPrimary ? _AppColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !isPrimary ? _AppColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !isPrimary ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    String? subText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(_AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  if (onTap != null)
                    Icon(Icons.edit_rounded,
                        size: 14, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: _AppSpacing.md),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              if (subText != null) ...[
                const SizedBox(height: _AppSpacing.xs),
                Text(
                  subText,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBmiRecommendationCard(
      BuildContext context, WorkoutProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusColor;
    IconData statusIcon;
    String actionPlan = "";

    if (provider.bmiCategory == 'Healthy') {
      statusColor = _AppColors.success;
      statusIcon = Icons.check_circle_rounded;
      actionPlan =
          "Diet: Maintain your weight with a balanced intake of lean proteins, vegetables, and complex carbs.\n\nExercise: Keep a healthy mix of moderate cardio and strength training 3-5 times a week.";
    } else if (provider.bmiCategory == 'Obesity') {
      statusColor = _AppColors.red;
      statusIcon = Icons.warning_amber_rounded;
      actionPlan =
          "Medical: Please consider consulting a healthcare provider or nutritionist for a safe, personalized plan.\n\nDiet: Prioritize whole, unprocessed foods and portion control.\n\nExercise: Start with low-impact activities like swimming or brisk walking to protect your joints.";
    } else if (provider.bmiCategory == 'Underweight') {
      statusColor = _AppColors.orange;
      statusIcon = Icons.info_outline_rounded;
      actionPlan =
          "Diet: Focus on calorie-dense, nutrient-rich foods like nuts, avocados, lean meats, and dairy to achieve a caloric surplus.\n\nExercise: Prioritize strength training to build muscle mass rather than burning calories with excessive cardio.";
    } else if (provider.bmiCategory == 'Overweight') {
      statusColor = _AppColors.orange;
      statusIcon = Icons.info_outline_rounded;
      actionPlan =
          "Diet: Aim for a moderate caloric deficit. Focus on high-fiber foods and lean proteins to stay full, and reduce processed sugars.\n\nExercise: Combine regular cardio to burn calories with weight training to boost your metabolism.";
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.info_outline_rounded;
      actionPlan =
          "Log your height and weight to receive personalized diet and exercise recommendations.";
    }

    return Container(
      margin: const EdgeInsets.only(top: _AppSpacing.sm),
      padding: const EdgeInsets.all(_AppSpacing.lg),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: _AppSpacing.sm),
              Text(
                'BMI: ${provider.bmiCategory}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: _AppSpacing.md),
          Text(
            provider.bmiRecommendation,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: _AppSpacing.md),
          // Action plan sub-card
          Container(
            padding: const EdgeInsets.all(_AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black26
                  : Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant_menu_rounded,
                        size: 15, color: statusColor),
                    const SizedBox(width: _AppSpacing.sm),
                    Text(
                      'Action Plan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _AppSpacing.sm),
                Text(
                  actionPlan,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double difference =
        (provider.weight - provider.targetWeight).abs();
    double goalProgress =
        (10 - difference.clamp(0.0, 10.0)) / 10;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text(
          'Goals & Metrics',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: _AppSpacing.lg, vertical: _AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section label ────────────────────────────────────────
            _smoothEntry(
              index: 0,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 4, bottom: _AppSpacing.sm),
                child: Text(
                  'WEIGHT GOAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),

            // ── Weight goal progress card ────────────────────────────
            _smoothEntry(
              index: 1,
              child: GestureDetector(
                onTap: () => _editWeightGoalDialog(context, provider),
                child: Container(
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.goalType,
                                style: const TextStyle(
                                  color: _AppColors.blue,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Target: ${provider.targetWeight.toStringAsFixed(1)} kg',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _AppColors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.edit_rounded,
                                size: 16, color: _AppColors.blue),
                          ),
                        ],
                      ),
                      const SizedBox(height: _AppSpacing.lg),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutCubic,
                        tween: Tween(begin: 0, end: goalProgress),
                        builder: (context, val, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: val,
                            minHeight: 10,
                            backgroundColor:
                                _AppColors.blue.withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                _AppColors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(height: _AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${difference.toStringAsFixed(1)} kg to go',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: _AppSpacing.lg),

            // ── Section label ────────────────────────────────────────
            _smoothEntry(
              index: 2,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 4, bottom: _AppSpacing.sm),
                child: Text(
                  'BODY METRICS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),

            // ── Metric cards row 1 ───────────────────────────────────
            _smoothEntry(
              index: 3,
              child: Row(
                children: [
                  _buildMetricCard(
                    context,
                    'Height',
                    '${provider.height.toStringAsFixed(0)} cm',
                    Icons.height_rounded,
                    _AppColors.teal,
                    () => _showHeightEditDialog(context, provider),
                  ),
                  const SizedBox(width: _AppSpacing.sm),
                  _buildMetricCard(
                    context,
                    'Weight',
                    '${provider.weight.toStringAsFixed(1)} kg',
                    Icons.monitor_weight_outlined,
                    _AppColors.teal,
                    () => _showWeightEditDialog(context, provider),
                  ),
                ],
              ),
            ),

            const SizedBox(height: _AppSpacing.sm),

            // ── Metric cards row 2 ───────────────────────────────────
            _smoothEntry(
              index: 4,
              child: Row(
                children: [
                  _buildMetricCard(
                    context,
                    'BMI',
                    provider.bmi.toStringAsFixed(1),
                    Icons.speed_rounded,
                    _AppColors.purple,
                    null,
                    subText: provider.bmiCategory,
                  ),
                  const SizedBox(width: _AppSpacing.sm),
                  _buildMetricCard(
                    context,
                    'Maintenance',
                    '${provider.maintenanceCalories}',
                    Icons.local_fire_department_rounded,
                    _AppColors.orange,
                    null,
                    subText: 'kcal / day',
                  ),
                ],
              ),
            ),

            const SizedBox(height: _AppSpacing.sm),

            // ── BMI recommendation card ──────────────────────────────
            if (provider.height > 0 && provider.weight > 0)
              _smoothEntry(
                index: 5,
                child: _buildBmiRecommendationCard(context, provider),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}