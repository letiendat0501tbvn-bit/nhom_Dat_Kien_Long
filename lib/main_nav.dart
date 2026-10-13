import 'package:flutter/material.dart';

import 'screens/explore_screen.dart';
import 'screens/profile_screen.dart';

// Chạy bản nộp bài: flutter run -t lib/main_nav.dart
void main() => runApp(const NavApp());

class NavApp extends StatelessWidget {
  const NavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ăn gì đây ta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFC62828),
        scaffoldBackgroundColor: const Color(0xFFFFFBF7),
      ),
      home: const MainShell(),
    );
  }
}

/// Khung chính có Bottom Navigation Bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _red = Color(0xFFC62828);

  int _index = 0;

  // Nội dung 4 tab: Khám phá, Bàn ăn, Lịch hẹn, Tôi
  final _pages = const [
    ExploreScreen(),
    _Placeholder('Bàn ăn'),
    _Placeholder('Lịch hẹn'),
    ProfileScreen(),
  ];

  void _select(int i) => setState(() => _index = i);

  Widget _tab(int i, IconData icon, String label) {
    final selected = _index == i;
    return Expanded(
      child: InkWell(
        onTap: () => _select(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? _red : Colors.grey),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? _red : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: _red,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _tab(0, Icons.explore_outlined, 'Khám phá'),
            _tab(1, Icons.restaurant, 'Bàn ăn'),
            const Expanded(child: SizedBox()), // chừa chỗ cho nút +
            _tab(2, Icons.calendar_month_outlined, 'Lịch hẹn'),
            _tab(3, Icons.person_outline, 'Tôi'),
          ],
        ),
      ),
    );
  }
}

/// Màn hình tạm cho các tab chưa làm.
class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder(this.title);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}
