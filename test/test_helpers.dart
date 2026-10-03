import 'package:flutter/material.dart';

import 'package:giua_ki_app/data/mock/mock_support.dart';
import 'package:giua_ki_app/state/app_scope.dart';
import 'package:giua_ki_app/state/app_state.dart';

// Giờ cố định dùng chung cho test: thứ Hai 05/10/2026, 10:00.
final testNow = DateTime(2026, 10, 5, 10, 0);

// AppState dùng dữ liệu mẫu, giờ cố định, không có độ trễ.
AppState makeAppState({Latency latency = noLatency}) =>
    AppState.mock(now: () => testNow, latency: latency);

// Bọc một widget trong AppScope + MaterialApp để test riêng từng widget.
Widget wrapWithApp(Widget child, {AppState? app}) {
  return AppScope(
    state: app ?? makeAppState(),
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}
