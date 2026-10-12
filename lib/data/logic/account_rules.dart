// Quy tắc kiểm tra dữ liệu đăng ký / đăng nhập (hàm thuần, dễ test).

const minNameLength = 2;
const maxNameLength = 40;
const minPasswordLength = 6;

// Các ô của form đăng ký, để báo lỗi đúng chỗ.
enum AccountField { name, email, password, confirm }

// Lý do một ô không hợp lệ.
enum AccountIssue {
  nameRequired,
  nameLength, // ngoài 2–40 ký tự sau khi cắt khoảng trắng hai đầu
  emailRequired,
  emailInvalid,
  emailTaken, // trùng với một tài khoản đã có (không phân biệt hoa thường)
  passwordRequired,
  passwordShort, // dưới 6 ký tự
  confirmRequired,
  passwordMismatch, // nhập lại không khớp
}

// Họ tên đã chuẩn hoá: cắt khoảng trắng hai đầu và gộp khoảng trắng liên tiếp bên trong.
String normalizeName(String name) =>
    name.trim().replaceAll(RegExp(r'\s+'), ' ');

// Email đã chuẩn hoá: cắt khoảng trắng hai đầu và chữ thường.
String normalizeEmail(String email) => email.trim().toLowerCase();

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@.]+(\.[^\s@.]+)+$');

// Email đúng định dạng cơ bản: có phần trước @, tên miền có ít nhất một dấu chấm, không có
// khoảng trắng. (Không cố kiểm tra mọi quy tắc của RFC.)
bool isValidEmailFormat(String email) =>
    _emailPattern.hasMatch(normalizeEmail(email));

// Email đã có trong danh sách chưa (so sánh sau khi chuẩn hoá, không phân biệt hoa thường).
bool isEmailTaken(String email, Iterable<String> existingEmails) {
  final e = normalizeEmail(email);
  return existingEmails.any((x) => normalizeEmail(x) == e);
}

AccountIssue? validateName(String name) {
  final n = normalizeName(name);
  if (n.isEmpty) return AccountIssue.nameRequired;
  if (n.length < minNameLength || n.length > maxNameLength) {
    return AccountIssue.nameLength;
  }
  return null;
}

// existingEmails: các email đã có; để rỗng nếu chỉ kiểm tra định dạng.
AccountIssue? validateEmail(
  String email, {
  Iterable<String> existingEmails = const [],
}) {
  if (email.trim().isEmpty) return AccountIssue.emailRequired;
  if (!isValidEmailFormat(email)) return AccountIssue.emailInvalid;
  if (isEmailTaken(email, existingEmails)) return AccountIssue.emailTaken;
  return null;
}

// Mật khẩu không bị cắt khoảng trắng (khoảng trắng cũng là ký tự hợp lệ).
AccountIssue? validatePassword(String password) {
  if (password.isEmpty) return AccountIssue.passwordRequired;
  if (password.length < minPasswordLength) return AccountIssue.passwordShort;
  return null;
}

AccountIssue? validateConfirm(String password, String confirm) {
  if (confirm.isEmpty) return AccountIssue.confirmRequired;
  if (confirm != password) return AccountIssue.passwordMismatch;
  return null;
}

// Kiểm tra cả form đăng ký, trả về lỗi của TỪNG ô (rỗng = hợp lệ).
Map<AccountField, AccountIssue> validateRegistration({
  required String name,
  required String email,
  required String password,
  required String confirm,
  Iterable<String> existingEmails = const [],
}) {
  final issues = <AccountField, AccountIssue>{};
  final nameIssue = validateName(name);
  if (nameIssue != null) issues[AccountField.name] = nameIssue;
  final emailIssue = validateEmail(email, existingEmails: existingEmails);
  if (emailIssue != null) issues[AccountField.email] = emailIssue;
  final passwordIssue = validatePassword(password);
  if (passwordIssue != null) issues[AccountField.password] = passwordIssue;
  final confirmIssue = validateConfirm(password, confirm);
  if (confirmIssue != null) issues[AccountField.confirm] = confirmIssue;
  return issues;
}
