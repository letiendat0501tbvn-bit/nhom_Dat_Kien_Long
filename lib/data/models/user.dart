// Người dùng. Khách ghé chơi (chưa đăng nhập) không có User, chỉ là null.
class User {
  const User({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.isGuest = false,
    this.createdAt,
  });

  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl; // chưa có ảnh thì UI dùng chữ cái đầu
  final bool isGuest;
  final DateTime?
  createdAt; // ngày tạo (tài khoản đăng ký mới); tài khoản mẫu để trống
}
