import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../bloc/auth_bloc.dart';
import '../../models/app_user.dart';
import '../validators.dart';
import '../widgets/user_avatar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.user});

  final AppUser user;

  static Future<void> open(BuildContext context, AppUser user) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => EditProfilePage(user: user)));

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late String? _department;
  Uint8List? _photo;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _location = TextEditingController(text: widget.user.location);
    _department = widget.user.department;
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    super.dispose();
  }

  List<String> get _departmentOptions => [
    ...departments,
    if (!departments.contains(widget.user.department) &&
        widget.user.department.isNotEmpty)
      widget.user.department,
  ];

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _photo = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open photo: $e')));
    }
  }

  void _save() {
    final form = _formKey.currentState!;
    if (!form.validate()) return;
    form.save();
    final department = _department;
    if (department == null) return;
    context.read<AuthBloc>().add(
      ProfileUpdateRequested(
        name: _name.text.trim(),
        department: department,
        location: _location.text.trim(),
        photo: _photo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select((AuthBloc b) => b.state.busy);
    final photo = _photo;
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (a, b) => a.busy && !b.busy,
      listener: (context, state) {
        if (state.error == null) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
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
                      Center(
                        child: photo == null
                            ? UserAvatar(
                                widget.user.name,
                                photoUrl: widget.user.photoUrl,
                                radius: 48,
                              )
                            : ClipOval(
                                child: Image.memory(
                                  photo,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: busy
                                  ? null
                                  : () => _pick(ImageSource.camera),
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: const Text('Camera'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: busy
                                  ? null
                                  : () => _pick(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Gallery'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: requiredField('Name', min: 2),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _departmentOptions.contains(_department)
                            ? _department
                            : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        items: [
                          for (final department in _departmentOptions)
                            DropdownMenuItem(
                              value: department,
                              child: Text(department),
                            ),
                        ],
                        // The field stores the choice itself; onChanged only enables it.
                        onChanged: (_) {},
                        onSaved: (value) => _department = value,
                        validator: (value) =>
                            value == null || !_departmentOptions.contains(value)
                            ? 'Department is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _location,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: requiredField('Location'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: widget.user.email,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: busy ? null : _save,
                        child: busy
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
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
}
