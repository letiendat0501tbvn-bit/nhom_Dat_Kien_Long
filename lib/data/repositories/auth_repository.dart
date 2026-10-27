import '../models/user.dart';

// Lý do một thao tác tài khoản bị từ chối.
enum AuthError {
  emailTaken, // đăng ký: email đã được dùng
  emailNotFound, // đăng nhập: không có tài khoản với email này
  wrongPassword, // đăng nhập: sai mật khẩu
  // Các lỗi chủ yếu đến từ Firebase Auth (bản Mock không phát sinh):
  invalidCredential, // email hoặc mật khẩu không đúng (Firebase không nói rõ cái nào)
  weakPassword, // mật khẩu quá yếu
  invalidEmail, // email không hợp lệ
  network, // mất mạng hoặc không kết nối được máy chủ
  tooManyRequests, // thử quá nhiều lần
  userDisabled, // tài khoản bị vô hiệu hoá
  notAllowed, // phương thức đăng nhập chưa được bật
  permissionDenied, // không có quyền (luật bảo mật của Firestore)
  unknown, // lỗi khác
}

class AuthException implements Exception {
  const AuthException(this.error);

  final AuthError error;

  @override
  String toString() => 'AuthException(${error.name})';
}

// Đăng nhập và tài khoản. Giai đoạn đầu là bản giả lập (không cần tài khoản Google thật).
abstract class AuthRepository {
  // null = khách ghé chơi (chưa đăng nhập).
  Future<User?> getCurrentUser();

  Future<User> signIn();

  // Tạo tài khoản mới. KHÔNG tự đăng nhập. Ném AuthException(emailTaken) nếu email đã có.
  Future<User> register({
    required String displayName,
    required String email,
    required String password,
  });

  // Đăng nhập bằng email + mật khẩu. Ném AuthException(emailNotFound / wrongPassword).
  Future<User> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  // Tra thông tin thành viên (tên hiển thị trong danh sách bàn, chat).
  Future<User?> getUser(String id);
}
