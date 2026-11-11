import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/reports_bloc.dart';
import '../../cubit/report_filter_cubit.dart';
import '../../models/app_user.dart';
import '../../models/report.dart';
import '../widgets/report_tile.dart';
import '../widgets/stat_card.dart';
import '../widgets/user_avatar.dart';

class MyReportsPage extends StatelessWidget {
  const MyReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppUser>();
    final state = context.watch<ReportsBloc>().state;
    final filter = context.watch<ReportFilterCubit>().state;
    final visible = filter.apply(state.reports);
    final theme = Theme.of(context);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverList.list(
              children: [
                Text(
                  user.isStaff ? 'All Reports' : 'My Reports',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _ProfileCard(user: user, state: state),
                const SizedBox(height: 16),
                const _SearchRow(),
                const SizedBox(height: 12),
                const _StatusChips(),
                const SizedBox(height: 12),
              ],
            ),
          ),
          switch (state.status) {
            ReportsStatus.loading => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            ReportsStatus.failure when state.reports.isEmpty =>
              SliverFillRemaining(
                child: Center(
                  child: Text('Could not load reports: ${state.error}'),
                ),
              ),
            _ when visible.isEmpty => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  state.reports.isEmpty
                      ? 'No reports yet.'
                      : 'No reports match your filters.',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ),
            _ => SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.separated(
                itemCount: visible.length,
                itemBuilder: (_, i) => ReportTile(visible[i]),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
              ),
            ),
          },
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.state});

  final AppUser user;
  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    Widget info(IconData icon, String text) => Row(
      children: [
        Icon(icon, size: 14, color: Colors.black45),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
      ],
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                UserAvatar(user.name, radius: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              user.isStaff ? 'Staff' : 'Student',
                              style: TextStyle(
                                color: primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      info(Icons.school_outlined, user.department),
                      const SizedBox(height: 2),
                      info(Icons.location_on_outlined, user.location),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    count: state.reports.length,
                    label: 'Total Reports',
                    color: primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    count: state.count(ReportStatus.inProgress),
                    label: 'In Progress',
                    color: const Color(0xFF2D7FF9),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    count: state.count(ReportStatus.resolved),
                    label: 'Resolved',
                    color: ReportStatus.resolved.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportFilterCubit>();
    final category = context.select((ReportFilterCubit c) => c.state.category);
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: cubit.setQuery,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search reports',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<ReportCategory?>(
          tooltip: 'Filter by category',
          onSelected: cubit.setCategory,
          itemBuilder: (_) => [
            const PopupMenuItem(value: null, child: Text('All categories')),
            for (final c in ReportCategory.values)
              PopupMenuItem(
                value: c,
                child: ListTile(
                  leading: Icon(c.icon),
                  title: Text(c.label),
                  selected: c == category,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
          child: Badge(
            isLabelVisible: category != null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6E6EF)),
              ),
              child: Icon(category?.icon ?? Icons.tune),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips();

  @override
  Widget build(BuildContext context) {
    final selected = context.select((ReportFilterCubit c) => c.state.status);
    final cubit = context.read<ReportFilterCubit>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (label, status) in [
            ('All', null),
            for (final s in ReportStatus.values) (s.label, s),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selected == status,
                onSelected: (_) => cubit.setStatus(status),
                showCheckmark: false,
              ),
            ),
        ],
      ),
    );
  }
}
