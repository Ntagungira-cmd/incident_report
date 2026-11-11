import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/reports_bloc.dart';
import '../../cubit/nav_cubit.dart';
import '../../cubit/report_filter_cubit.dart';
import '../../data/report_repository.dart';
import '../../models/app_user.dart';
import 'home_page.dart';
import 'my_reports_page.dart';
import 'profile_page.dart';
import 'report_form_page.dart';

/// Signed-in root: provides the per-user blocs and the bottom navigation.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
    value: user,
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (c) =>
              ReportsBloc(c.read<ReportRepository>())
                ..add(ReportsSubscribed(user)),
        ),
        BlocProvider(create: (_) => ReportFilterCubit()),
        BlocProvider(create: (_) => NavCubit()),
      ],
      child: const _ShellView(),
    ),
  );
}

class _ShellView extends StatelessWidget {
  const _ShellView();

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<NavCubit>().state;
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: const [HomePage(), MyReportsPage(), ProfilePage()],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        tooltip: 'Report an issue',
        onPressed: () => ReportFormPage.open(context),
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              active: Icons.home,
              label: 'Home',
              index: 0,
              current: tab,
            ),
            _NavItem(
              icon: Icons.description_outlined,
              active: Icons.description,
              label: 'Reports',
              index: 1,
              current: tab,
            ),
            const Expanded(child: SizedBox()),
            _NavItem(
              icon: Icons.person_outline,
              active: Icons.person,
              label: 'Profile',
              index: 2,
              current: tab,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.active,
    required this.label,
    required this.index,
    required this.current,
  });

  final IconData icon;
  final IconData active;
  final String label;
  final int index;
  final int current;

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Colors.black54;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkResponse(
          onTap: () => context.read<NavCubit>().select(index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? active : icon, color: color),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
