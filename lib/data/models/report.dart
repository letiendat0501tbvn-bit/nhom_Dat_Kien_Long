import '../../core/entity.dart';
import '../../core/map_utils.dart';
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

  factory Report.fromMap(String id, Map<String, dynamic> map) => Report(
    id: id,
    reporterId: map['reporterId'] as String,
    targetType: readEnum(
      ReportTargetType.values,
      map['targetType'],
      ReportTargetType.table,
    ),
    targetId: map['targetId'] as String,
    reason: map['reason'] as String,
    createdAt: readDate(map['createdAt']),
    note: map['note'] as String? ?? '',
  );

  final String reporterId;
  final ReportTargetType targetType;
  final String targetId;
  final String reason;
  final DateTime createdAt;
  final String note; // ghi chú tuỳ chọn của người báo cáo (tối đa 280 ký tự)

  @override
  Map<String, dynamic> toMap() => {
    'reporterId': reporterId,
    'targetType': targetType.name,
    'targetId': targetId,
    'reason': reason,
    'createdAt': createdAt,
    'note': note,
  };

  @override
  String get label => '${targetType.name}:$reason';
}
