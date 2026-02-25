import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../workout_provider.dart';
import '../login_signup/login_screen.dart';
import 'package:intl/intl.dart';

// --- 1. MAIN SETTINGS SCREEN ---
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Timer? _backgroundTimer;

  @override
  void initState() {
    super.initState();
    _startBackgroundVerificationCheck();
  }

  @override
  void dispose() {
    _backgroundTimer?.cancel();
    super.dispose();
  }

  void _startBackgroundVerificationCheck() {
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.reload();
        if (user.emailVerified) {
          if (mounted) {
            setState(() {}); 
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Success! Your email has been verified and updated.'),
                backgroundColor: Colors.teal,
              ),
            );
          }
          timer.cancel();
        }
      }
    });
  }

  void _logout(BuildContext context) async {
    context.read<WorkoutProvider>().clearWorkouts();
    await FirebaseAuth.instance.signOut(); 
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen()), 
        (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 35, backgroundColor: Colors.teal, child: Icon(Icons.person, size: 35, color: Colors.white)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.displayName ?? 'Fitness User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      if (user != null && !user.emailVerified)
                        const Text('Pending email verification...', style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildSettingsTile(
            context,
            'Personal Details',
            'Name, Email, Birthday, and Gender',
            Icons.person_outline,
            Colors.teal,
            () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
              if (mounted) {
                setState(() {});
                _startBackgroundVerificationCheck(); 
              }
            },
          ),
          _buildSettingsTile(
            context,
            'Fitness Goals',
            'Targets for weight, calories, and steps',
            Icons.flag_outlined,
            Colors.blue,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditGoalsScreen())),
          ),
          _buildSettingsTile(
            context,
            'Password & Security',
            'Update your account password',
            Icons.lock_outline,
            Colors.orange,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PasswordSecurityScreen())),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            secondary: Icon(provider.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.deepPurple),
            title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
            value: provider.isDarkMode,
            activeColor: Colors.teal,
            onChanged: (bool value) => provider.toggleTheme(value),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: onTap,
        ),
        const Divider(indent: 50),
      ],
    );
  }
}

