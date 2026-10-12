import '../logic/account_rules.dart';
import '../mock/mock_support.dart';
import '../models/user.dart';
import 'auth_repository.dart';

// Bản mock của AuthRepository: đăng nhập giả lập, không cần tài khoản Google thật.
// signIn (nút "Tiếp tục với Google") luôn trả về `signInAs` (người dùng mẫu đầu tiên nếu
// không chỉ định). Tài khoản đăng ký mới chỉ nằm trong bộ nhớ: còn đến khi tắt app
// (web: tải lại trang là mất).
//
// CHỈ LÀ MÔ PHỎNG: mật khẩu được giữ nguyên dạng chữ trong bộ nhớ. Bản thật phải dùng dịch
// vụ xác thực (Firebase Auth, máy chủ có băm mật khẩu...) và KHÔNG BAO GIỜ lưu mật khẩu thô.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    required List<User> users,
    User? signInAs,
    this.latency = randomLatency,
    this.now = systemClock,
  }) : _users = List.of(users),
       _signInAs = signInAs ?? users.first;

  final Latency latency;
  final Clock now;
  final List<User> _users;
  final User _signInAs;
  // Mật khẩu theo id người dùng. Tài khoản mẫu không có mật khẩu (chỉ vào bằng nút Google).
  final _passwords = <String, String>{};
  var _nextId = 1;
  User? _current; // null = khách ghé chơi

  @override
  Future<User?> getCurrentUser() async {
    await Future<void>.delayed(latency());
    return _current;
  }

  @override
  Future<User> signIn() async {
    await Future<void>.delayed(latency());
    return _current = _signInAs;
  }

  @override
  Future<User> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latency());
    // Kiểm tra trùng email với MỌI tài khoản đã có, kể cả tài khoản mẫu
    if (isEmailTaken(email, _users.map((u) => u.email))) {
      throw const AuthException(AuthError.emailTaken);
    }
    final user = User(
      id: 'r${_nextId++}', // 'r' + số: không bao giờ trùng id mẫu (u1, u2...)
      displayName: normalizeName(displayName),
      email: normalizeEmail(email),
      createdAt: now(),
    );
    _users.add(user);
    _passwords[user.id] = password;
    return user;
  }

  @override
  Future<User> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latency());
    final e = normalizeEmail(email);
    final matches = _users.where((u) => normalizeEmail(u.email) == e);
    if (matches.isEmpty) throw const AuthException(AuthError.emailNotFound);
    final user = matches.first;
    if (_passwords[user.id] != password) {
      throw const AuthException(AuthError.wrongPassword);
    }
    return _current = user;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(latency());
    _current = null;
  }

  @override
  Future<User?> getUser(String id) async {
    await Future<void>.delayed(latency());
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }
}
