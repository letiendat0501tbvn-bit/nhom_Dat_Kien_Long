import '../models/block_entry.dart';
import '../models/enums.dart';
import '../models/report.dart';
import '../models/user_feedback.dart';

// Báo cáo, chặn và phản hồi riêng tư (các mục trong tab Tài khoản).
abstract class SafetyRepository {
  Future<Report> submitReport({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
  });

  Future<List<Report>> getReports(String reporterId);

  Future<void> blockUser(String userId, String blockedUserId);

  Future<void> unblockUser(String userId, String blockedUserId);

  Future<List<BlockEntry>> getBlocks(String userId);

  Future<UserFeedback> submitFeedback({
    required String userId,
    required String text,
  });

  Future<List<UserFeedback>> getFeedbacks(String userId);
}
