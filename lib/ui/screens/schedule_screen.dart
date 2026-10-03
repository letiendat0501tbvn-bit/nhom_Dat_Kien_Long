import 'package:flutter/material.dart';

import 'profile_screen.dart';

// Tab Lịch hẹn: dùng chung màn Hồ sơ, mở sẵn tab "Bàn của tôi".
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen(initialTab: 0);
  }
}