// --- 2. EDIT PROFILE SCREEN ---
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstName = TextEditingController();
  final _surname = TextEditingController();
  final _email = TextEditingController();
  DateTime? _birthday;
  String _gender = 'Male'; 
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final p = context.read<WorkoutProvider>();
    _email.text = user?.email ?? '';
    if (user?.displayName != null) {
      List<String> parts = user!.displayName!.split(' ');
      if (parts.length > 1) {
        _firstName.text = parts.sublist(0, parts.length - 1).join(' ');
        _surname.text = parts.last;
      } else {
        _firstName.text = user.displayName!;
      }
    }
    _birthday = p.birthday;
    _gender = p.gender;
  }

  void _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String oldEmail = user.email ?? '';
    String newEmail = _email.text.trim();
    bool isEmailChanging = newEmail != oldEmail && newEmail.isNotEmpty;

    setState(() => _isSaving = true);
    try {
      await context.read<WorkoutProvider>().updateProfileSettings("${_firstName.text.trim()} ${_surname.text.trim()}", _birthday, _gender);
      if (isEmailChanging) {
        await user.verifyBeforeUpdateEmail(newEmail);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification link sent to your email.')));
          Navigator.pop(context); 
        }
      } else {
        await user.reload(); 
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
       setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Details')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          TextField(controller: _firstName, decoration: InputDecoration(labelText: 'First Name', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          TextField(controller: _surname, decoration: InputDecoration(labelText: 'Surname', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          TextField(controller: _email, decoration: InputDecoration(labelText: 'Email Address', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context, initialDate: _birthday ?? DateTime(2000, 1, 1), firstDate: DateTime(1900), lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.teal, onPrimary: Colors.white, surface: Colors.white, onSurface: Colors.black)),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _birthday = picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(labelText: 'Birthday', prefixIcon: const Icon(Icons.cake), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(_birthday == null ? 'Select Date' : DateFormat('MMMM d, yyyy').format(_birthday!)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: InputDecoration(labelText: 'Gender', prefixIcon: const Icon(Icons.wc), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: ['Male', 'Female'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _gender = v!),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isSaving ? null : _save, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
            child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('SAVE DETAILS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}

// --- 3. EDIT GOALS SCREEN ---
class EditGoalsScreen extends StatefulWidget {
  const EditGoalsScreen({super.key});
  @override
  State<EditGoalsScreen> createState() => _EditGoalsScreenState();
}

class _EditGoalsScreenState extends State<EditGoalsScreen> {
  final _calGoal = TextEditingController();
  final _intakeGoal = TextEditingController();
  final _targetWeight = TextEditingController();
  final _stepGoal = TextEditingController();
  String _goalType = 'Maintain Weight';

  @override
  void initState() {
    super.initState();
    final p = context.read<WorkoutProvider>();
    _calGoal.text = p.calorieGoal.toString();
    _intakeGoal.text = p.intakeGoal.toString();
    _targetWeight.text = p.targetWeight.toString();
    _stepGoal.text = p.stepGoal.toString();
    _goalType = p.goalType;
  }

  void _saveGoals() async {
    final provider = context.read<WorkoutProvider>();
    await provider.updateFitnessGoals(provider.height, provider.weight, int.tryParse(_calGoal.text) ?? provider.calorieGoal, int.tryParse(_intakeGoal.text) ?? provider.intakeGoal, double.tryParse(_targetWeight.text) ?? provider.targetWeight, _goalType, int.tryParse(_stepGoal.text) ?? provider.stepGoal);
    if (mounted) Navigator.pop(context);
  }

  // Helper to build headers for activities
  Widget _buildSectionHeader(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fitness Goals')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('Current Strategy', Icons.track_changes, Colors.teal),
          DropdownButtonFormField<String>(
            value: _goalType, 
            decoration: const InputDecoration(border: OutlineInputBorder()), 
            items: ['Lose Weight', 'Maintain Weight', 'Gain Weight'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), 
            onChanged: (v) => setState(() => _goalType = v!)
          ),
          
          _buildSectionHeader('Weight Target', Icons.monitor_weight, Colors.blue),
          TextField(controller: _targetWeight, decoration: const InputDecoration(labelText: 'Target Weight (kg)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          
          _buildSectionHeader('Daily Nutrition', Icons.restaurant, Colors.orange),
          TextField(controller: _intakeGoal, decoration: const InputDecoration(labelText: 'Intake Goal (kcal)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          
          _buildSectionHeader('Exercise Goal', Icons.local_fire_department, Colors.red),
          TextField(controller: _calGoal, decoration: const InputDecoration(labelText: 'Burn Goal (kcal)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          
          _buildSectionHeader('Activity Target', Icons.directions_walk, Colors.purple),
          TextField(controller: _stepGoal, decoration: const InputDecoration(labelText: 'Step Goal', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
            onPressed: _saveGoals, 
            child: const Text('SAVE GOALS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }
}

// --- 4. PASSWORD & SECURITY SCREEN ---
class PasswordSecurityScreen extends StatefulWidget {
  const PasswordSecurityScreen({super.key});
  @override
  State<PasswordSecurityScreen> createState() => _PasswordSecurityScreenState();
}

class _PasswordSecurityScreenState extends State<PasswordSecurityScreen> {
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscurePassword = true;
  bool _isUpdating = false;

  void _updatePassword() async {
    if (_passController.text.length < 6) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Min 6 characters'))); return; }
    if (_passController.text != _confirmPassController.text) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mismatch'))); return; }
    setState(() => _isUpdating = true);
    try {
      await FirebaseAuth.instance.currentUser?.updatePassword(_passController.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
    finally { if (mounted) setState(() => _isUpdating = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(controller: _passController, obscureText: _obscurePassword, decoration: InputDecoration(labelText: 'New Password', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)))),
          const SizedBox(height: 16),
          TextField(controller: _confirmPassController, obscureText: _obscurePassword, decoration: InputDecoration(labelText: 'Confirm Password', prefixIcon: const Icon(Icons.lock_reset), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 40),
          ElevatedButton(onPressed: _isUpdating ? null : _updatePassword, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isUpdating ? const CircularProgressIndicator(color: Colors.white) : const Text('UPDATE PASSWORD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}