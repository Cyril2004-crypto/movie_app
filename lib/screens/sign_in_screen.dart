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
    await context.read<AuthProvider>().signIn(_userCtrl.text.trim(), _passCtrl.text);
    setState(() => _submitting = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _userCtrl, decoration: const InputDecoration(labelText: 'Username'), validator: (v) => (v==null||v.isEmpty)?'Required':null),
              const SizedBox(height: 12),
              TextFormField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: (v) => (v==null||v.isEmpty)?'Required':null),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submitting ? null : _submit, child: _submitting ? const CircularProgressIndicator() : const Text('Sign in')),
            ],
          ),
        ),
      ),
    );
  }
}