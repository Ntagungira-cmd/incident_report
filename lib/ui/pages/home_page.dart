import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/reports_bloc.dart';
import '../../cubit/nav_cubit.dart';
import '../../models/app_user.dart';
import '../../models/report.dart';
import '../widgets/report_tile.dart';
import '../widgets/stat_card.dart';
import '../widgets/user_avatar.dart';
import 'report_form_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppUser>();
    final state = context.watch<ReportsBloc>().state;
    final theme = Theme.of(context);
    void seeAll() => context.read<NavCubit>().select(1);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Hello, ${user.firstName}',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.waving_hand, color: Color(0xFFF5B400)),
                  ],
                ),
              ),
              UserAvatar(user.name),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Help make our campus safer.',
            style: theme.textTheme.titleMedium,
          ),
          const Text(
            'Report issues and track their resolution.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          const _ReportBanner(),
          const SizedBox(height: 24),
          _SectionHeader('Report Summary', onSeeAll: seeAll),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (label, count, color, icon) in [
                (
                  user.isStaff ? 'All Reports' : 'My Reports',
                  state.reports.length,
                  theme.colorScheme.primary,
                  Icons.description_outlined,
                ),
                (
                  ReportStatus.inProgress.label,
                  state.count(ReportStatus.inProgress),
                  const Color(0xFF2D7FF9),
                  Icons.schedule,
                ),
                (
                  ReportStatus.resolved.label,
                  state.count(ReportStatus.resolved),
                  ReportStatus.resolved.color,
                  Icons.check,
                ),
                (
                  ReportStatus.submitted.label,
                  state.count(ReportStatus.submitted),
                  const Color(0xFFE5484D),
                  Icons.priority_high,
                ),
              ]) ...[
                Expanded(
                  child: StatCard(
                    count: count,
                    label: label,
                    color: color,
                    icon: icon,
                  ),
                ),
                if (label != ReportStatus.submitted.label)
                  const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader('Recent Reports', onSeeAll: seeAll),
          const SizedBox(height: 12),
          ...switch (state.status) {
            ReportsStatus.loading => [
              const Center(child: CircularProgressIndicator()),
            ],
            ReportsStatus.failure when state.reports.isEmpty => [
              Text(
                'Could not load reports: ${state.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ],
            _ when state.reports.isEmpty => [
              const _EmptyState(
                'No reports yet. Tap "Report an Issue" to submit one.',
              ),
            ],
            _ => [
              for (final r in state.reports.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ReportTile(r),
                ),
            ],
          },
        ],
      ),
    );
  }
}

class _ReportBanner extends StatelessWidget {
  const _ReportBanner();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF6D4AFF), Color(0xFFA48BFF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'See an issue on campus?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Report it and help improve our learning environment.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.account_balance,
                size: 72,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => ReportFormPage.open(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: primary,
                      child: const Icon(
                        Icons.add,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Report an Issue',
                        style: TextStyle(
                          color: primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      TextButton(onPressed: onSeeAll, child: const Text('See all')),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const Icon(Icons.inbox_outlined, size: 48, color: Colors.black26),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    ),
  );
}
