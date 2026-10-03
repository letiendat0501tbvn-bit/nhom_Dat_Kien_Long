import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../theme/app_theme.dart';

// Trạng thái tải của một danh sách.
enum LoadStatus { loading, ready, error }

// Khối dùng chung cho đủ 4 trạng thái của một danh sách:
// đang tải (vòng xoay), lỗi (thông báo + nút "Thử lại"), rỗng (câu gợi ý), có dữ liệu.
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.status,
    required this.isEmpty,
    required this.onRetry,
    required this.builder,
    this.emptyKey = StrKey.dishesEmpty,
    this.errorKey = StrKey.dishesError,
    this.padding = const EdgeInsets.symmetric(vertical: 40),
  });

  final LoadStatus status;
  final bool isEmpty; // chỉ xét khi status == ready
  final VoidCallback onRetry;
  final WidgetBuilder builder; // dựng nội dung khi có dữ liệu
  final StrKey emptyKey;
  final StrKey errorKey;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    switch (status) {
      case LoadStatus.loading:
        return Padding(
          padding: padding,
          child: const Center(child: CircularProgressIndicator()),
        );
      case LoadStatus.error:
        return Padding(
          padding: padding,
          child: Column(
            children: [
              Text(t(errorKey), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: const StadiumBorder(),
                ),
                child: Text(t(StrKey.retry)),
              ),
            ],
          ),
        );
      case LoadStatus.ready:
        if (isEmpty) {
          return Padding(
            padding: padding,
            child: Center(
              child: Text(t(emptyKey), textAlign: TextAlign.center),
            ),
          );
        }
        return builder(context);
    }
  }
}
