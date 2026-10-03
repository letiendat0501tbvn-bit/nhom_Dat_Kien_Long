import '../mock/mock_support.dart';
import '../models/block_entry.dart';
import '../models/enums.dart';
import '../models/report.dart';
import '../models/user_feedback.dart';
import 'safety_repository.dart';

// Bản mock của SafetyRepository: báo cáo, chặn, phản hồi lưu trong bộ nhớ.
// Việc ẩn nội dung của người bị chặn làm ở tầng trên (giai đoạn F).
class MockSafetyRepository implements SafetyRepository {
  MockSafetyRepository({
    this.now = systemClock,
    this.latency = randomLatency,
  });

  final Clock now;
  final Latency latency;
  final _reports = <Report>[];
  final _blocks = <BlockEntry>[];
  final _feedbacks = <UserFeedback>[];
  var _nextId = 1;

  Future<void> _wait() => Future<void>.delayed(latency());

  @override
  Future<Report> submitReport({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
  }) async {
    await _wait();
    final report = Report(
      id: 'r${_nextId++}',
      reporterId: reporterId,
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      createdAt: now(),
    );
    _reports.add(report);
    return report;
  }

  @override
  Future<List<Report>> getReports(String reporterId) async {
    await _wait();
    return _reports.where((r) => r.reporterId == reporterId).toList();
  }

  @override
  Future<void> blockUser(String userId, String blockedUserId) async {
    await _wait();
    final exists = _blocks.any(
        (b) => b.userId == userId && b.blockedUserId == blockedUserId);
    if (exists) return; // chặn lại người đã chặn thì bỏ qua
    _blocks.add(BlockEntry(
      userId: userId,
      blockedUserId: blockedUserId,
      createdAt: now(),
    ));
  }

  @override
  Future<void> unblockUser(String userId, String blockedUserId) async {
    await _wait();
    _blocks.removeWhere(
        (b) => b.userId == userId && b.blockedUserId == blockedUserId);
  }

  @override
  Future<List<BlockEntry>> getBlocks(String userId) async {
    await _wait();
    return _blocks.where((b) => b.userId == userId).toList();
  }

  @override
  Future<UserFeedback> submitFeedback({
    required String userId,
    required String text,
  }) async {
    await _wait();
    final feedback = UserFeedback(
      id: 'f${_nextId++}',
      userId: userId,
      text: text,
      createdAt: now(),
    );
    _feedbacks.add(feedback);
    return feedback;
  }

  @override
  Future<List<UserFeedback>> getFeedbacks(String userId) async {
    await _wait();
    return _feedbacks.where((f) => f.userId == userId).toList();
  }
}
