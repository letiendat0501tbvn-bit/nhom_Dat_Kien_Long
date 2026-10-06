import 'package:flutter/widgets.dart';

import '../l10n/strings.dart';
import 'app_state.dart';

// Đưa AppState xuống cây widget. Widget nào gọi AppScope.of(context) sẽ tự
// dựng lại khi AppState đổi (ví dụ đổi ngôn ngữ, đăng nhập).
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  // listen: false khi chỉ cần gọi hàm/lấy repository, không cần dựng lại theo thay đổi.
  static AppState of(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AppScope>()
        : context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'Không tìm thấy AppScope trên cây widget');
    return scope!.notifier!;
  }
}

extension AppContext on BuildContext {
  // Lấy AppState và đăng ký dựng lại khi nó đổi.
  AppState get appState => AppScope.of(this);

  // Bộ chuỗi theo ngôn ngữ hiện tại: final t = context.strings; t(StrKey.xxx)
  Strings get strings => AppScope.of(this).strings;
}
