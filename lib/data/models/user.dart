import '../../core/entity.dart';

// Người dùng. Khách ghé chơi (chưa đăng nhập) không có User, chỉ là null.
class User extends Entity<String> {
  const User({
    required String id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.isGuest = false,
    this.createdAt,
  }) : super(id);

  final String displayName;
  final String email;
  final String? avatarUrl; // chưa có ảnh thì UI dùng chữ cái đầu
  final bool isGuest;
  final DateTime?
  createdAt; // ngày tạo (tài khoản đăng ký mới); tài khoản mẫu để trống

  @override
  String get label => displayName;
}
