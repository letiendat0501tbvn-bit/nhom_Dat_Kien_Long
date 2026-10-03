import 'enums.dart';

// Báo cáo bàn / người dùng / tin nhắn; hiện trong "Báo cáo đã gửi".
class Report {
  const Report({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String reporterId;
  final ReportTargetType targetType;
  final String targetId;
  final String reason;
  final DateTime createdAt;
}
