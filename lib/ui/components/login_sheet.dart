import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../../data/models/enums.dart';
import '../screens/static_page_screen.dart';
import '../theme/app_theme.dart';

// Bảng đăng nhập dạng bottom sheet (mục 4.7 SPEC).
// Đăng nhập xong chỉ đóng bảng: người dùng ở lại đúng màn cũ và tự bấm lại hành động
// đang định làm. Đăng nhập KHÔNG tự tham gia hay mở bàn.
Future<void> showLoginSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _LoginSheet(),
  );
}

class _LoginSheet extends StatefulWidget {
  const _LoginSheet();

  @override
  State<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<_LoginSheet> {
  var _failed = false;

  Future<void> _signIn() async {
    final app = AppScope.of(context, listen: false);
    setState(() => _failed = false);
    try {
      await app.signIn();
      if (mounted) Navigator.of(context).pop(); // quay lại màn cũ
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  // Mở trang chính sách / điều khoản; Back quay về bảng đăng nhập (bảng vẫn mở bên dưới).
  void _openStatic(StaticPage page) => openStaticPage(context, page);

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final busy = context.appState.isSigningIn;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
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
                icon: busy
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
            if (_failed) ...[
              const SizedBox(height: 10),
              Text(
                t(StrKey.loginFailed),
                style: const TextStyle(color: AppColors.primary),
              ),
            ],
            const SizedBox(height: 12),
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
