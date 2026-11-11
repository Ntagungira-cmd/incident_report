import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../data/report_repository.dart';
import '../models/app_user.dart';
import '../models/report.dart';

enum SubmitStatus { idle, submitting, success, failure }

class ReportFormState {
  const ReportFormState({
    this.photo,
    this.status = SubmitStatus.idle,
    this.error,
  });

  final Uint8List? photo;
  final SubmitStatus status;
  final String? error;
}

class ReportFormCubit extends Cubit<ReportFormState> {
  ReportFormCubit(this._repo, this._user, {ImagePicker? picker})
    : _picker = picker ?? ImagePicker(),
      super(const ReportFormState());

  final ReportRepository _repo;
  final AppUser _user;
  final ImagePicker _picker;

  Future<void> pickPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      emit(ReportFormState(photo: await file.readAsBytes()));
    } catch (e) {
      emit(
        ReportFormState(
          photo: state.photo,
          status: SubmitStatus.failure,
          error: 'Could not open photo: $e',
        ),
      );
    }
  }

  void removePhoto() => emit(const ReportFormState());

  Future<void> submit({
    required String title,
    required ReportCategory category,
    required String location,
    required String description,
  }) async {
    emit(ReportFormState(photo: state.photo, status: SubmitStatus.submitting));
    try {
      await _repo.submit(
        user: _user,
        title: title,
        category: category,
        location: location,
        description: description,
        photo: state.photo,
      );
      emit(ReportFormState(photo: state.photo, status: SubmitStatus.success));
    } catch (e) {
      final message = e is FirebaseException ? (e.message ?? e.code) : '$e';
      emit(
        ReportFormState(
          photo: state.photo,
          status: SubmitStatus.failure,
          error: message,
        ),
      );
    }
  }
}
