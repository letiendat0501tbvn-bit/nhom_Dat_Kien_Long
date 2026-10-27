import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/firestore_repo.dart';
import '../logic/account_rules.dart';
import '../mock/mock_support.dart';
import '../models/user.dart';
import 'auth_repository.dart';
import 'firebase_errors.dart';

// AuthRepository dùng Firebase Authentication (email + mật khẩu) và collection `users`
// của Firestore. Mật khẩu chỉ được chuyển cho Firebase, KHÔNG lưu ở bất kỳ đâu trong app.
// Hồ sơ người dùng (tên, email, ngày tạo) nằm ở document users/{uid}, đọc/ghi qua FirestoreRepo.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required this.auth,
    required this.users,
    this.now = systemClock,
  });

  final fb.FirebaseAuth auth;
  final FirestoreRepo<User> users; // collection 'users'
  final Clock now;

  // Hồ sơ trong Firestore; thiếu thì dựng tạm từ tài khoản Auth.
  Future<User> _profileOf(fb.User u) async {
    final doc = await users.find(u.uid);
    if (doc != null) return doc;
    return User(
      id: u.uid,
      displayName: u.displayName ?? (u.email ?? '').split('@').first,
      email: normalizeEmail(u.email ?? ''),
    );
  }

  @override
  Future<User?> getCurrentUser() => guardFirebase(() async {
    // Đợi Firebase khôi phục phiên đăng nhập cũ (nhất là trên web) rồi mới đọc currentUser
    final current = await auth.authStateChanges().first;
    return current == null ? null : _profileOf(current);
  });

  // Đăng nhập Google chưa hỗ trợ ở bản Firebase (cần thêm thư viện riêng).
  @override
  Future<User> signIn() async =>
      throw const AuthException(AuthError.notAllowed);

  @override
  Future<User> register({
    required String displayName,
    required String email,
    required String password,
  }) => guardFirebase(() async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: normalizeEmail(email),
      password: password,
    );
    final authUser = cred.user!;
    final profile = User(
      id: authUser.uid,
      displayName: normalizeName(displayName),
      email: normalizeEmail(email),
      createdAt: now(),
    );
    try {
      await authUser.updateDisplayName(profile.displayName);
      await users.set(profile); // tạo document users/{uid}
    } catch (_) {
      // Không có hồ sơ thì tài khoản dở dang: xoá luôn để người dùng đăng ký lại được
      await authUser.delete();
      rethrow;
    }
    // Firebase tự đăng nhập sau khi tạo tài khoản; app muốn quay về màn đăng nhập nên đăng xuất
    await auth.signOut();
    return profile;
  });

  @override
  Future<User> signInWithPassword({
    required String email,
    required String password,
  }) => guardFirebase(() async {
    final cred = await auth.signInWithEmailAndPassword(
      email: normalizeEmail(email),
      password: password,
    );
    return _profileOf(cred.user!);
  });

  @override
  Future<void> signOut() => guardFirebase(auth.signOut);

  @override
  Future<User?> getUser(String id) => guardFirebase(() => users.find(id));
}
