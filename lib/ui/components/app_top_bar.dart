import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Thanh trên cùng dùng chung: logo | vị trí hoặc tên app | EN | xúc xắc | hồ sơ.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    this.showLocation = true,
    this.onLocationTap,
    this.onLanguageTap,
    this.onDiceTap,
    this.onProfileTap,
  });

  // true: hiện nút "Chọn vị trí"; false: hiện tên app (như màn Hồ sơ).
  final bool showLocation;
  final VoidCallback? onLocationTap;
  final VoidCallback? onLanguageTap;
  final VoidCallback? onDiceTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: Color(0x14000000))),
      ),
      child: Row(
        children: [
          // Logo tròn (chưa có ảnh logo nên dùng biểu tượng tạm)
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.ramen_dining, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(child: showLocation ? _locationButton() : _title()),
          const SizedBox(width: 8),
          _circleButton(
            onTap: onLanguageTap,
            child: const Text('EN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          _circleButton(
            onTap: onDiceTap,
            color: AppColors.accent,
            child: const Icon(Icons.casino_outlined, color: AppColors.text),
          ),
          const SizedBox(width: 8),
          _circleButton(
            onTap: onProfileTap,
            child: const Icon(Icons.person_outline),
          ),
        ],
      ),
    );
  }

  Widget _title() {
    return const Text(
      'Ăn Gì Đây Ta? 👀',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  // Nút viên thuốc: ghim + "Chọn vị trí" + mũi tên xổ xuống
  Widget _locationButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onLocationTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x1F000000)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Chọn vị trí',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.keyboard_arrow_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton({
    required Widget child,
    VoidCallback? onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x1F000000)),
        ),
        child: child,
      ),
    );
  }
}
