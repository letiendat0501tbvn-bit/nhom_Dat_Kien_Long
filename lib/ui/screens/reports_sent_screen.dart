import 'package:flutter/material.dart';

import '../../data/models/report.dart';
import '../../l10n/formatters.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../components/status_view.dart';
import '../theme/app_theme.dart';

// "Báo cáo đã gửi" (Hồ sơ > Tài khoản): loại đối tượng, lý do, thời gian, mới nhất trước.
// Chưa có ảnh thiết kế; dựng theo phong cách các màn khác.
class ReportsSentScreen extends StatefulWidget {
  const ReportsSentScreen({super.key});

  @override
  State<ReportsSentScreen> createState() => _ReportsSentScreenState();
}

class _ReportsSentScreenState extends State<ReportsSentScreen> {
  var _status = LoadStatus.loading;
  var _reports = <Report>[];
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = LoadStatus.loading);
    try {
      final app = AppScope.of(context, listen: false);
      final me = app.currentUser;
      final list = me == null
          ? <Report>[]
          : await app.safetyRepository.getReports(me.id);
      if (!mounted) return;
      setState(() {
        _reports = [...list]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _status = LoadStatus.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = LoadStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(t(StrKey.reportsSent))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: StatusView(
            status: _status,
            isEmpty: _reports.isEmpty,
            onRetry: _load,
            emptyKey: StrKey.reportsEmpty,
            errorKey: StrKey.reportsError,
            builder: (_) => Column(
              children: [
                for (final r in _reports)
                  _ReportCard(key: ValueKey(r.id), report: r),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final muted = TextStyle(
      fontSize: 14,
      color: AppColors.text.withValues(alpha: 0.7),
    );
    final when =
        '${formatDayMonth(report.createdAt)} · ${formatClockTime(report.createdAt, t.language)}';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1F000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.reportTypeLabel(report.targetType),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(when, style: muted),
          const SizedBox(height: 6),
          Text(
            t.reportReasonLabel(report.reason),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          if (report.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              report.note,
              style: muted.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

// Mở màn "Báo cáo đã gửi".
Future<void> openReportsSent(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const ReportsSentScreen()),
  );
}
