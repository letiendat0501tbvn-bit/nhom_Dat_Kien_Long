import 'package:flutter/material.dart';

import '../components/section_heading.dart';
import '../theme/app_theme.dart';

// Màn "Hồ sơ của bạn" với 2 tab: Bàn của tôi (0) và Tài khoản (1).
// Tab Lịch hẹn ở thanh dưới mở tab 0, tab Tôi mở tab 1.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.initialTab = 1});

  final int initialTab;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late int _tab = widget.initialTab;

  // Chưa có đăng nhập thật (giai đoạn 2), nên luôn là khách.
  final bool _loggedIn = false;

  void _onLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đăng nhập Google: sẽ làm ở giai đoạn 2')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  title: 'Hồ sơ của bạn',
                  subtitle: 'Bàn ăn, phản hồi riêng tư, báo cáo và danh sách chặn.',
                ),
                const SizedBox(height: 20),
                _TabSwitcher(
                  labels: const ['Bàn của tôi', 'Tài khoản'],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                const SizedBox(height: 20),
                if (_tab == 0) _myTables() else _account(),
              ],
            ),
          ),
        ),
        const _BrandFooter(),
      ],
    );
  }

  // Tab "Bàn của tôi"
  Widget _myTables() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bàn ăn của bạn',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Text(
          _loggedIn
              ? 'Bạn chưa tham gia bàn ăn nào.' // đã đăng nhập nhưng danh sách rỗng
              : 'Đăng nhập để xem những bàn ăn của bạn.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.text.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  // Tab "Tài khoản"
  Widget _account() {
    if (_loggedIn) {
      return const Text('Đã đăng nhập'); // sẽ làm khi có đăng nhập thật
    }
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
          const Text(
            'Khách ghé chơi',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Đăng nhập để xem lại bàn, trò chuyện và quản lý phản hồi riêng tư.',
            style: TextStyle(fontSize: 16, height: 1.4),
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
              child: const Text(
                'Đăng nhập',
                style: TextStyle(fontWeight: FontWeight.bold),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF1EA),
        border: Border(top: BorderSide(color: Color(0x14000000))),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.ramen_dining,
                    size: 18, color: AppColors.primary),
              ),
              SizedBox(width: 10),
              Text(
                'Ăn Gì Đây Ta?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Món ngon • Bạn mới • Kết nối thật',
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
