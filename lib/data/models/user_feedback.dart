import '../../core/entity.dart';
import '../../core/map_utils.dart';

// Phản hồi riêng tư của người dùng.
// Đặt tên UserFeedback (SPEC ghi Feedback) để không trùng widget Feedback của Flutter.
class UserFeedback extends Entity<String> {
  const UserFeedback({
    required String id,
    required this.userId,
    required this.text,
    required this.createdAt,
  }) : super(id);

  factory UserFeedback.fromMap(String id, Map<String, dynamic> map) =>
      UserFeedback(
        id: id,
        userId: map['userId'] as String,
        text: map['text'] as String,
        createdAt: readDate(map['createdAt']),
      );

  final String userId;
  final String text;
  final DateTime createdAt;

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'text': text,
    'createdAt': createdAt,
  };

  @override
  String get label => text;
}
