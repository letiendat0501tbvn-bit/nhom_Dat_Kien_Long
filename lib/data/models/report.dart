import '../../core/entity.dart';
import 'enums.dart';

// Báo cáo bàn / người dùng / tin nhắn; hiện trong "Báo cáo đã gửi".
class Report extends Entity<String> {
  const Report({
    required String id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.createdAt,
    this.note = '',
  }) : super(id);

  final String reporterId;
  final ReportTargetType targetType;
  final String targetId;
  final String reason;
  final DateTime createdAt;
  final String note; // ghi chú tuỳ chọn của người báo cáo (tối đa 280 ký tự)

  @override
  String get label => '${targetType.name}:$reason';
}
