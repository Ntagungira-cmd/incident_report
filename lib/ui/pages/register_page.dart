import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth_bloc.dart';
import '../validators.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _department = TextEditingController();
  final _location = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _department, _location, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      RegisterRequested(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        department: _department.text.trim(),
        location: _location.text.trim(),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon,
    FormFieldValidator<String> validator, {
    TextInputType? keyboard,
    bool obscure = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      keyboardType: keyboard,
      obscureText: obscure,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final busy = context.select((AuthBloc b) => b.state.busy);
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field(
                      _name,
                      'Full name',
                      Icons.person_outline,
                      requiredField('Name', min: 2),
                    ),
                    _field(
                      _department,
                      'Department',
                      Icons.school_outlined,
                      requiredField('Department'),
                    ),
                    _field(
                      _location,
                      'Location',
                      Icons.location_on_outlined,
                      requiredField('Location'),
                    ),
                    _field(
                      _email,
                      'Email',
                      Icons.mail_outline,
                      validateEmail,
                      keyboard: TextInputType.emailAddress,
                    ),
                    _field(
                      _password,
                      'Password',
                      Icons.lock_outline,
                      requiredField('Password', min: 6),
                      obscure: true,
                    ),
                    TextFormField(
                      obscureText: true,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) =>
                          v != _password.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: busy ? null : _submit,
                      child: busy
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Register'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
