import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth_bloc.dart';
import '../validators.dart';

const _departments = [
  'Computer Science',
  'Engineering',
  'Business',
  'Education',
  'Health Sciences',
  'Facilities',
];

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _department;

  @override
  void dispose() {
    for (final c in [_name, _location, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final form = _formKey.currentState!;
    if (!form.validate()) return;
    form.save();
    final department = _department;
    if (department == null) return;
    context.read<AuthBloc>().add(
      RegisterRequested(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        department: department,
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
                        initialValue: _department,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        items: [
                          for (final department in _departments)
                            DropdownMenuItem(
                              value: department,
                              child: Text(department),
                            ),
                        ],
                        // The field stores the choice itself; onChanged only enables it.
                        onChanged: (_) {},
                        onSaved: (value) => _department = value,
                        validator: (value) =>
                            value == null || !_departments.contains(value)
                            ? 'Department is required'
                            : null,
                      ),
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
