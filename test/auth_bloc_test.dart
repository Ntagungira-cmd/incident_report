import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incident_report/bloc/auth_bloc.dart';
import 'package:incident_report/data/auth_repository.dart';
import 'package:incident_report/models/app_user.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.updated);

  final AppUser updated;
  AppUser? savedFrom;

  @override
  Stream<AppUser?> userChanges() => Stream.value(before);

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String department,
    required String location,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<List<AppUser>> listStaff() async => const [];

  @override
  Future<AppUser> updateProfile({
    required AppUser user,
    required String name,
    required String department,
    required String location,
    Uint8List? photo,
  }) async {
    savedFrom = user;
    return updated;
  }
}

const before = AppUser(
  uid: 'u1',
  name: 'Amina Hassan',
  email: 'a@b.c',
  department: 'Computer Science',
  location: 'Kigali Campus',
);

const after = AppUser(
  uid: 'u1',
  name: 'Amina Uwase',
  email: 'a@b.c',
  department: 'Business',
  location: 'Huye Campus',
  photoUrl: 'https://res.cloudinary.com/demo/image/upload/v1/avatar.jpg',
);

void main() {
  late FakeAuthRepository repo;

  setUp(() => repo = FakeAuthRepository(after));

  blocTest<AuthBloc, AuthState>(
    'emits the user returned by a profile update',
    build: () => AuthBloc(repo),
    act: (bloc) async {
      bloc.add(const AuthStarted());
      await bloc.stream.firstWhere((s) => s.status == AuthStatus.authenticated);
      bloc.add(
        const ProfileUpdateRequested(
          name: 'Amina Uwase',
          department: 'Business',
          location: 'Huye Campus',
        ),
      );
    },
    expect: () => [
      isA<AuthState>()
          .having((s) => s.status, 'status', AuthStatus.authenticated)
          .having((s) => s.user?.name, 'name', 'Amina Hassan'),
      isA<AuthState>().having((s) => s.busy, 'busy', true),
      isA<AuthState>()
          .having((s) => s.user?.name, 'name', 'Amina Uwase')
          .having((s) => s.user?.photoUrl, 'photo', after.photoUrl)
          .having((s) => s.busy, 'busy', false),
    ],
    verify: (_) => expect(repo.savedFrom?.name, 'Amina Hassan'),
  );
}
