import 'package:flutter/material.dart';

import '../../data/logic/account_rules.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../theme/app_theme.dart';

// Kết quả của màn Đăng ký: email vừa đăng ký (để điền sẵn ở màn Đăng nhập), hoặc rỗng nếu
// người dùng chỉ bấm "Đã có tài khoản? Đăng nhập". Bấm Back thì kết quả là null.
class RegisterResult {
  const RegisterResult(this.email, {this.created = false});

  final String email;
  final bool created;
}

// Màn Đăng ký GIẢ LẬP (tài khoản chỉ nằm trong bộ nhớ). Đăng ký xong KHÔNG tự đăng nhập:
// quay về màn Đăng nhập với email đã điền sẵn.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  var _showPassword = false;
  var _submitting = false; // đang xử lý: chặn bấm hai lần
  var _submitted = false; // đã thử đăng ký: từ đó báo lỗi trực tiếp khi sửa
  var _issues = <AccountField, AccountIssue>{};
  AuthError?
  _authError; // lỗi chung (mất mạng, mật khẩu yếu...), hiện đã Việt hoá

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Map<AccountField, AccountIssue> _validate() => validateRegistration(
    name: _name.text,
    email: _email.text,
    password: _password.text,
    confirm: _confirm.text,
  );

  // Mỗi lần sửa: xoá lỗi chung và (nếu đã thử đăng ký) kiểm tra lại ngay.
  void _edited() {
    setState(() {
      _authError = null;
      if (_submitted) {
        _issues = _validate();
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final app = AppScope.of(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final message = context.strings(StrKey.registerSuccess);
    setState(() {
      _submitted = true;
      _authError = null;
      _issues = _validate();
    });
    if (_issues.isNotEmpty) return;
    setState(() => _submitting = true);
    try {
      final user = await app.register(
        displayName: _name.text,
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(RegisterResult(user.email, created: true));
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        if (e.error == AuthError.emailTaken) {
          _issues = {..._issues, AccountField.email: AccountIssue.emailTaken};
        } else {
          _authError = e.error;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _authError = AuthError.unknown;
      });
    }
  }

  String? _errorOf(AccountField field) {
    final issue = _issues[field];
    return issue == null ? null : context.strings.accountIssue(issue);
  }

  InputDecoration _decoration(
    String label,
    AccountField field, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      errorText: _errorOf(field),
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
    final toggle = IconButton(
      tooltip: t(_showPassword ? StrKey.hidePassword : StrKey.showPassword),
      onPressed: () => setState(() => _showPassword = !_showPassword),
      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
    );
    return Scaffold(
      appBar: AppBar(title: Text(t(StrKey.registerTitle))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t(StrKey.registerNote),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                enabled: !_submitting,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _edited(),
                decoration: _decoration(t(StrKey.fieldName), AccountField.name),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _email,
                enabled: !_submitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _edited(),
                decoration: _decoration(
                  t(StrKey.fieldEmail),
                  AccountField.email,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                enabled: !_submitting,
                obscureText: !_showPassword,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _edited(),
                decoration: _decoration(
                  t(StrKey.fieldPassword),
                  AccountField.password,
                  suffix: toggle,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirm,
                enabled: !_submitting,
                obscureText: !_showPassword,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _edited(),
                onSubmitted: (_) => _submit(),
                decoration: _decoration(
                  t(StrKey.fieldConfirm),
                  AccountField.confirm,
                ),
              ),
              if (_authError != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    t.authError(_authError!),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: const StadiumBorder(),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          t(StrKey.registerButton),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _submitting
                      ? null
                      : () =>
                            Navigator.of(context)
                                .pop(RegisterResult(_email.text.trim())),
                  child: Text(
                    t(StrKey.registerHaveAccount),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Mở màn Đăng ký. Trả về RegisterResult khi đăng ký xong hoặc bấm "Đã có tài khoản";
// null khi bấm Back.
Future<RegisterResult?> openRegister(BuildContext context) {
  return Navigator.of(context).push<RegisterResult>(
    MaterialPageRoute<RegisterResult>(builder: (_) => const RegisterScreen()),
  );
}
