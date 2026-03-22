import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../workout_provider.dart';
import '../login_signup/login_screen.dart';
import 'package:intl/intl.dart';

// =============================================================================
// DESIGN TOKENS
// =============================================================================

class _AppColors {
  static const teal = Color(0xFF00897B);
  static const tealLight = Color(0xFFE0F2F1);
  static const tealDark = Color(0xFF00695C);

  static const blue = Color(0xFF1E88E5);
  static const blueLight = Color(0xFFE3F2FD);

  static const orange = Color(0xFFFB8C00);
  static const orangeLight = Color(0xFFFFF3E0);

  static const red = Color(0xFFE53935);
  static const redLight = Color(0xFFFFEBEE);

  static const purple = Color(0xFF8E24AA);
  static const purpleLight = Color(0xFFF3E5F5);

  static const success = Color(0xFF43A047);
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
// 1. MAIN SETTINGS SCREEN
// =============================================================================

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

  void _startBackgroundVerificationCheck() {
    _backgroundTimer?.cancel();
    _backgroundTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.reload();
        if (user.emailVerified) {
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text('Email verified successfully!'),
                  ],
                ),
                backgroundColor: _AppColors.teal,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
        (route) => false,
      );
    }
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 4, bottom: _AppSpacing.sm, top: _AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 16 : 6),
      topRight: Radius.circular(isFirst ? 16 : 6),
      bottomLeft: Radius.circular(isLast ? 16 : 6),
      bottomRight: Radius.circular(isLast ? 16 : 6),
    );

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: _AppSpacing.md, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: _AppSpacing.lg, vertical: _AppSpacing.md),
        children: [
          // ── Profile Header ──────────────────────────────────────────
          _smoothEntry(
            index: 0,
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
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_AppColors.teal, _AppColors.tealDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _AppColors.teal.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_rounded,
                            size: 32, color: Colors.white),
                      ),
                      if (user != null && user.emailVerified)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Theme.of(context).cardColor, width: 2),
                            ),
                            child: const Icon(Icons.check,
                                size: 10, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: _AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Fitness User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (user != null && !user.emailVerified) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: _AppSpacing.sm, vertical: 3),
                            decoration: BoxDecoration(
                              color: _AppColors.orangeLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: _AppColors.orange, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Email not verified',
                                  style: TextStyle(
                                    color: _AppColors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: _AppSpacing.xl),

          // ── Account Section ─────────────────────────────────────────
          _smoothEntry(index: 1, child: _buildSectionLabel('Account')),
          _smoothEntry(
            index: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ],
              ),
              child: Column(
                children: [
                  _buildNavTile(
                    context: context,
                    title: 'Personal Details',
                    subtitle: 'Name, email, and birthday',
                    icon: Icons.person_outline_rounded,
                    color: _AppColors.teal,
                    isFirst: true,
                    onTap: () async {
                      await Navigator.push(
                          context,
                          _smoothPageRoute(
                              const EditProfileScreen()));
                      if (mounted) {
                        setState(() {});
                        _startBackgroundVerificationCheck();
                      }
                    },
                  ),
                  _buildNavTile(
                    context: context,
                    title: 'Fitness Goals',
                    subtitle: 'Weight and activity targets',
                    icon: Icons.flag_rounded,
                    color: _AppColors.blue,
                    onTap: () => Navigator.push(
                        context,
                        _smoothPageRoute(
                            const EditGoalsScreen())),
                  ),
                  _buildNavTile(
                    context: context,
                    title: 'Security',
                    subtitle: 'Update your account password',
                    icon: Icons.lock_outline_rounded,
                    color: _AppColors.orange,
                    isLast: true,
                    onTap: () => Navigator.push(
                        context,
                        _smoothPageRoute(
                            const PasswordSecurityScreen())),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: _AppSpacing.xl),

          // ── Preferences Section ──────────────────────────────────────
          _smoothEntry(index: 3, child: _buildSectionLabel('Preferences')),
          _smoothEntry(
            index: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ],
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: _AppSpacing.md, vertical: 6),
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple
                        .withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    provider.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Dark Mode',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                value: provider.isDarkMode,
                activeColor: _AppColors.teal,
                onChanged: (bool value) => provider.toggleTheme(value),
              ),
            ),
          ),

          const SizedBox(height: _AppSpacing.xxl),

          // ── Logout ───────────────────────────────────────────────────
          _smoothEntry(
            index: 5,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text(
                  'Log Out',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _AppColors.red,
                  side: BorderSide(
                      color: _AppColors.red.withOpacity(0.4), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. EDIT PROFILE SCREEN
// =============================================================================

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
  bool _canResendEmail = true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final p = context.read<WorkoutProvider>();
    _email.text =
        (p.email ?? '').isNotEmpty ? p.email : (user?.email ?? '');
    _email.addListener(() => setState(() {}));

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

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Widget _smoothEntry({required Widget child, required int index}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + index * 50),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child:
            Transform.translate(offset: Offset(0, 18 * (1 - value)), child: child),
      ),
      child: child,
    );
  }

  Future<void> _resendVerification(User user) async {
    try {
      await user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification email sent!'),
            backgroundColor: _AppColors.teal,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() => _canResendEmail = false);
      }
      await Future.delayed(const Duration(seconds: 30));
      if (mounted) setState(() => _canResendEmail = true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<bool> _reauthenticate(User user) async {
    final passwordController = TextEditingController();
    bool success = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Identity',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your password to continue with this change.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: _AppSpacing.md),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  filled: true,
                  fillColor: isDark
                      ? Colors.grey.shade900
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
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
              onPressed: () async {
                try {
                  AuthCredential credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: passwordController.text.trim(),
                  );
                  await user.reauthenticateWithCredential(credential);
                  success = true;
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incorrect password. Please try again.'),
                      backgroundColor: _AppColors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    return success;
  }

  void _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final newEmail = _email.text.trim();
    setState(() => _isSaving = true);
    try {
      if (newEmail != user.email) {
        try {
          await user.verifyBeforeUpdateEmail(newEmail);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Verification sent to new address!'),
              backgroundColor: _AppColors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            bool reauthed = await _reauthenticate(user);
            if (reauthed) {
              await user.verifyBeforeUpdateEmail(newEmail);
            } else {
              setState(() => _isSaving = false);
              return;
            }
          } else {
            rethrow;
          }
        }
      }
      await context.read<WorkoutProvider>().updateProfileSettings(
            "${_firstName.text.trim()} ${_surname.text.trim()}",
            _birthday,
            _gender,
            newEmail,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: _AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData? icon,
    Color fill, {
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: _AppSpacing.md, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;

    final bool isSavedEmail =
        _email.text.trim() == provider.email;
    final bool isVerified = (user != null &&
        _email.text.trim() == user.email &&
        user.emailVerified);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text('Personal Details',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(_AppSpacing.lg),
        children: [
          // ── Name Row ────────────────────────────────────────────────
          _smoothEntry(
            index: 0,
            child: Row(
              children: [
                Expanded(
                    child: _buildField(
                        'First Name', _firstName,
                        Icons.person_outline_rounded, fillColor)),
                const SizedBox(width: _AppSpacing.sm),
                Expanded(
                    child:
                        _buildField('Surname', _surname, null, fillColor)),
              ],
            ),
          ),

          const SizedBox(height: _AppSpacing.md),

          // ── Email ────────────────────────────────────────────────────
          _smoothEntry(
            index: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _email,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: _AppSpacing.md, vertical: 16),
                    suffixIcon: isSavedEmail
                        ? (isVerified
                            ? const Icon(Icons.check_circle_rounded,
                                color: _AppColors.success, size: 20)
                            : const Icon(Icons.error_outline_rounded,
                                color: _AppColors.orange, size: 20))
                        : null,
                  ),
                ),
                if (isSavedEmail && !isVerified) ...[
                  const SizedBox(height: _AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: _AppSpacing.md, vertical: 10),
                    decoration: BoxDecoration(
                      color: _AppColors.orangeLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: _AppColors.orange, size: 16),
                        const SizedBox(width: _AppSpacing.sm),
                        const Expanded(
                          child: Text(
                            'Email not verified',
                            style: TextStyle(
                              color: _AppColors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _canResendEmail
                              ? () => _resendVerification(
                                  FirebaseAuth.instance.currentUser!)
                              : null,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: _AppSpacing.sm),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _canResendEmail ? 'Resend' : 'Wait...',
                            style: TextStyle(
                              color: _canResendEmail
                                  ? _AppColors.blue
                                  : Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: _AppSpacing.md),

          // ── Birthday ─────────────────────────────────────────────────
          _smoothEntry(
            index: 2,
            child: InkWell(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _birthday ?? DateTime(2000, 1, 1),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: isDark
                            ? const ColorScheme.dark(
                                primary: Colors.tealAccent,
                                surface: Color(0xFF1E1E1E),
                              )
                            : const ColorScheme.light(
                                primary: _AppColors.teal,
                                surface: Colors.white,
                              ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) setState(() => _birthday = picked);
              },
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Birthday',
                  prefixIcon: const Icon(Icons.cake_outlined, size: 20),
                  filled: true,
                  fillColor: fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: _AppSpacing.md, vertical: 16),
                ),
                child: Text(
                  _birthday == null
                      ? 'Select date'
                      : DateFormat('MMMM d, yyyy').format(_birthday!),
                  style: TextStyle(
                    color: _birthday == null
                        ? Colors.grey.shade500
                        : null,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: _AppSpacing.md),

          // ── Gender ───────────────────────────────────────────────────
          _smoothEntry(
            index: 3,
            child: DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(
                labelText: 'Gender',
                prefixIcon: const Icon(Icons.wc_rounded, size: 20),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: _AppSpacing.md, vertical: 16),
              ),
              items: ['Male', 'Female']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v!),
            ),
          ),

          const SizedBox(height: _AppSpacing.xxl),

          // ── Save Button ──────────────────────────────────────────────
          _smoothEntry(
            index: 4,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AppColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Save Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. EDIT GOALS SCREEN
// =============================================================================

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

  Widget _smoothEntry({required Widget child, required int index}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + index * 50),
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

  void _saveGoals() async {
    final provider = context.read<WorkoutProvider>();
    await provider.updateFitnessGoals(
      provider.height,
      provider.weight,
      int.tryParse(_calGoal.text) ?? provider.calorieGoal,
      int.tryParse(_intakeGoal.text) ?? provider.intakeGoal,
      double.tryParse(_targetWeight.text) ?? provider.targetWeight,
      _goalType,
      int.tryParse(_stepGoal.text) ?? provider.stepGoal,
    );
    if (mounted) Navigator.pop(context);
  }

  Widget _buildGoalCard({
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required Color fillColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(_AppSpacing.md),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: _AppSpacing.sm),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: _AppSpacing.sm),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: _AppSpacing.md, vertical: 12),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;
    final cardFill =
        isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text('Fitness Goals',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(_AppSpacing.lg),
        children: [
          // ── Strategy ─────────────────────────────────────────────────
          _smoothEntry(
            index: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                    label: 'Strategy',
                    icon: Icons.track_changes_rounded,
                    color: _AppColors.teal),
                const SizedBox(height: _AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: _goalType,
                  decoration: InputDecoration(
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
                  onChanged: (v) => setState(() => _goalType = v!),
                ),
              ],
            ),
          ),

          const SizedBox(height: _AppSpacing.lg),

          // ── Goals Grid ───────────────────────────────────────────────
          _smoothEntry(
            index: 1,
            child: const _SectionHeader(
                label: 'Targets',
                icon: Icons.adjust_rounded,
                color: _AppColors.blue),
          ),
          const SizedBox(height: _AppSpacing.sm),
          _smoothEntry(
            index: 2,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildGoalCard(
                        label: 'Target Weight',
                        hint: 'kg',
                        icon: Icons.monitor_weight_outlined,
                        color: _AppColors.blue,
                        controller: _targetWeight,
                        fillColor: cardFill,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: _AppSpacing.sm),
                    Expanded(
                      child: _buildGoalCard(
                        label: 'Step Goal',
                        hint: 'steps',
                        icon: Icons.directions_walk_rounded,
                        color: _AppColors.purple,
                        controller: _stepGoal,
                        fillColor: cardFill,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _buildGoalCard(
                        label: 'Intake Goal',
                        hint: 'kcal',
                        icon: Icons.restaurant_rounded,
                        color: _AppColors.orange,
                        controller: _intakeGoal,
                        fillColor: cardFill,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: _AppSpacing.sm),
                    Expanded(
                      child: _buildGoalCard(
                        label: 'Burn Goal',
                        hint: 'kcal',
                        icon: Icons.local_fire_department_rounded,
                        color: _AppColors.red,
                        controller: _calGoal,
                        fillColor: cardFill,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: _AppSpacing.xxl),

          // ── Save Button ──────────────────────────────────────────────
          _smoothEntry(
            index: 3,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveGoals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AppColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Save Goals',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. PASSWORD & SECURITY SCREEN
// =============================================================================

class PasswordSecurityScreen extends StatefulWidget {
  const PasswordSecurityScreen({super.key});

  @override
  State<PasswordSecurityScreen> createState() =>
      _PasswordSecurityScreenState();
}

class _PasswordSecurityScreenState
    extends State<PasswordSecurityScreen> {
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isUpdating = false;

  void _updatePassword() async {
    if (_passController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password must be at least 6 characters.'),
          backgroundColor: _AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (_passController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match.'),
          backgroundColor: _AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _isUpdating = true);
    try {
      await FirebaseAuth.instance.currentUser
          ?.updatePassword(_passController.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
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
        title: const Text('Security',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(_AppSpacing.lg),
        children: [
          // ── Info Banner ──────────────────────────────────────────────
          _smoothEntry(
            index: 0,
            child: Container(
              padding: const EdgeInsets.all(_AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? _AppColors.teal.withOpacity(0.1)
                    : _AppColors.tealLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: _AppColors.teal, size: 20),
                  const SizedBox(width: _AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Use at least 6 characters with a mix of letters and numbers.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _AppColors.tealDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: _AppSpacing.lg),

          // ── New Password ─────────────────────────────────────────────
          _smoothEntry(
            index: 1,
            child: TextField(
              controller: _passController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon:
                    const Icon(Icons.lock_outline_rounded, size: 20),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: _AppSpacing.md, vertical: 16),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ),

          const SizedBox(height: _AppSpacing.md),

          // ── Confirm Password ─────────────────────────────────────────
          _smoothEntry(
            index: 2,
            child: TextField(
              controller: _confirmPassController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon:
                    const Icon(Icons.lock_reset_rounded, size: 20),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: _AppSpacing.md, vertical: 16),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
          ),

          const SizedBox(height: _AppSpacing.xxl),

          // ── Update Button ────────────────────────────────────────────
          _smoothEntry(
            index: 3,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AppColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Update Password',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }
}