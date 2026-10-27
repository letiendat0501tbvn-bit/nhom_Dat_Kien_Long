import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:firebase_core/firebase_core.dart' show FirebaseException;

import 'auth_repository.dart';

// Đổi mã lỗi của Firebase Auth (FirebaseAuthException.code) thành AuthError để giao diện
// hiện thông báo đã Việt hoá (strings.dart). Mã lạ thì là AuthError.unknown.
AuthError authErrorFromCode(String code) {
  switch (code) {
    case 'email-already-in-use':
      return AuthError.emailTaken;
    case 'weak-password':
      return AuthError.weakPassword;
    case 'invalid-email':
      return AuthError.invalidEmail;
    case 'user-not-found':
      return AuthError.emailNotFound;
    case 'wrong-password':
      return AuthError.wrongPassword;
    case 'invalid-credential':
    case 'invalid-login-credentials':
      return AuthError.invalidCredential;
    case 'network-request-failed':
    case 'unavailable': // Firestore: không tới được máy chủ
    case 'deadline-exceeded':
      return AuthError.network;
    case 'too-many-requests':
      return AuthError.tooManyRequests;
    case 'user-disabled':
      return AuthError.userDisabled;
    case 'operation-not-allowed':
      return AuthError.notAllowed;
    case 'permission-denied':
      return AuthError.permissionDenied;
    default:
      return AuthError.unknown;
  }
}

// Bọc mọi lời gọi Firebase: lỗi của Firebase (Auth hoặc Firestore) đổi thành AuthException
// đã phân loại; AuthException giữ nguyên; lỗi lạ thành AuthError.unknown. Không để lỗi mạng
// làm app sập: giao diện luôn nhận được một lỗi đã Việt hoá hoặc trạng thái lỗi có nút Thử lại.
Future<T> guardFirebase<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on AuthException {
    rethrow;
  } on FirebaseAuthException catch (e) {
    throw AuthException(authErrorFromCode(e.code));
  } on FirebaseException catch (e) {
    throw AuthException(authErrorFromCode(e.code));
  } catch (_) {
    throw const AuthException(AuthError.unknown);
  }
}

// Lỗi khi đọc/ghi dữ liệu (không phải tài khoản): mất mạng, không đủ quyền... code là mã
// của Firebase. Giao diện không cần biết chi tiết: các danh sách hiện trạng thái lỗi kèm nút
// "Thử lại", các thao tác (tham gia, mở bàn...) hiện thông báo lỗi chung đã Việt hoá.
class DataException implements Exception {
  const DataException(this.code);

  final String code;

  @override
  String toString() => 'DataException($code)';
}

// Bọc lời gọi Firestore cho các repository dữ liệu: lỗi Firebase (mất mạng, không đủ quyền...)
// thành DataException; lỗi nghiệp vụ của chính app (TableException...) đi qua nguyên vẹn.
Future<T> guardData<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on FirebaseException catch (e) {
    throw DataException(e.code);
  }
}
