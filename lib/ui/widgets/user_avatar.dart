import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar(this.name, {super.key, this.photoUrl, this.radius = 22});

  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(context);
    final url = photoUrl;
    if (url == null || url.isEmpty) return initials;
    return ClipOval(
      child: Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => initials,
      ),
    );
  }

  Widget _initials(BuildContext context) {
    final letters = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0])
        .join();
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        letters.toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
      ),
    );
  }
}
