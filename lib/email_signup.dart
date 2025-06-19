import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'music_screen.dart';

/// A single screen that handles both **Sign‑Up** and **Sign‑In** flows.
/// * After a successful **Sign‑Up** the user is shown the **Sign‑In** form so
///   they can log in straight away.
/// * After a successful **Sign‑In** we navigate to `MusicScreen`.
/// * If the user is already authenticated (`initState`) we skip the auth flow
///   entirely.
class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  // ---------------------------------------------------------------------------
  // Controllers & State
  // ---------------------------------------------------------------------------
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showSignIn = false; // toggles between sign‑up & sign‑in forms
  bool _isLoading = false; // shows a progress indicator when true

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    // Jump straight to the music UI if already signed in.
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToMusicUI());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.1, 0.9],
            colors: [Color(0xFF283048), Color(0xFF859398)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 12,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showSignIn ? 'Sign In' : 'Create Account',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      if (!_showSignIn) _buildNameField(),
                      _buildEmailField(),
                      _buildPasswordField(),
                      const SizedBox(height: 24),
                      // Primary action button or spinner
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showSignIn
                              ? _handleSignIn
                              : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _showSignIn ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Switch form link
                      TextButton(
                        onPressed: () {
                          setState(() => _showSignIn = !_showSignIn);
                        },
                        child: Text(
                          _showSignIn
                              ? "Don't have an account? Sign Up"
                              : 'Already have an account? Sign In',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Form Fields
  // ---------------------------------------------------------------------------
  Widget _buildNameField() => TextFormField(
    controller: _nameController,
    decoration: const InputDecoration(
      labelText: 'Name',
      border: OutlineInputBorder(),
    ),
    validator: (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Name is required';
      }
      if (value.trim().length < 3) {
        return 'Name must be at least 3 characters';
      }
      return null;
    },
  );

  Widget _buildEmailField() => TextFormField(
    controller: _emailController,
    decoration: const InputDecoration(
      labelText: 'Email',
      border: OutlineInputBorder(),
    ),
    keyboardType: TextInputType.emailAddress,
    validator: (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Email is required';
      }
      // Very simple check: must contain "@" and ".".
      if (!value.contains('@') || !value.contains('.')) {
        return 'Enter a valid email';
      }
      return null;
    },
  );

  Widget _buildPasswordField() => TextFormField(
    controller: _passwordController,
    decoration: const InputDecoration(
      labelText: 'Password',
      border: OutlineInputBorder(),
    ),
    obscureText: true,
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Password is required';
      }
      if (value.length < 6) {
        return 'Password must be at least 6 characters';
      }
      return null;
    },
  );

  // ---------------------------------------------------------------------------
  // Auth Handlers
  // ---------------------------------------------------------------------------
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Ensure name uniqueness first.
      final nameSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: _nameController.text.trim())
          .limit(1)
          .get();
      if (nameSnapshot.docs.isNotEmpty) {
        _showSnack('Name already taken');
        return; // `finally` will switch the spinner off.
      }

      // 2️⃣ Create user in FirebaseAuth.
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 3️⃣ Save the display name in Firestore (for greeting, etc.).
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({'name': _nameController.text.trim()});

      // 4️⃣ Let the user know and switch to Sign‑In mode **without touching the
      // spinner**. The `finally` block will turn it off for us.
      if (!mounted) return;
      setState(() => _showSignIn = true);
      _formKey.currentState!.reset(); // clear the fields so they can sign in.
      _showSnack('Account created! Please sign in.');
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Sign‑up failed');
    } catch (e) {
      _showSnack('Something went wrong, please try again');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      _goToMusicUI();
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Sign‑in failed');
    } catch (e) {
      _showSnack('Something went wrong, please try again');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToMusicUI() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MusicScreen()),
    );
  }
}
