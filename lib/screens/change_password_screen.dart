import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cur = TextEditingController();
  final _new = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _cur.dispose();
    _new.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await context.read<AuthProvider>().changePassword(_cur.text, _new.text);
    setState(() => _busy = false);
    if (ok && mounted) Navigator.pop(context);
    if (!ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to change password')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(controller: _cur, decoration: const InputDecoration(labelText: 'Current password'), obscureText: true, validator: (v)=> v==null||v.isEmpty? 'Required':null),
            const SizedBox(height: 12),
            TextFormField(controller: _new, decoration: const InputDecoration(labelText: 'New password'), obscureText: true, validator: (v)=> v==null||v.length<6? 'Min 6 chars':null),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _busy ? null : _submit, child: _busy ? const CircularProgressIndicator() : const Text('Change password')),
          ]),
        ),
      ),
    );
  }
}