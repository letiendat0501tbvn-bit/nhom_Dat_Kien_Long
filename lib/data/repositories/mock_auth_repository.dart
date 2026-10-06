import '../mock/mock_support.dart';
import '../models/user.dart';
import 'auth_repository.dart';

// Bản mock của AuthRepository: đăng nhập giả lập, không cần tài khoản Google thật.
// Đăng nhập luôn trả về `signInAs` (người dùng mẫu đầu tiên nếu không chỉ định).
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    required List<User> users,
    User? signInAs,
    this.latency = randomLatency,
  }) : _users = users,
       _signInAs = signInAs ?? users.first;

  final Latency latency;
  final List<User> _users;
  final User _signInAs;
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
