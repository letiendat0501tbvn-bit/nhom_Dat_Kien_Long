import '../models/user.dart';

// Đăng nhập. Giai đoạn đầu là bản giả lập (không cần tài khoản Google thật).
abstract class AuthRepository {
  // null = khách ghé chơi (chưa đăng nhập).
  Future<User?> getCurrentUser();

  Future<User> signIn();

  Future<void> signOut();

  // Tra thông tin thành viên (tên hiển thị trong danh sách bàn, chat).
  Future<User?> getUser(String id);
}
