import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../workout_provider.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  // Dialog to update Goal Type and Target Weight together
  void _editWeightGoalDialog(BuildContext context, WorkoutProvider provider) {
    String localGoalType = provider.goalType;
    final targetWeightController = TextEditingController(text: provider.targetWeight.toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Weight Goal', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: localGoalType,
                  decoration: const InputDecoration(labelText: 'Goal Type'),
                  items: ['Lose Weight', 'Maintain Weight', 'Gain Weight']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => localGoalType = v!),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: targetWeightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Target Weight (kg)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {
                final target = double.tryParse(targetWeightController.text) ?? provider.targetWeight;
                provider.updateGoalField('goalType', localGoalType);
                provider.updateGoalField('targetWeight', target);
                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double difference = (provider.weight - provider.targetWeight).abs();
    double goalProgress = (10 - difference.clamp(0.0, 10.0)) / 10;

    return Scaffold(
      appBar: AppBar(title: const Text('Goals & Metrics', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weight Goal Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // --- UPDATED INTERACTIVE WEIGHT CARD ---
            InkWell(
              onTap: () => _editWeightGoalDialog(context, provider),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 5))]
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(provider.goalType, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text('Target: ${provider.targetWeight} kg', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Icon(Icons.edit, size: 18, color: Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(value: goalProgress, minHeight: 14, backgroundColor: isDark ? Colors.grey.shade800 : Colors.blue.shade50, valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue)),
                    ),
                    const SizedBox(height: 10),
                    Text('${difference.toStringAsFixed(1)} kg to go', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 35),
            const Text('Body Metrics (Tap to edit)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMetricCard(context, 'Height', '${provider.height.toStringAsFixed(0)} cm', Icons.height, Colors.teal, () => _showSimpleEdit(context, 'Height', 'cm', provider.height, (v) => provider.updateSpecificMetric(height: v))),
                const SizedBox(width: 16),
                _buildMetricCard(context, 'Weight', '${provider.weight.toStringAsFixed(1)} kg', Icons.monitor_weight, Colors.teal, () => _showSimpleEdit(context, 'Weight', 'kg', provider.weight, (v) => provider.updateSpecificMetric(weight: v))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMetricCard(context, 'BMI', provider.bmi.toStringAsFixed(1), Icons.speed, Colors.purple, null, subText: provider.bmiCategory),
                const SizedBox(width: 16),
                _buildMetricCard(context, 'Maintenance', '${provider.maintenanceCalories}', Icons.local_fire_department, Colors.orange, null, subText: 'kcal / day'),
              ],
            ),
            
            // --- NEW: BMI RECOMMENDATION CARD ---
            if (provider.height > 0 && provider.weight > 0)
              _buildBmiRecommendationCard(context, provider),
              
          ],
        ),
      ),
    );
  }

  void _showSimpleEdit(BuildContext context, String title, String unit, double current, Function(double) onSave) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(suffixText: unit)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            onSave(double.tryParse(controller.text) ?? current);
            Navigator.pop(context);
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, MaterialColor color, VoidCallback? onTap, {String? subText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: color, size: 20), if (onTap != null) Icon(Icons.edit, size: 14, color: Colors.grey.shade400)]),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (subText != null) Text(subText, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW: RECOMMENDATION WIDGET METHOD ---
  Widget _buildBmiRecommendationCard(BuildContext context, WorkoutProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine card color based on category
    Color statusColor;
    IconData statusIcon;
    if (provider.bmiCategory == 'Healthy') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (provider.bmiCategory == 'Obesity') {
      statusColor = Colors.redAccent;
      statusIcon = Icons.warning_amber_rounded;
    } else if (provider.bmiCategory == 'No Data') {
      statusColor = Colors.grey;
      statusIcon = Icons.info_outline;
    } else {
      statusColor = Colors.orange; // For Underweight and Overweight
      statusIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? statusColor.withOpacity(0.1) : statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 10),
              Text(
                'BMI Recommendation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            provider.bmiRecommendation,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}