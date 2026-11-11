import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/reports_bloc.dart';
import '../../data/auth_repository.dart';
import '../../models/app_user.dart';
import '../../models/report.dart';
import '../format.dart';
import '../widgets/report_tile.dart';
import '../widgets/status_chip.dart';

class IncidentDetailsPage extends StatelessWidget {
  const IncidentDetailsPage({super.key, required this.reportId});

  final String reportId;

  /// Pushed above the shell, so its providers are re-exposed to the new route.
  static Future<void> open(BuildContext context, Report report) {
    final bloc = context.read<ReportsBloc>();
    final user = context.read<AppUser>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RepositoryProvider.value(
          value: user,
          child: BlocProvider.value(
            value: bloc,
            child: IncidentDetailsPage(reportId: report.id),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppUser>();
    final report = context.select((ReportsBloc b) => b.state.byId(reportId));
    final theme = Theme.of(context);
    final heading = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return BlocListener<ReportsBloc, ReportsState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: ${state.error}'))),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Incident Details'),
          centerTitle: true,
        ),
        body: report == null
            ? const Center(child: Text('This report is no longer available.'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ReportThumb(report, size: 80),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(report.title, style: heading),
                                    const SizedBox(height: 2),
                                    Text(
                                      report.location,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    StatusChip(report.status),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _Meta(Icons.category_outlined, report.category.label),
                          _Meta(
                            Icons.calendar_today_outlined,
                            'Submitted on ${formatDateTime(report.createdAt)}',
                          ),
                          _Meta(
                            Icons.person_outline,
                            'Reported by ${report.reporterName}',
                          ),
                          if (report.assigneeLabel case final label?)
                            _Meta(
                              Icons.assignment_ind_outlined,
                              label == 'Unassigned'
                                  ? 'Unassigned'
                                  : 'Assigned to $label',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Status Timeline', style: heading),
                  const SizedBox(height: 12),
                  _Timeline(report),
                  const SizedBox(height: 24),
                  Text('Description', style: heading),
                  const SizedBox(height: 8),
                  Text(report.description, style: const TextStyle(height: 1.5)),
                  if (report.photoUrl != null) ...[
                    const SizedBox(height: 24),
                    Text('Attached Photo', style: heading),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        report.photoUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const SizedBox(
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                        errorBuilder: (_, _, _) => const SizedBox(
                          height: 120,
                          child: Center(child: Text('Could not load photo')),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
        bottomNavigationBar: report != null && user.isStaff
            ? _actions(context, user, report)
            : null,
      ),
    );
  }

  Future<void> _changeStatus(BuildContext context, Report report) async {
    final bloc = context.read<ReportsBloc>();
    final status = await showModalBottomSheet<ReportStatus>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in ReportStatus.values)
              ListTile(
                leading: Icon(s.icon, color: s.color),
                title: Text(s.label),
                trailing: s == report.status ? const Icon(Icons.check) : null,
                enabled: s != report.status,
                onTap: () => Navigator.pop(context, s),
              ),
          ],
        ),
      ),
    );
    if (status != null) bloc.add(StatusUpdateRequested(report, status));
  }

  Future<void> _assign(BuildContext context, Report report) async {
    final bloc = context.read<ReportsBloc>();
    List<AppUser> staff;
    try {
      staff = await context.read<AuthRepository>().listStaff();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load staff: $e')));
      return;
    }
    if (!context.mounted) return;
    final assignee = await showModalBottomSheet<AppUser>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: staff.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No staff to assign'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final member in staff)
                    ListTile(
                      title: Text(member.name),
                      subtitle: Text(member.department),
                      onTap: () => Navigator.pop(context, member),
                    ),
                ],
              ),
      ),
    );
    if (assignee != null) bloc.add(AssigneeSet(report, assignee));
  }

  Widget _actions(BuildContext context, AppUser user, Report report) {
    final canTake =
        report.assigneeId == null && report.status != ReportStatus.resolved;
    final changeStatus = canTake
        ? OutlinedButton.icon(
            onPressed: () => _changeStatus(context, report),
            icon: const Icon(Icons.sync_alt),
            label: const Text('Change status'),
          )
        : FilledButton.icon(
            onPressed: () => _changeStatus(context, report),
            icon: const Icon(Icons.sync_alt),
            label: const Text('Change status'),
          );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canTake) ...[
              FilledButton.icon(
                onPressed: () =>
                    context.read<ReportsBloc>().add(AssigneeSet(report, user)),
                icon: const Icon(Icons.front_hand_outlined),
                label: const Text('Claim issue'),
              ),
              if (user.isAdmin) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _assign(context, report),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Assign'),
                ),
              ],
              const SizedBox(height: 8),
            ],
            changeStatus,
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.black45),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline(this.report);

  final Report report;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final current = report.status.index;
    final steps = ReportStatus.values;
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i <= current ? primary : Colors.black12,
                  ),
                ),
              CircleAvatar(
                radius: 14,
                backgroundColor: i <= current ? primary : Colors.black12,
                child: Icon(
                  i < current || report.status == ReportStatus.resolved
                      ? Icons.check
                      : steps[i].icon,
                  size: 16,
                  color: i <= current ? Colors.white : Colors.black38,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: Column(
                  crossAxisAlignment: switch (i) {
                    0 => CrossAxisAlignment.start,
                    _ when i == steps.length - 1 => CrossAxisAlignment.end,
                    _ => CrossAxisAlignment.center,
                  },
                  children: [
                    Text(
                      steps[i].label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: i == current ? primary : Colors.black87,
                      ),
                    ),
                    Text(
                      _reachedAt(steps[i]) == null || i > current
                          ? '-'
                          : formatShort(_reachedAt(steps[i])!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Latest time the report entered [status]; it can move back and forth.
  DateTime? _reachedAt(ReportStatus status) => report.history
      .where((h) => h.status == status)
      .map((h) => h.at)
      .fold<DateTime?>(
        null,
        (latest, at) => latest == null || at.isAfter(latest) ? at : latest,
      );
}
