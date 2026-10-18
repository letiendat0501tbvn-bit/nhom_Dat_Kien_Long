import '../../core/entity.dart';

// Phản hồi riêng tư của người dùng.
// Đặt tên UserFeedback (SPEC ghi Feedback) để không trùng widget Feedback của Flutter.
class UserFeedback extends Entity<String> {
  const UserFeedback({
    required String id,
    required this.userId,
    required this.text,
    required this.createdAt,
  }) : super(id);

  final String userId;
  final String text;
  final DateTime createdAt;

  @override
  String get label => text;
}
