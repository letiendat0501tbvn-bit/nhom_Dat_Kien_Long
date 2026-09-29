import 'package:flutter/material.dart';

/// Màn hình "Tôi" - Hồ sơ của bạn (Stateless Widget).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _red = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Hồ sơ của bạn',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Bàn ăn, phản hồi riêng tư, báo cáo và danh sách chặn.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 20),
        const _SegmentedTabs(),
        const SizedBox(height: 20),
        const _GuestCard(),
      ],
    );
  }
}

/// Hai nút chuyển "Bàn của tôi" / "Tài khoản" (Stateless Widget).
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'Bàn của tôi',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Tài khoản',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ "Khách ghé chơi" kèm nút đăng nhập (Stateless Widget).
class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
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
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: ProfileScreen._red,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Đăng nhập',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
