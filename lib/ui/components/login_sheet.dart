import 'package:flutter/material.dart';

import '../../data/logic/account_rules.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../screens/register_screen.dart';
import '../screens/static_page_screen.dart';
import '../theme/app_theme.dart';

// Bảng đăng nhập dạng bottom sheet (mục 4.7 SPEC).
// Đăng nhập xong chỉ đóng bảng: người dùng ở lại đúng màn cũ và tự bấm lại hành động
// đang định làm. Đăng nhập KHÔNG tự tham gia hay mở bàn.
// Có hai cách: nút "Tiếp tục với Google" (giả lập, vào tài khoản mẫu) và email + mật khẩu
// (tài khoản đã đăng ký trong app). initialEmail: email điền sẵn (sau khi vừa đăng ký).
Future<void> showLoginSheet(BuildContext context, {String? initialEmail}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _LoginSheet(initialEmail: initialEmail),
  );
}

class _LoginSheet extends StatefulWidget {
  const _LoginSheet({this.initialEmail});

  final String? initialEmail;

  @override
  State<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<_LoginSheet> {
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _password = TextEditingController();
  AuthError? _googleError; // đăng nhập Google lỗi
  AuthError? _emailGeneralError; // đăng nhập email lỗi chung (mất mạng, quá nhiều lần thử...)
  var _emailSigning =
      false; // đang đăng nhập bằng email (để hiện vòng quay đúng nút)
  var _showPassword = false;
  AccountIssue? _emailIssue;
  AccountIssue? _passwordIssue;
  AuthError? _authError; // lỗi từ repository: không có email / sai mật khẩu

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final app = AppScope.of(context, listen: false);
    setState(() => _googleError = null);
    try {
      await app.signIn();
      if (mounted) Navigator.of(context).pop(); // quay lại màn cũ
    } on AuthException catch (e) {
      if (mounted) setState(() => _googleError = e.error);
    } catch (_) {
      if (mounted) setState(() => _googleError = AuthError.unknown);
    }
  }

  // Đăng nhập bằng email + mật khẩu: kiểm tra ô trước, rồi hỏi repository.
  Future<void> _signInWithEmail() async {
    final app = AppScope.of(context, listen: false);
    if (app.isSigningIn) return;
    final emailIssue = validateEmail(_email.text);
    final passwordIssue = _password.text.isEmpty
        ? AccountIssue.passwordRequired
        : null;
    setState(() {
      _emailIssue = emailIssue;
      _passwordIssue = passwordIssue;
      _authError = null;
      _emailGeneralError = null;
    });
    if (emailIssue != null || passwordIssue != null) return;
    setState(() => _emailSigning = true);
    try {
      await app.signInWithEmail(_email.text, _password.text);
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) {
        final field =
            e.error == AuthError.emailNotFound ||
            e.error == AuthError.wrongPassword;
        setState(() {
          _emailSigning = false;
          if (field) {
            _authError = e.error; // báo ngay dưới ô email/mật khẩu
          } else {
            _emailGeneralError = e.error; // lỗi chung: hiện dưới nút
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _emailSigning = false;
          _emailGeneralError = AuthError.unknown;
        });
      }
    }
  }

  // Sang màn Đăng ký; xong thì quay lại đây, điền sẵn email vừa đăng ký.
  Future<void> _openRegister() async {
    final result = await openRegister(context);
    if (!mounted || result == null) return;
    setState(() {
      if (result.email.isNotEmpty) _email.text = result.email;
      _password.clear();
      _emailIssue = null;
      _passwordIssue = null;
      _authError = null;
    });
  }

  // Mở trang chính sách / điều khoản; Back quay về bảng đăng nhập (bảng vẫn mở bên dưới).
  void _openStatic(StaticPage page) => openStaticPage(context, page);

  String? _emailError(Strings t) {
    if (_emailIssue != null) return t.accountIssue(_emailIssue!);
    if (_authError == AuthError.emailNotFound) {
      return t(StrKey.accErrEmailNotFound);
    }
    return null;
  }

  String? _passwordError(Strings t) {
    if (_passwordIssue != null) return t.accountIssue(_passwordIssue!);
    if (_authError == AuthError.wrongPassword) {
      return t(StrKey.accErrWrongPassword);
    }
    return null;
  }

  InputDecoration _decoration(String label, String? error, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      errorText: error,
      errorMaxLines: 3,
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0x1F000000)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final busy = context.appState.isSigningIn;
    return SafeArea(
      child: SingleChildScrollView(
        // Đẩy nội dung lên trên bàn phím
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t(StrKey.loginTitle),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              t(StrKey.loginBody),
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: busy ? null : _signIn,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: const StadiumBorder(),
                ),
                icon: busy && !_emailSigning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(
                  t(StrKey.continueWithGoogle),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (_googleError != null) ...[
              const SizedBox(height: 10),
              Text(
                t.authError(_googleError!),
                style: const TextStyle(color: AppColors.primary),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: Text(
                t(StrKey.loginOr),
                style: TextStyle(color: AppColors.text.withValues(alpha: 0.6)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {
                _emailIssue = null;
                _authError = null;
              }),
              decoration: _decoration(t(StrKey.fieldEmail), _emailError(t)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              enabled: !busy,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _signInWithEmail(),
              onChanged: (_) => setState(() {
                _passwordIssue = null;
                _authError = null;
              }),
              decoration: _decoration(
                t(StrKey.fieldPassword),
                _passwordError(t),
                suffix: IconButton(
                  tooltip: t(
                    _showPassword ? StrKey.hidePassword : StrKey.showPassword,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
            ),
            if (_emailGeneralError != null) ...[
              const SizedBox(height: 10),
              Text(
                t.authError(_emailGeneralError!),
                style: const TextStyle(color: AppColors.primary),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: busy ? null : _signInWithEmail,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: const StadiumBorder(),
                ),
                child: _emailSigning && busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        t(StrKey.loginEmailButton),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: busy ? null : _openRegister,
                child: Text(
                  t(StrKey.loginNoAccount),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                t(StrKey.loginNote),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _openStatic(StaticPage.privacy),
                  child: Text(t(StrKey.privacyPolicy)),
                ),
                TextButton(
                  onPressed: () => _openStatic(StaticPage.terms),
                  child: Text(t(StrKey.termsOfUse)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
