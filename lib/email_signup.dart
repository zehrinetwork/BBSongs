
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// A single stateful widget for handling both Sign In and Sign Up
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Controllers to grab the text entered in the input fields
  final _nameController = TextEditingController(); // Only needed for Sign Up
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State to determine if we are currently signing in or signing up
  bool _isSigningIn = true; // Start by showing the Sign In form

  // A little helper to show a loading spinner when we're processing
  bool _isLoading = false;

  // --- Sign Up Logic ---
  Future<void> _signUp() async {
    // Set loading to true to show the spinner and disable the button
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the values from our text fields
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();
      final String displayName = _nameController.text.trim(); // Get the name for display

      // Basic validation: check if fields are empty for sign up
      if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
        if (!mounted) return; // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields for Sign Up')),
        );
        return; // Stop here if validation fails
      }

      // Call Firebase Authentication to create the user!
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return; // Check after async call

      // Now we update the user's display name.
      await userCredential.user!.updateDisplayName(displayName);

      if (!mounted) return; // Check after async call

      // Yay! User created and name set. You could navigate to a home screen here.
      // Example: Navigator.pushReplacementNamed(context, '/home');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully! Welcome!')),
      );

      // Optionally, switch back to sign-in after successful sign up
      // setState(() { _isSigningIn = true; });

    } on FirebaseAuthException catch (e) {
      if (!mounted) return; // Check before using context
      String message = 'An error occurred during sign up.';
      if (e.code == 'weak-password') {
        message = 'Oops! The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Looks like that email is already in use. Try signing in!';
        // Maybe automatically switch to sign in form?
        // setState(() { _isSigningIn = true; });
      } else if (e.code == 'invalid-email') {
        message = 'Hmm, that email address doesn\'t look quite right.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      print('FirebaseAuthException during Sign Up: ${e.code} - ${e.message}');

    } catch (e) {
      if (!mounted) return; // Check before using context
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred. Please try again.')),
      );
      print('Unexpected error during Sign Up: $e');
    } finally {
      if (!mounted) return; // Check before setState
      // Make sure to turn off the loading spinner
      setState(() {
        _isLoading = false;
      });
      // Clear password field for security (optional but good practice)
      _passwordController.clear();
    }
  }

  // --- Sign In Logic ---
  Future<void> _signIn() async {
    // Set loading to true
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the values from our text fields
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      // Basic validation: check if fields are empty for sign in
      if (email.isEmpty || password.isEmpty) {
        if (!mounted) return; // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email and password for Sign In')),
        );
        return; // Stop here if validation fails
      }

      // Call Firebase Authentication to sign the user in!
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If the above line completes without throwing an exception,
      // the user is successfully signed in! Firebase Auth handles the session.

      if (!mounted) return; // Check after async call

      // Show success message (optional, often you just navigate)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in successfully!')),
      );

      // You would typically navigate to your main app screen here.
      // Example: Navigator.pushReplacementNamed(context, '/home');


    } on FirebaseAuthException catch (e) {
      if (!mounted) return; // Check before using context
      String message = 'An error occurred during sign in.';
      if (e.code == 'user-not-found') {
        message = 'Hmm, no user found with that email. Maybe sign up?';
      } else if (e.code == 'wrong-password') {
        message = 'Oops! Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        message = 'Hmm, that email address doesn\'t look quite right.';
      } else if (e.code == 'user-disabled') {
        message = 'This user account has been disabled.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      print('FirebaseAuthException during Sign In: ${e.code} - ${e.message}');

    } catch (e) {
      if (!mounted) return; // Check before using context
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred. Please try again.')),
      );
      print('Unexpected error during Sign In: $e');
    } finally {
      if (!mounted) return; // Check before setState
      // Make sure to turn off the loading spinner
      setState(() {
        _isLoading = false;
      });
      // Clear password field for security (optional but good practice)
      _passwordController.clear();
    }
  }

  // Clean up the controllers when the widget is removed
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to toggle between Sign In and Sign Up forms
  void _toggleAuthMode() {
    setState(() {
      _isSigningIn = !_isSigningIn;
      // Clear fields when switching forms for a cleaner experience
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine button text and toggle link text based on current mode
    final String buttonText = _isSigningIn ? 'Sign In' : 'Sign Up';
    final String toggleLinkText = _isSigningIn
        ? 'Don\'t have an account? Sign Up'
        : 'Already have an account? Sign In';
    final Function authAction = _isSigningIn ? _signIn : _signUp; // Choose the correct function

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSigningIn ? 'Sign In' : 'Sign Up'), // AppBar title reflects the mode
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center( // Center the content vertically
          child: SingleChildScrollView( // Allows scrolling if content overflows
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch fields horizontally
              children: <Widget>[
                // Name Input Field (only shown during Sign Up)
                if (!_isSigningIn) ...[ // Use the spread operator (...) to conditionally include widgets
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                ],
                // Email Input Field
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Password Input Field
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true, // Hides the password text
                ),
                const SizedBox(height: 24),
                // Action Button (Sign In or Sign Up)
                _isLoading
                    ? const Center(child: CircularProgressIndicator()) // Center spinner when loading
                    : ElevatedButton(
                  // CORRECTED LINE: Wrap the async call in a synchronous lambda
                  onPressed: _isLoading ? null : () {
                    authAction(); // Call the async function here
                  },
                  child: Text(buttonText),
                ),
                const SizedBox(height: 16),
                // Toggle Link (Switch between Sign In and Sign Up)
                TextButton(
                  // This is correct because _toggleAuthMode is synchronous
                  onPressed: _toggleAuthMode,
                  child: Text(toggleLinkText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



}
