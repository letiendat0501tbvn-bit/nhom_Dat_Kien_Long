import 'package:flutter/material.dart';

import '../../data/models/area.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../theme/app_theme.dart';
import 'option_chips.dart';

// Bảng "Vị trí của bạn" / chọn khu vực (mục 4.9 SPEC).
// Chọn một khu vực thì ghi vào AppState và đóng bảng. "Cho phép vị trí" tạm chỉ báo
// "sẽ có ở bản sau" (chưa xin quyền thật); "Để sau" đóng bảng.
Future<void> showAreaSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _AreaSheet(),
  );
}

class _AreaSheet extends StatefulWidget {
  const _AreaSheet();

  @override
  State<_AreaSheet> createState() => _AreaSheetState();
}

class _AreaSheetState extends State<_AreaSheet> {
  var _showComingSoon = false;

  // Gom khu vực theo thành phố, giữ thứ tự xuất hiện.
  Map<String, List<Area>> _byCity(List<Area> areas) {
    final result = <String, List<Area>>{};
    for (final area in areas) {
      result.putIfAbsent(area.city, () => []).add(area);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final app = context.appState;
    final selectedId = app.selectedAreaId;
    final muted = TextStyle(
      fontSize: 14,
      color: AppColors.text.withValues(alpha: 0.7),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(StrKey.areaSheetTitle),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(StrKey.areaSheetBody),
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: FilledButton(
                          // Chưa xin quyền vị trí thật: chỉ báo ngay trong bảng
                          onPressed: () =>
                              setState(() => _showComingSoon = true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            t(StrKey.allowLocation),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            t(StrKey.maybeLater),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showComingSoon) ...[
                  const SizedBox(height: 10),
                  Text(
                    t(StrKey.locationComingSoon),
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  t(StrKey.areaOrChoose),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (app.areas.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  for (final entry in _byCity(app.areas).entries) ...[
                    // Tên thành phố và quận là dữ liệu, không dịch
                    Text(entry.key, style: muted),
                    const SizedBox(height: 6),
                    OptionChips<String>(
                      options: [
                        for (final a in entry.value) (a.id, a.district),
                      ],
                      selected: selectedId,
                      onChanged: (id) {
                        app.selectArea(id);
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                Text(t(StrKey.areaCenterNote), style: muted),
                if (selectedId != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        app.selectArea(null);
                        Navigator.of(context).pop();
                      },
                      child: Text(t(StrKey.areaClear)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
