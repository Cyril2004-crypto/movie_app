import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;
    final ok = await context.read<AuthProvider>().loginWithPassword(username, password);
    setState(() => _submitting = false);

    if (ok) {
      if (mounted) Navigator.pop(context);
      return;
    }

    // login failed -> show snackbar and offer to register
    if (mounted) {
      final register = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Not found or wrong password'),
          content: const Text('No account found or wrong password. Create an account with these credentials?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Create')),
          ],
        ),
      );
      if (register == true) {
        setState(() => _submitting = true);
        final created = await context.read<AuthProvider>().register(username, password);
        setState(() => _submitting = false);
        if (created && mounted) Navigator.pop(context);
        if (!created && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not create account (already exists)')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting ? const CircularProgressIndicator() : const Text('Continue'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // social buttons (existing)
            OutlinedButton.icon(
              icon: const Icon(Icons.email, size: 20),
              label: const Text('Continue with Google'),
              onPressed: _submitting
                  ? null
                  : () async {
                      setState(() => _submitting = true);
                      final ok = await context.read<AuthProvider>().signInWithGoogle();
                      setState(() => _submitting = false);
                      if (ok && mounted) Navigator.pop(context);
                    },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.apple, size: 20),
              label: const Text('Continue with Apple'),
              onPressed: _submitting
                  ? null
                  : () async {
                      setState(() => _submitting = true);
                      final ok = await context.read<AuthProvider>().signInWithApple();
                      setState(() => _submitting = false);
                      if (ok && mounted) Navigator.pop(context);
                    },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.facebook, size: 20),
              label: const Text('Continue with Facebook'),
              onPressed: _submitting
                  ? null
                  : () async {
                      setState(() => _submitting = true);
                      final ok = await context.read<AuthProvider>().signInWithFacebook();
                      setState(() => _submitting = false);
                      if (ok && mounted) Navigator.pop(context);
                    },
            ),
          ],
        ),
      ),
    );
  }
}