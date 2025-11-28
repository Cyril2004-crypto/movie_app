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

    final reason = await context.read<AuthProvider>().changePasswordWithReason(_cur.text, _new.text);

    setState(() => _busy = false);

    if (reason == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    // If reason says no stored credentials, offer creation of local password
    if (reason.toLowerCase().contains('no stored credentials') || reason.toLowerCase().contains('managed by')) {
      final create = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('No local password found'),
          content: const Text('This account does not have a local password. Create one now?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Create')),
          ],
        ),
      );

      if (create == true) {
        // create local password using the "new password" field
        setState(() => _busy = true);
        final createReason = await context.read<AuthProvider>().createLocalPasswordForCurrentUser(_new.text);
        setState(() => _busy = false);
        if (createReason == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local password created. You can now change it.')));
            Navigator.pop(context);
          }
          return;
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create local password: $createReason')));
          return;
        }
      }
    }

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to change password: $reason')));
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