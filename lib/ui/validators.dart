import 'package:flutter/widgets.dart';

FormFieldValidator<String> requiredField(String field, {int min = 1}) =>
    (value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return '$field is required';
      if (v.length < min) return '$field must be at least $min characters';
      return null;
    };

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Email is required';
  final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
  return valid ? null : 'Enter a valid email';
}
