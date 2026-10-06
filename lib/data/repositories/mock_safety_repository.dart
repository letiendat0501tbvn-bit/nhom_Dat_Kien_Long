import '../mock/mock_support.dart';
import '../models/block_entry.dart';
import '../models/enums.dart';
import '../models/report.dart';
import '../models/user_feedback.dart';
import 'safety_repository.dart';

// Bản mock của SafetyRepository: báo cáo, chặn, phản hồi lưu trong bộ nhớ.
// Việc ẩn nội dung của người bị chặn do MockTableRepository/MockChatRepository làm,
// dùng blockedIdsOf bên dưới (không có độ trễ để các repository kia gọi nhanh).
class MockSafetyRepository implements SafetyRepository {
  MockSafetyRepository({this.now = systemClock, this.latency = randomLatency});

  final Clock now;
  final Latency latency;
  final _reports = <Report>[];
  final _blocks = <BlockEntry>[];
  final _feedbacks = <UserFeedback>[];
  var _nextId = 1;

  Future<void> _wait() => Future<void>.delayed(latency());

  // Id những người mà userId đã chặn (không trễ; dùng nội bộ giữa các repository mock).
  Set<String> blockedIdsOf(String userId) => {
    for (final b in _blocks)
      if (b.userId == userId) b.blockedUserId,
  };

  @override
  Future<Report> submitReport({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
    String note = '',
  }) async {
    await _wait();
    if (targetType == ReportTargetType.user && targetId == reporterId) {
      throw const SafetyException(SafetyError.cannotTargetSelf);
    }
    final duplicate = _reports.any(
      (r) =>
          r.reporterId == reporterId &&
          r.targetType == targetType &&
          r.targetId == targetId &&
          r.reason == reason,
    );
    if (duplicate) throw const SafetyException(SafetyError.alreadyReported);
    final report = Report(
      id: 'r${_nextId++}',
      reporterId: reporterId,
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      note: note.trim(),
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
    if (userId == blockedUserId) {
      throw const SafetyException(SafetyError.cannotTargetSelf);
    }
    final exists = _blocks.any(
      (b) => b.userId == userId && b.blockedUserId == blockedUserId,
    );
    if (exists) return; // chặn lại người đã chặn thì bỏ qua
    _blocks.add(
      BlockEntry(
        userId: userId,
        blockedUserId: blockedUserId,
        createdAt: now(),
      ),
    );
  }

  @override
  Future<void> unblockUser(String userId, String blockedUserId) async {
    await _wait();
    _blocks.removeWhere(
      (b) => b.userId == userId && b.blockedUserId == blockedUserId,
    );
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
