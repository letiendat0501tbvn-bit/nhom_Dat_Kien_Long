import 'package:flutter/material.dart';

import '../ui/components/app_bottom_bar.dart';
import '../ui/components/app_top_bar.dart';
import '../ui/screens/explore_screen.dart';
import '../ui/screens/create_table_screen.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/screens/tables_screen.dart';

// Khung chính: giữ thanh dưới cố định, đổi nội dung theo tab đang chọn.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // Thanh dưới có 4 tab, nhưng Lịch hẹn (2) và Tôi (3) là CÙNG một màn Hồ sơ:
  // tab trong Hồ sơ = _index - 2.
  Widget _body() {
    switch (_index) {
      case 0:
        return const ExploreScreen();
      case 1:
        return const TablesScreen();
      default:
        return ProfileScreen(
          tab: _index - 2,
          onTabChanged: (t) => setState(() => _index = 2 + t),
          onFindTables: () => setState(() => _index = 1),
        );
    }
  }

  // Nút + mở màn "Mở bàn mới" (toàn trang, có nút Back).
  void _openCreateTable() => openCreateTable(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Tab Khám phá và Bàn ăn hiện nút vị trí; Lịch hẹn và Tôi hiện tên app
            AppTopBar(
              showLocation: _index < 2,
              onProfileTap: () => setState(() => _index = 3),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        onCreate: _openCreateTable,
      ),
    );
  }
}
