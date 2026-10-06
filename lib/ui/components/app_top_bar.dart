import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../../data/models/area.dart';
import '../theme/app_theme.dart';
import 'area_sheet.dart';
import 'dice_sheet.dart';

// Thanh trên cùng dùng chung: logo | vị trí hoặc tên app | EN | xúc xắc | hồ sơ.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    this.showLocation = true,
    this.onLocationTap,
    this.onDiceTap,
    this.onProfileTap,
  });

  // true: hiện nút "Chọn vị trí"; false: hiện tên app (như màn Hồ sơ).
  final bool showLocation;
  final VoidCallback? onLocationTap;
  final VoidCallback? onDiceTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final app = context.appState;
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
          Expanded(
            child: showLocation
                ? _locationButton(context, t, app.selectedArea)
                : _title(t),
          ),
          const SizedBox(width: 8),
          // Nút đổi ngôn ngữ: hiện mã của ngôn ngữ sẽ chuyển sang
          _circleButton(
            label: t(StrKey.semLanguage),
            onTap: app.toggleLanguage,
            child: Text(
              languageButtonLabel(app.language),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          _circleButton(
            label: t(StrKey.semDice),
            onTap: onDiceTap ?? () => showDiceSheet(context),
            color: AppColors.accent,
            child: const Icon(Icons.casino_outlined, color: AppColors.text),
          ),
          const SizedBox(width: 8),
          _circleButton(
            label: t(StrKey.semProfile),
            onTap: onProfileTap,
            child: const Icon(Icons.person_outline),
          ),
        ],
      ),
    );
  }

  Widget _title(Strings t) {
    return Text(
      t(StrKey.appNameWithEyes),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  // Nút viên thuốc: ghim + tên khu vực đã chọn (hoặc "Chọn vị trí") + mũi tên xổ xuống.
  // Bấm vào mở bảng chọn khu vực.
  Widget _locationButton(BuildContext context, Strings t, Area? area) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onLocationTap ?? () => showAreaSheet(context),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x1F000000)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  area?.district ?? t(StrKey.chooseLocation),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Nút tròn 48x48 (đủ vùng bấm tối thiểu), có nhãn cho trình đọc màn hình.
  Widget _circleButton({
    required Widget child,
    required String label,
    VoidCallback? onTap,
    Color color = Colors.white,
  }) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x1F000000)),
          ),
          child: child,
        ),
      ),
    );
  }
}
