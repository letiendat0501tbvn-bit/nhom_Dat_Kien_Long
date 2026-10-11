import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Logo tròn của app (assets/images/logo.png). Chưa có file hoặc file lỗi thì hiện biểu tượng tạm.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.radius = 20});

  static const asset = 'assets/images/logo.png';

  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: Icon(Icons.ramen_dining, color: AppColors.primary, size: radius),
    );
    // Logo là hình trang trí: tên app đã có chữ bên cạnh nên không đọc cho trình đọc màn hình
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Image.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: (size * dpr).ceil(),
            errorBuilder: (_, _, _) => fallback,
          ),
        ),
      ),
    );
  }
}
