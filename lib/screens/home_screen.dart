import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../workout_provider.dart';
import 'package:intl/intl.dart'; // Make sure to add this for formatting dates

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- NEW: Daily Motivation Quotes ---
  String _getDailyQuote() {
    final List<String> quotes = [
      "Push harder than yesterday if you want a different tomorrow.",
      "The secret of getting ahead is getting started.",
      "It never gets easier, you just get stronger.",
      "Don't stop when you're tired. Stop when you're done.",
      "Wake up with determination. Go to bed with satisfaction.",
      "A one-hour workout is 4% of your day. No excuses.",
      "Success starts with self-discipline.",
      "Small daily improvements are the key to staggering long-term results."
    ];
    // Picks a quote based on the day of the year, so it changes daily but doesn't flicker on rebuilds
    int dayOfYear = int.parse(DateFormat("D").format(DateTime.now()));
    return quotes[dayOfYear % quotes.length];
  }

  void _editStepGoalDialog(BuildContext context, WorkoutProvider provider) {
    final controller = TextEditingController(text: provider.stepGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Update Step Goal', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Daily Steps', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.teal))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) provider.updateGoalField('stepGoal', val);
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    
    if (!provider.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String displayName = user?.displayName ?? 'Fitness User';

    double stepProgress = (provider.stepGoal > 0) ? (provider.dailySteps / provider.stepGoal).clamp(0.0, 1.0) : 0.0;
    double intakeProgress = provider.intakeGoal > 0 ? (provider.dailyCaloriesEaten / provider.intakeGoal).clamp(0.0, 1.0) : 0.0;
    double burnProgress = provider.calorieGoal > 0 ? (provider.dailyCaloriesBurned / provider.calorieGoal).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0, backgroundColor: Colors.transparent, foregroundColor: isDark ? Colors.white : Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 24),
                const SizedBox(width: 6),
                Text('${provider.streak} Day Streak', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orangeAccent)),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back, $displayName!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            
            // --- NEW: Daily Motivation Quote ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.teal.withOpacity(0.3))),
              child: Row(
                children: [
                  const Icon(Icons.format_quote, color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_getDailyQuote(), style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: isDark ? Colors.tealAccent : Colors.teal.shade800))),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // TAPPABLE SINGLE STEP COUNTER
            InkWell(
              onTap: () => _editStepGoalDialog(context, provider),
              borderRadius: BorderRadius.circular(24),
              child: _buildStepCard(context, provider, stepProgress, isDark),
            ),
            const SizedBox(height: 24),

            // NUTRITION SUMMARY
            _buildSummaryCard(context, 'Nutrition Intake', Icons.restaurant, Colors.green, provider.dailyCaloriesEaten, provider.intakeGoal, intakeProgress, provider.dailyCaloriesEaten > provider.intakeGoal),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildMacroChip('Protein', '${provider.dailyProtein}g', Colors.blue, isDark)),
                const SizedBox(width: 10),
                Expanded(child: _buildMacroChip('Carbs', '${provider.dailyCarbs}g', Colors.orange, isDark)),
                const SizedBox(width: 10),
                Expanded(child: _buildMacroChip('Fat', '${provider.dailyFat}g', Colors.red, isDark)),
              ],
            ),
            const SizedBox(height: 24),

            // ACTIVITY SUMMARY
            _buildSummaryCard(context, 'Activity Burn', Icons.fitness_center, Colors.teal, provider.dailyCaloriesBurned, provider.calorieGoal, burnProgress, false),
          ],
        ),
      ),
    );
  }

Widget _buildStepCard(BuildContext context, WorkoutProvider provider, double progress, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
        children: [
          // Expanded ensures the text takes only available space and doesn't push the circle out
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8), 
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle), 
                      child: const Icon(Icons.directions_walk, color: Colors.orange, size: 20)
                    ),
                    const SizedBox(width: 10),
                    // Flexible prevents long text from overflowing on very small screens
                    const Flexible(
                      child: Text('Steps Today', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // History Button (Moved below the title for better small-screen fit)
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StepHistoryScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min, // Keep button compact
                      children: [
                        Icon(Icons.history, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('History', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Step Count Text
                FittedBox( // Shrinks text if the number gets extremely large (e.g., 100,000 steps)
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: RichText(text: TextSpan(children: [
                    TextSpan(text: '${provider.dailySteps} ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    TextSpan(text: '/ ${provider.stepGoal}', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                  ])),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16), // Spacing between text and circle
          
          // The Circular Tracker (Now safely contained on the right)
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80, // Slightly increased for better visual balance
                width: 80, 
                child: CircularProgressIndicator(
                  value: progress, 
                  strokeWidth: 8, 
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.orange.shade50, 
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange)
                )
              ),
              Icon(Icons.stars, color: progress >= 1.0 ? Colors.orange : Colors.grey.withOpacity(0.3), size: 32),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, IconData icon, MaterialColor color, int current, int goal, double progress, bool isOver) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
              const SizedBox(width: 15),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(text: TextSpan(children: [
                TextSpan(text: '$current ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                TextSpan(text: '/ $goal kcal', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
              ])),
              Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isOver ? Colors.redAccent : color)),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: isDark ? Colors.grey.shade800 : color.shade50, valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.redAccent : color)),
          )
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: isDark ? color.withOpacity(0.1) : color.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- NEW: STEP HISTORY SCREEN ---
class StepHistoryScreen extends StatelessWidget {
  const StepHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final history = provider.stepHistory;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Step History', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0, backgroundColor: Colors.transparent, foregroundColor: Colors.orange,
      ),
      body: history.isEmpty
          ? Center(child: Text('No step history recorded yet.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final log = history[index];
                String dateStr = DateFormat('EEEE, MMM d, yyyy').format(log.date);
                double progress = (provider.stepGoal > 0) ? (log.steps / provider.stepGoal).clamp(0.0, 1.0) : 0.0;
                bool goalReached = log.steps >= provider.stepGoal;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                          if (goalReached) const Icon(Icons.stars, color: Colors.orange, size: 20)
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          RichText(text: TextSpan(children: [
                            TextSpan(text: '${log.steps} ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                            TextSpan(text: 'steps', style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                          ])),
                          Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: isDark ? Colors.grey.shade800 : Colors.orange.shade50, valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange)),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}