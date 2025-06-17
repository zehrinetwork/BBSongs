import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Make sure AuthViewModel is provided higher up the tree. If not, provide
    // it locally for this screen only.
    return ChangeNotifierProvider<AuthViewModel>(
      create: (_) => AuthViewModel(),
      builder: (context, _) {
        final vm = context.watch<AuthViewModel>();

        return Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Create Account',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Name -------------------------------------------------
                      _AuthTextField(
                        controller: vm.nameController,
                        label: 'Name (unique)',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 24),

                      // Email ------------------------------------------------
                      _AuthTextField(
                        controller: vm.emailController,
                        label: 'Email',
                        icon: Icons.alternate_email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 24),

                      // Password --------------------------------------------
                      _AuthTextField(
                        controller: vm.passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 40),

                      // Sign‑Up button --------------------------------------
                      FilledButton(
                        onPressed: vm.isLoading ? null : () => vm.register(context),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          textStyle: Theme.of(context).textTheme.titleMedium,
                        ),
                        child: const Text('Sign Up'),
                      ),
                      const SizedBox(height: 24),

                      // Sign‑In link ----------------------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/signin');
                            },
                            child: const Text('Sign In'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading overlay -----------------------------------------------
            if (vm.isLoading)
              Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable Auth TextField
// ---------------------------------------------------------------------------
class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        filled: true,
        fillColor: Colors.white10,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel (ChangeNotifier) -------------------------------------------------
// ---------------------------------------------------------------------------
class AuthViewModel extends ChangeNotifier {
  // Controllers --------------------------------------------------------------
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // State --------------------------------------------------------------------
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Registration -------------------------------------------------------------
  Future<void> register(BuildContext context) async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage(context, 'All fields are required.');
      return;
    }

    _setLoading(true);

    try {
      // Check if name is unique
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: name)
          .get();
      if (existing.docs.isNotEmpty) {
        _setLoading(false);  // ✅ stop spinner
        _showMessage(context, 'That name is already taken.');
        return;
      }

      // Create Firebase Auth user
      final creds = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(creds.user!.uid)
          .set({
        'uid': creds.user!.uid,
        'name': name,
        'email': email,
        'createdAt': Timestamp.now(),
      });

      // Success — show confirmation
      if (context.mounted) {
        _setLoading(false);  // ✅ stop spinner before snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, $name')),
        );
      }
    } on FirebaseAuthException catch (e) {
      _setLoading(false);  // ✅ stop spinner
      _showMessage(context, e.message ?? 'Registration failed.');
    } catch (e) {
      _setLoading(false);  // ✅ stop spinner
      _showMessage(context, 'Something went wrong. Please try again.');
    }
  }



  // Utilities ----------------------------------------------------------------
  void _showMessage(BuildContext context, String msg) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Message'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }







  // Dispose ------------------------------------------------------------------
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
