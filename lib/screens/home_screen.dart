import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../workout_provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// =============================================================================
// DESIGN TOKENS (mirrors profile_screen.dart, activity_screen.dart, goals_screen.dart)
// =============================================================================

class _AppColors {
  static const teal = Color(0xFF00897B);
  static const tealLight = Color(0xFFE0F2F1);
  static const orange = Color(0xFFFB8C00);
  static const orangeLight = Color(0xFFFFF3E0);
  static const blue = Color(0xFF1E88E5);
  static const green = Color(0xFF43A047);
  static const red = Color(0xFFE53935);
}

class _AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

// =============================================================================
// HOME SCREEN
// =============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _dailyQuote = "Fetching motivation...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchDailyQuoteAPI();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _fetchDailyQuoteAPI();
    }
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

  Future<void> _fetchDailyQuoteAPI() async {
    if (mounted) setState(() => _dailyQuote = "Fetching motivation...");
    try {
      final response =
          await http.get(Uri.parse('https://zenquotes.io/api/random'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted)
          setState(() =>
              _dailyQuote = '"${data[0]['q']}" — ${data[0]['a']}');
      } else {
        _useFallbackQuote();
      }
    } catch (e) {
      _useFallbackQuote();
    }
  }

  void _useFallbackQuote() {
    if (mounted)
      setState(() => _dailyQuote =
          "Push harder than yesterday if you want a different tomorrow.");
  }

  void _editStepGoalDialog(BuildContext context, WorkoutProvider provider) {
    final controller =
        TextEditingController(text: provider.stepGoal.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Update Step Goal',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Daily Steps',
            prefixIcon:
                const Icon(Icons.directions_walk_rounded, size: 20),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: _AppColors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) provider.updateGoalField('stepGoal', val);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    if (!provider.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: _AppColors.teal),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String displayName =
        FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ??
            'User';

    final double stepProgress = provider.stepGoal > 0
        ? (provider.dailySteps / provider.stepGoal).clamp(0.0, 1.0)
        : 0.0;
    final double intakeProgress = provider.intakeGoal > 0
        ? (provider.dailyCaloriesEaten / provider.intakeGoal).clamp(0.0, 1.0)
        : 0.0;
    final double burnProgress = provider.calorieGoal > 0
        ? (provider.dailyCaloriesBurned / provider.calorieGoal)
            .clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text(
          'Overview',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded,
                color: _AppColors.orange, size: 24),
            onPressed: () => Navigator.push(
                context, _smoothPageRoute(const StepHistoryScreen())),
          ),
          const SizedBox(width: _AppSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: _AppSpacing.lg, vertical: _AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ─────────────────────────────────────────────
            _smoothEntry(
              index: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello,',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: _AppSpacing.sm),

            // ── Daily quote ──────────────────────────────────────────
            _smoothEntry(
              index: 1,
              child: Text(
                _dailyQuote,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade500,
                ),
              ),
            ),

            const SizedBox(height: _AppSpacing.xxl),

            // ── Step ring ────────────────────────────────────────────
            _smoothEntry(
              index: 2,
              child: Center(
                child: GestureDetector(
                  onTap: () => _editStepGoalDialog(context, provider),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 220,
                        width: 220,
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCirc,
                          tween: Tween(begin: 0, end: stepProgress),
                          builder: (context, val, _) =>
                              CircularProgressIndicator(
                            value: val,
                            strokeWidth: 14,
                            strokeCap: StrokeCap.round,
                            backgroundColor: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                _AppColors.orange),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_walk_rounded,
                              color: _AppColors.orange, size: 28),
                          const SizedBox(height: _AppSpacing.xs),
                          Text(
                            '${provider.dailySteps}',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'of ${provider.stepGoal}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: _AppSpacing.xxl),

            // ── Stat rows ────────────────────────────────────────────
            _smoothEntry(
              index: 3,
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
                    _buildStatRow(
                      'Activity Burn',
                      Icons.local_fire_department_rounded,
                      _AppColors.teal,
                      provider.dailyCaloriesBurned,
                      provider.calorieGoal,
                      burnProgress,
                      isDark,
                    ),
                    const SizedBox(height: _AppSpacing.lg),
                    _buildStatRow(
                      'Nutrition Intake',
                      Icons.restaurant_rounded,
                      _AppColors.green,
                      provider.dailyCaloriesEaten,
                      provider.intakeGoal,
                      intakeProgress,
                      isDark,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: _AppSpacing.md),

            // ── Macros card ──────────────────────────────────────────
            _smoothEntry(
              index: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: _AppSpacing.lg,
                    horizontal: _AppSpacing.md),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMacroCell(
                        'Protein', '${provider.dailyProtein}g',
                        _AppColors.blue, isDark),
                    _buildDivider(isDark),
                    _buildMacroCell(
                        'Carbs', '${provider.dailyCarbs}g',
                        _AppColors.orange, isDark),
                    _buildDivider(isDark),
                    _buildMacroCell(
                        'Fat', '${provider.dailyFat}g',
                        _AppColors.red, isDark),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String title,
    IconData icon,
    Color color,
    int current,
    int goal,
    double progress,
    bool isDark,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: _AppSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              '$current / $goal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const SizedBox(height: _AppSpacing.sm),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
          tween: Tween(begin: 0, end: progress),
          builder: (context, val, _) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: val,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCell(
      String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: _AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: isDark
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.08),
    );
  }
}

// =============================================================================
// STEP HISTORY SCREEN
// =============================================================================

class StepHistoryScreen extends StatelessWidget {
  const StepHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final rawHistory = provider.stepHistory;
    final Map<String, dynamic> uniqueLogs = {};
    for (var log in rawHistory) {
      String dateKey = DateFormat('yyyy-MM-dd').format(log.date);
      if (!uniqueLogs.containsKey(dateKey) ||
          log.steps > uniqueLogs[dateKey].steps) {
        uniqueLogs[dateKey] = log;
      }
    }
    final history = uniqueLogs.values.toList();
    history.sort((a, b) => b.date.compareTo(a.date));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text(
          'Step History',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_walk_rounded,
                      size: 56, color: Colors.grey.withOpacity(0.25)),
                  const SizedBox(height: _AppSpacing.md),
                  Text(
                    'No history yet. Start walking!',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: _AppSpacing.lg, vertical: _AppSpacing.md),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final log = history[index];
                final String dateStr =
                    DateFormat('EEEE, MMM d').format(log.date);
                final bool goalReached = provider.stepGoal > 0 &&
                    log.steps >= provider.stepGoal;

                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, val, child) => Opacity(
                    opacity: val,
                    child: Transform.translate(
                        offset: Offset(0, 18 * (1 - val)), child: child),
                  ),
                  child: Container(
                    margin:
                        const EdgeInsets.only(bottom: _AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                        horizontal: _AppSpacing.md, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A1A1A)
                          : Colors.white,
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
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _AppColors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.directions_walk_rounded,
                            color: _AppColors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: _AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${log.steps} ',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'steps',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (goalReached)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: _AppSpacing.sm,
                                vertical: _AppSpacing.xs),
                            decoration: BoxDecoration(
                              color:
                                  _AppColors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.stars_rounded,
                                color: _AppColors.orange, size: 18),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}