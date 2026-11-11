import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth_bloc.dart';
import 'data/auth_repository.dart';
import 'data/report_repository.dart';
import 'firebase_options.dart';
import 'ui/pages/app_shell.dart';
import 'ui/pages/login_page.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _navigator = GlobalKey<NavigatorState>();
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider(create: (_) => AuthRepository()),
      RepositoryProvider(create: (_) => ReportRepository()),
    ],
    child: BlocProvider(
      create: (c) =>
          AuthBloc(c.read<AuthRepository>())..add(const AuthStarted()),
      child: MultiBlocListener(
        listeners: [
          // Drop pushed routes (register, details, form) whenever the user signs in or out.
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (a, b) => a.status != b.status,
            listener: (_, _) =>
                _navigator.currentState?.popUntil((r) => r.isFirst),
          ),
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (a, b) => b.error != null && a.error == null,
            listener: (_, s) => _messenger.currentState?.showSnackBar(
              SnackBar(content: Text(s.error!)),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Campus Incident Reporter',
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          navigatorKey: _navigator,
          scaffoldMessengerKey: _messenger,
          home: BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (a, b) =>
                a.status != b.status || a.user?.uid != b.user?.uid,
            builder: (_, state) => switch (state.status) {
              AuthStatus.unknown => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              AuthStatus.unauthenticated => const LoginPage(),
              AuthStatus.authenticated => AppShell(
                key: ValueKey(state.user!.uid),
                user: state.user!,
              ),
            },
          ),
        ),
      ),
    ),
  );
}
