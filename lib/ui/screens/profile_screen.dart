import 'package:flutter/material.dart';

import '../../data/models/user.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../components/login_sheet.dart';
import '../components/section_heading.dart';
import '../theme/app_theme.dart';

// Màn "Hồ sơ của bạn" với 2 tab: Bàn của tôi (0) và Tài khoản (1).
// Tab Lịch hẹn ở thanh dưới mở tab 0, tab Tôi mở tab 1.
// Tab hiện tại do MainShell giữ (controlled) để thanh dưới luôn đồng bộ.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.tab, required this.onTabChanged});

  final int tab; // 0: Bàn của tôi, 1: Tài khoản
  final ValueChanged<int> onTabChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int get _tab => widget.tab;

  // Mở bảng đăng nhập; xong thì ở lại đúng tab này.
  void _onLogin() => showLoginSheet(context);

  void _notBuilt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.strings(StrKey.notBuiltYet))),
    );
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
                ),
                const SizedBox(height: 20),
                _TabSwitcher(
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

  // Tab "Bàn của tôi"
  Widget _myTables(Strings t, User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t(StrKey.myTablesHeading),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Text(
          // Danh sách bàn thật (Sắp tới / Đã qua) làm ở giai đoạn G
          user != null
              ? t(StrKey.myTablesMemberPlaceholder)
              : t(StrKey.myTablesGuest),
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

  // Thẻ thành viên: khung đơn giản. Phản hồi riêng tư, báo cáo, danh sách chặn
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
                          fontSize: 22, fontWeight: FontWeight.bold),
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
          ])
            // Material trong suốt để ListTile vẽ hiệu ứng bấm đúng trên nền thẻ trắng
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t(key)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _notBuilt,
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: context.appState.signOut,
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

// Thanh chuyển tab dạng viên thuốc; mục đang chọn là nút trắng nổi lên.
class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0x1F000000)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: i == selected
                        ? const [BoxShadow(color: Colors.black12, blurRadius: 6)]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: i == selected
                          ? AppColors.text
                          : AppColors.text.withValues(alpha: 0.7),
                    ),
                  ),
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
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.ramen_dining,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                t(StrKey.appName),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
