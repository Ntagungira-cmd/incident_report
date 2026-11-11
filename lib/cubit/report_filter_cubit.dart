import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/report.dart';

class ReportFilter {
  const ReportFilter({this.status, this.category, this.query = ''});

  /// Null means "all".
  final ReportStatus? status;
  final ReportCategory? category;
  final String query;

  List<Report> apply(List<Report> reports) {
    final q = query.trim().toLowerCase();
    return reports
        .where((r) => status == null || r.status == status)
        .where((r) => category == null || r.category == category)
        .where(
          (r) =>
              q.isEmpty ||
              r.title.toLowerCase().contains(q) ||
              r.location.toLowerCase().contains(q) ||
              r.description.toLowerCase().contains(q),
        )
        .toList();
  }
}

class ReportFilterCubit extends Cubit<ReportFilter> {
  ReportFilterCubit() : super(const ReportFilter());

  void setStatus(ReportStatus? status) => emit(
    ReportFilter(status: status, category: state.category, query: state.query),
  );

  void setCategory(ReportCategory? category) => emit(
    ReportFilter(status: state.status, category: category, query: state.query),
  );

  void setQuery(String query) => emit(
    ReportFilter(status: state.status, category: state.category, query: query),
  );
}
