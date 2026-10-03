// Phản hồi riêng tư của người dùng.
// Đặt tên UserFeedback (SPEC ghi Feedback) để không trùng widget Feedback của Flutter.
class UserFeedback {
  const UserFeedback({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;
}
