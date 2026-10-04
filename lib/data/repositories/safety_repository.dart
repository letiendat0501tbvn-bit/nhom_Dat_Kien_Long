import '../models/block_entry.dart';
import '../models/enums.dart';
import '../models/report.dart';
import '../models/user_feedback.dart';

// Lý do một thao tác báo cáo/chặn bị từ chối.
enum SafetyError {
  alreadyReported, // cùng người báo cáo, cùng đối tượng, cùng lý do
  cannotTargetSelf, // không báo cáo hoặc chặn chính mình
}

class SafetyException implements Exception {
  const SafetyException(this.error);

  final SafetyError error;

  @override
  String toString() => 'SafetyException(${error.name})';
}

// Báo cáo, chặn và phản hồi riêng tư (các mục trong tab Tài khoản).
// Việc ẩn bàn/tin nhắn của người bị chặn do TableRepository và ChatRepository thực hiện,
// dựa trên danh sách chặn lưu ở đây.
abstract class SafetyRepository {
  // Ném SafetyException(alreadyReported) nếu đã có báo cáo cùng người, đối tượng, lý do
  // (không tạo bản ghi mới); cannotTargetSelf nếu báo cáo chính mình.
  Future<Report> submitReport({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
    String note = '',
  });

  Future<List<Report>> getReports(String reporterId);

  // Ném SafetyException(cannotTargetSelf) nếu tự chặn mình.
  Future<void> blockUser(String userId, String blockedUserId);

  Future<void> unblockUser(String userId, String blockedUserId);

  Future<List<BlockEntry>> getBlocks(String userId);

  Future<UserFeedback> submitFeedback({
    required String userId,
    required String text,
  });

  Future<List<UserFeedback>> getFeedbacks(String userId);
}
