import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../cubit/report_form_cubit.dart';
import '../../data/report_repository.dart';
import '../../models/app_user.dart';
import '../../models/report.dart';
import '../validators.dart';

class ReportFormPage extends StatefulWidget {
  const ReportFormPage({super.key});

  /// Pushed above the shell, so the cubit's dependencies are passed in explicitly.
  static Future<void> open(BuildContext context) {
    final repo = context.read<ReportRepository>();
    final user = context.read<AppUser>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ReportFormCubit(repo, user),
          child: const ReportFormPage(),
        ),
      ),
    );
  }

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  ReportCategory? _category;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ReportFormCubit>().submit(
      title: _title.text.trim(),
      category: _category!,
      location: _location.text.trim(),
      description: _description.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportFormCubit, ReportFormState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.status == SubmitStatus.success) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Report submitted')),
          );
          Navigator.of(context).pop();
        } else if (state.status == SubmitStatus.failure) {
          messenger.showSnackBar(
            SnackBar(content: Text(state.error ?? 'Submission failed')),
          );
        }
      },
      builder: (context, state) {
        final submitting = state.status == SubmitStatus.submitting;
        return Scaffold(
          appBar: AppBar(title: const Text('Report an Issue')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _title,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. Water shortage',
                    ),
                    validator: requiredField('Title', min: 3),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ReportCategory>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      for (final c in ReportCategory.values)
                        DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Icon(c.icon, size: 20),
                              const SizedBox(width: 10),
                              Text(c.label),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (c) => setState(() => _category = c),
                    validator: (c) => c == null ? 'Choose a category' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _location,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'e.g. Block B, Room 204',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: requiredField('Location'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _description,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'What happened, and since when?',
                      alignLabelWithHint: true,
                    ),
                    validator: requiredField('Description', min: 10),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Photo (optional)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _PhotoPicker(enabled: !submitting),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: submitting ? null : _submit,
                    child: submitting
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit report'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportFormCubit>();
    final photo = context.select((ReportFormCubit c) => c.state.photo);
    if (photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              photo,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filledTonal(
              tooltip: 'Remove photo',
              onPressed: enabled ? cubit.removePhoto : null,
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled
                ? () => cubit.pickPhoto(ImageSource.camera)
                : null,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Camera'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled
                ? () => cubit.pickPhoto(ImageSource.gallery)
                : null,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Gallery'),
          ),
        ),
      ],
    );
  }
}
