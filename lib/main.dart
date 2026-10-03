import 'package:flutter/material.dart';

import 'l10n/strings.dart';
import 'navigation/main_shell.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'ui/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  // appState: truyền vào khi test (đồng hồ/độ trễ giả); mặc định dùng dữ liệu mẫu.
  const MyApp({super.key, this.appState});

  final AppState? appState;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppState _appState = widget.appState ?? AppState.mock();

  @override
  void initState() {
    super.initState();
    _appState.load(); // nạp người dùng đang đăng nhập (nếu có)
  }

  @override
  void dispose() {
    // Chỉ huỷ AppState do mình tạo; cái được truyền vào do nơi truyền quản lý.
    if (widget.appState == null) _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _appState,
      // Dựng lại MaterialApp để tiêu đề cập nhật theo ngôn ngữ
      child: Builder(
        builder: (context) => MaterialApp(
          title: context.strings(StrKey.appName),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const MainShell(),
        ),
      ),
    );
  }
}
