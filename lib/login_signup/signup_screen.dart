import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// =============================================================================
// DESIGN TOKENS (mirrors profile_screen.dart and all other screens)
// =============================================================================

class _AppColors {
  static const teal = Color(0xFF00897B);
  static const tealDark = Color(0xFF00695C);
  static const tealLight = Color(0xFFE0F2F1);
  static const orange = Color(0xFFFB8C00);
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
// SIGN UP SCREEN
// =============================================================================

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthdayController = TextEditingController();

  DateTime? _selectedBirthday;
  String? _selectedGender;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthdayController.dispose();
    super.dispose();
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

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _selectBirthday(BuildContext context) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Colors.tealAccent,
                    onPrimary: Colors.black,
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                    secondary: Colors.tealAccent,
                  )
                : const ColorScheme.light(
                    primary: _AppColors.teal,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    isDark ? Colors.tealAccent : _AppColors.teal,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
        _birthdayController.text =
            DateFormat('MMMM d, yyyy').format(picked);
      });
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBirthday == null || _selectedGender == null) {
      final String message = _selectedBirthday == null
          ? 'Please select your birthday'
          : 'Please select your gender';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        final String fullName =
            '${_firstNameController.text.trim()} ${_surnameController.text.trim()}';
        await userCredential.user!.updateDisplayName(fullName);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'fullName': fullName,
          'firstName': _firstNameController.text.trim(),
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
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Account created! Please check your email to verify.'),
                  ),
                ],
              ),
              backgroundColor: _AppColors.teal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Sign up failed'),
          backgroundColor: _AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Component builders ────────────────────────────────────────────────────

  Widget _buildGenderRow(bool isDark) {
    return Row(
      children: [
        _buildGenderOption('Female', isDark),
        const SizedBox(width: _AppSpacing.sm),
        _buildGenderOption('Male', isDark),
      ],
    );
  }

  Widget _buildGenderOption(String title, bool isDark) {
    final bool isSelected = _selectedGender == title;
    const Color activeColor = _AppColors.teal;
    final Color fillColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          padding: const EdgeInsets.symmetric(
              horizontal: _AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isSelected
                ? activeColor.withOpacity(0.08)
                : fillColor,
            border: Border.all(
              color: isSelected
                  ? activeColor.withOpacity(0.4)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isSelected
                      ? activeColor
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              Radio<String>(
                value: title,
                groupValue: _selectedGender,
                onChanged: (val) =>
                    setState(() => _selectedGender = val),
                activeColor: activeColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    required Color fillColor,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: _AppSpacing.md, vertical: 16),
      suffixIcon: suffix,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F3F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: _AppSpacing.lg, vertical: _AppSpacing.sm),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Logo ────────────────────────────────────────────────
              _smoothEntry(
                index: 0,
                child: Center(
                  child: Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_AppColors.teal, _AppColors.tealDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _AppColors.teal.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: _AppSpacing.lg),

              // ── Header ───────────────────────────────────────────────
              _smoothEntry(
                index: 1,
                child: Column(
                  children: [
                    Text(
                      'Join Us',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: _AppSpacing.xs),
                    Text(
                      'Create an account to start tracking',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: _AppSpacing.xl),

              // ── Name row ─────────────────────────────────────────────
              _smoothEntry(
                index: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: _fieldDecoration(
                          label: 'First Name',
                          icon: Icons.person_outline_rounded,
                          fillColor: fillColor,
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: _AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _surnameController,
                        decoration: InputDecoration(
                          labelText: 'Surname',
                          filled: true,
                          fillColor: fillColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: _AppSpacing.md, vertical: 16),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: _AppSpacing.md),

              // ── Email ────────────────────────────────────────────────
              _smoothEntry(
                index: 3,
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fieldDecoration(
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    fillColor: fillColor,
                  ),
                  validator: (v) =>
                      v!.contains('@') ? null : 'Enter a valid email',
                ),
              ),

              const SizedBox(height: _AppSpacing.md),

              // ── Birthday ─────────────────────────────────────────────
              _smoothEntry(
                index: 4,
                child: TextFormField(
                  controller: _birthdayController,
                  readOnly: true,
                  onTap: () => _selectBirthday(context),
                  decoration: _fieldDecoration(
                    label: 'Birthday',
                    icon: Icons.cake_outlined,
                    fillColor: fillColor,
                  ),
                ),
              ),

              const SizedBox(height: _AppSpacing.md),

              // ── Gender ───────────────────────────────────────────────
              _smoothEntry(
                index: 5,
                child: _buildGenderRow(isDark),
              ),

              const SizedBox(height: _AppSpacing.md),

              // ── Password ─────────────────────────────────────────────
              _smoothEntry(
                index: 6,
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _fieldDecoration(
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    fillColor: fillColor,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 20,
                        color: Colors.grey.shade500,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v!.length < 6 ? 'Minimum 6 characters' : null,
                ),
              ),

              const SizedBox(height: _AppSpacing.xxl),

              // ── Sign up button ────────────────────────────────────────
              _smoothEntry(
                index: 7,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _AppColors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: _AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}