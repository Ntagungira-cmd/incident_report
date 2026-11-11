import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/report_repository.dart';
import '../models/app_user.dart';
import '../models/report.dart';

sealed class ReportsEvent {
  const ReportsEvent();
}

final class ReportsSubscribed extends ReportsEvent {
  const ReportsSubscribed(this.user);
  final AppUser user;
}

final class StatusUpdateRequested extends ReportsEvent {
  const StatusUpdateRequested(this.report, this.status);
  final Report report;
  final ReportStatus status;
}

enum ReportsStatus { loading, ready, failure }

class ReportsState {
  const ReportsState({
    this.status = ReportsStatus.loading,
    this.reports = const [],
    this.error,
  });

  final ReportsStatus status;
  final List<Report> reports;
  final String? error;

  int count(ReportStatus s) => reports.where((r) => r.status == s).length;
  Report? byId(String id) => reports.where((r) => r.id == id).firstOrNull;
}

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc(this._repo) : super(const ReportsState()) {
    on<ReportsSubscribed>(
      (event, emit) => emit.forEach<List<Report>>(
        _repo.watch(event.user),
        onData: (reports) =>
            ReportsState(status: ReportsStatus.ready, reports: reports),
        onError: (e, _) => ReportsState(
          status: ReportsStatus.failure,
          reports: state.reports,
          error: '$e',
        ),
      ),
    );
    on<StatusUpdateRequested>((event, emit) async {
      try {
        await _repo.updateStatus(event.report, event.status);
      } catch (e) {
        emit(
          ReportsState(
            status: state.status,
            reports: state.reports,
            error: '$e',
          ),
        );
      }
    });
  }

  final ReportRepository _repo;
}
