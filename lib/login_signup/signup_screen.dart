import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'verify_email_screen.dart'; 

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // --- UPDATED: Separated name controllers ---
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthdayController = TextEditingController(); 
  
  DateTime? _selectedBirthday; 
  String? _selectedGender; 
  bool _isLoading = false;
  bool _obscurePassword = true;

Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1), 
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,        // Header background color
              onPrimary: Colors.white,     // Header text color (selected date)
              surface: Colors.white,       // Dialog background
              onSurface: Colors.black,     // Body text & calendar dates
            ),
            // --- UPDATED THEME DATA ---
            datePickerTheme: const DatePickerThemeData(
              headerBackgroundColor: Colors.teal, // Forces the header background to Teal
              headerForegroundColor: Colors.white, // Forces the header text to White
              backgroundColor: Colors.white,       // Dialog container background
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black), 
              titleMedium: TextStyle(color: Colors.black), 
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              labelStyle: TextStyle(color: Colors.teal),
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.teal)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
        _birthdayController.text = DateFormat('MMMM d, yyyy').format(picked);
      });
    }
}

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBirthday == null || _selectedGender == null) {
      String message = _selectedBirthday == null ? 'Please select your birthday' : 'Please select your gender';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.orange.shade800));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        // --- UPDATED: Combine names for Firebase Display Name ---
        String fullName = '${_firstNameController.text.trim()} ${_surnameController.text.trim()}';
        await userCredential.user!.updateDisplayName(fullName);

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'fullName': fullName,
          'firstName': _firstNameController.text.trim(), // Save separately for easier access
          'surname': _surnameController.text.trim(),
          'email': _emailController.text.trim(),
          'birthday': Timestamp.fromDate(_selectedBirthday!), 
          'gender': _selectedGender, 
          'height': 0.0,
          'weight': 0.0,
          'calorieGoal': 500,
          'intakeGoal': 2000,
          'targetWeight': 0.0,
          'goalType': 'Maintain Weight',
          'stepGoal': 10000,
          'dailySteps': 0,
          'isDarkMode': false,
        });

        await userCredential.user!.sendEmailVerification();
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const VerifyEmailScreen()));
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Sign up failed')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Widget _buildGenderOption(String title, bool isDark) {
    bool isSelected = _selectedGender == title;
    Color activeColor = isDark ? Colors.tealAccent : Colors.teal;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedGender = title),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? activeColor : Colors.grey.shade400, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? activeColor.withOpacity(0.05) : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              Radio<String>(
                value: title,
                groupValue: _selectedGender,
                onChanged: (val) => setState(() => _selectedGender = val),
                activeColor: activeColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        foregroundColor: isDark ? Colors.tealAccent : Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.fitness_center, size: 60, color: isDark ? Colors.tealAccent : Colors.teal),
              const SizedBox(height: 32),
              
              // --- UPDATED: FIRST NAME & SURNAME ROW ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First Name', 
                        prefixIcon: const Icon(Icons.person_outline), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _surnameController,
                      decoration: InputDecoration(
                        labelText: 'Surname', 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.contains('@') ? null : 'Enter a valid email',
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _birthdayController,
                readOnly: true, 
                onTap: () => _selectBirthday(context),
                decoration: InputDecoration(labelText: 'Birthday', prefixIcon: const Icon(Icons.cake_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildGenderOption('Female', isDark),
                  const SizedBox(width: 12),
                  _buildGenderOption('Male', isDark),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                ),
                validator: (v) => v!.length < 6 ? 'Minimum 6 characters' : null,
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SIGN UP', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}