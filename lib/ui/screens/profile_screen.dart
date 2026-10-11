import 'package:flutter/material.dart';

import '../../data/models/user.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../components/app_logo.dart';
import '../components/login_sheet.dart';
import '../components/my_tables.dart';
import '../components/pill_tabs.dart';
import '../components/section_heading.dart';
import '../theme/app_theme.dart';
import 'feedback_screen.dart';
import 'static_page_screen.dart';
import 'block_list_screen.dart';
import 'reports_sent_screen.dart';

// Màn "Hồ sơ của bạn" với 2 tab: Bàn của tôi (0) và Tài khoản (1).
// Tab Lịch hẹn ở thanh dưới mở tab 0, tab Tôi mở tab 1.
// Tab hiện tại do MainShell giữ (controlled) để thanh dưới luôn đồng bộ.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.tab,
    required this.onTabChanged,
    this.onFindTables,
  });

  final int tab; // 0: Bàn của tôi, 1: Tài khoản
  final ValueChanged<int> onTabChanged;
  final VoidCallback?
  onFindTables; // nút "Tìm bàn ăn" ở trạng thái rỗng của Bàn của tôi

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int get _tab => widget.tab;

  // Mở bảng đăng nhập; xong thì ở lại đúng tab này.
  void _onLogin() => showLoginSheet(context);

  // Đăng xuất có hộp xác nhận; xong thì về trạng thái khách.
  Future<void> _confirmSignOut() async {
    final t = context.strings;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(t(StrKey.signOutTitle)),
        content: Text(t(StrKey.signOutBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t(StrKey.dialogCancel)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(t(StrKey.signOut)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await context.appState.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final user = context.appState.currentUser; // null = khách
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  title: t(StrKey.profileTitle),
                  subtitle: t(StrKey.profileSubtitle),
                  titleSize: 35, // to hơn các tiêu đề khác, theo lich-hen.jpg và toi.jpg
                ),
                const SizedBox(height: 20),
                PillTabs(
                  labels: [t(StrKey.tabMyTables), t(StrKey.tabAccount)],
                  selected: _tab,
                  onChanged: widget.onTabChanged,
                ),
                const SizedBox(height: 20),
                if (_tab == 0) _myTables(t, user) else _account(t, user),
              ],
            ),
          ),
        ),
        const _BrandFooter(),
      ],
    );
  }

  // Tab "Bàn của tôi": khách thấy lời mời đăng nhập (như ảnh), thành viên thấy danh sách bàn.
  Widget _myTables(Strings t, User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t(StrKey.myTablesHeading),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        if (user != null)
          MyTables(userId: user.id, onFindTables: widget.onFindTables)
        else
          Text(
            t(StrKey.myTablesGuest),
            style: TextStyle(
              fontSize: 16,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
      ],
    );
  }

  // Tab "Tài khoản"
  Widget _account(Strings t, User? user) {
    if (user != null) return _memberCard(t, user);
    // Khách: thẻ "Khách ghé chơi" như ảnh, mục "Thông tin" xếp ngay dưới
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _guestCard(t),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x1F000000)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t(StrKey.infoTitle)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openInfo(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _guestCard(Strings t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1F000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(StrKey.guestTitle),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            t(StrKey.guestBody),
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _onLogin,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const StadiumBorder(),
              ),
              child: Text(
                t(StrKey.signIn),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Thẻ thành viên. Báo cáo đã gửi và Danh sách chặn mở màn riêng; Phản hồi riêng tư
  // chưa có nội dung (làm ở giai đoạn G).
  Widget _memberCard(Strings t, User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1F000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Chưa có ảnh đại diện thật: dùng chữ cái đầu của tên
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.selectedBg,
                child: Text(
                  user.displayName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.text.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final key in const [
            StrKey.privateFeedback,
            StrKey.reportsSent,
            StrKey.blockList,
            StrKey.infoTitle,
          ])
            // Material trong suốt để ListTile vẽ hiệu ứng bấm đúng trên nền thẻ trắng
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t(key)),
                trailing: const Icon(Icons.chevron_right),
                onTap: switch (key) {
                  StrKey.reportsSent => () => openReportsSent(context),
                  StrKey.blockList => () => openBlockList(context),
                  StrKey.infoTitle => () => openInfo(context),
                  _ => () => openFeedback(context),
                },
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _confirmSignOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: const StadiumBorder(),
              ),
              child: Text(
                t(StrKey.signOut),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Khối thương hiệu ở cuối trang, ngay trên thanh dưới (như trong ảnh).
class _BrandFooter extends StatelessWidget {
  const _BrandFooter();

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF1EA),
        border: Border(top: BorderSide(color: Color(0x14000000))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(radius: 16),
              const SizedBox(width: 10),
              Text(
                t(StrKey.appName),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t(StrKey.tagline),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
