import '../../core/entity.dart';
import '../../core/map_utils.dart';

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

  factory User.fromMap(String id, Map<String, dynamic> map) => User(
    id: id,
    displayName: map['displayName'] as String,
    email: map['email'] as String,
    avatarUrl: map['avatarUrl'] as String?,
    isGuest: map['isGuest'] as bool? ?? false,
    createdAt: readDateOrNull(map['createdAt']),
  );

  final String displayName;
  final String email;
  final String? avatarUrl; // chưa có ảnh thì UI dùng chữ cái đầu
  final bool isGuest;
  final DateTime?
  createdAt; // ngày tạo (tài khoản đăng ký mới); tài khoản mẫu để trống

  @override
  Map<String, dynamic> toMap() => {
    'displayName': displayName,
    'email': email,
    'avatarUrl': avatarUrl,
    'isGuest': isGuest,
    'createdAt': createdAt,
  };

  @override
  String get label => displayName;
}
