import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  Timer? timer;
  bool canResendEmail = true;

  @override
  void initState() {
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      timer = Timer.periodic(
        const Duration(seconds: 3), 
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload(); // Refresh the cached user state

    if (mounted) {
      setState(() {
        isEmailVerified = user?.emailVerified ?? false;
      });
    }

    if (isEmailVerified) {
      // --- THE FIX: Stop the loop immediately ---
      timer?.cancel();
      if (mounted) {
        Navigator.of(context).pop(); // Go back to Personal Details
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully!'), backgroundColor: Colors.teal),
        );
      }
    }
  }

  Future sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      setState(() => canResendEmail = false);
      await Future.delayed(const Duration(seconds: 10)); // Cooldown
      if (mounted) setState(() => canResendEmail = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.teal),
            const SizedBox(height: 24),
            const Text('A verification link was sent to your email.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Please check your inbox and click the link. We are waiting for you!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.teal),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: canResendEmail ? sendVerificationEmail : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Resend Email', style: TextStyle(color: Colors.white)),
              ),
            ),
            TextButton(
              onPressed: () {
                timer?.cancel();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel / Fix Email', style: TextStyle(color: Colors.teal)),
            ),
          ],
        ),
      ),
    );
  }
}