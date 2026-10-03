import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../components/dish_picker.dart';

// Màn "Tất cả món ngon": danh sách đầy đủ, dùng lại DishPicker không giới hạn số món
// nên có sẵn tìm kiếm không dấu và bảng lọc buổi ăn như màn chính.
class AllDishesScreen extends StatelessWidget {
  const AllDishesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(t(StrKey.allDishesTitle))),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: DishPicker(),
      ),
    );
  }
}

// Mở màn "Tất cả món ngon".
void openAllDishes(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const AllDishesScreen()));
}
