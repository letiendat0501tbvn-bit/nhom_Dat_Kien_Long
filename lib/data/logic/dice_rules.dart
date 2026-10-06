import 'dart:math';

import '../models/dish.dart';
import '../models/enums.dart';

// Quy tắc cho "Lắc món" (hàm thuần, dễ test).

// Danh sách món để quay. Có chọn buổi ăn thì chỉ lấy món hợp buổi đó (mealTimes chứa buổi);
// nếu không có món nào hợp thì quay trong tất cả món và đánh dấu fallback để báo rõ cho người dùng.
({List<Dish> pool, bool fallback}) dicePool(
  List<Dish> all,
  MealTime? mealTime,
) {
  if (mealTime == null) return (pool: all, fallback: false);
  final fit = [
    for (final d in all)
      if (d.mealTimes.contains(mealTime)) d,
  ];
  if (fit.isEmpty) return (pool: all, fallback: true);
  return (pool: fit, fallback: false);
}

// Chọn ngẫu nhiên một món từ danh sách không rỗng.
Dish pickDish(List<Dish> pool, Random random) =>
    pool[random.nextInt(pool.length)];

// Dải món chạy qua màn hình trong lúc quay: [steps] món ngẫu nhiên rồi kết thúc ở [result].
List<Dish> diceReel(
  List<Dish> pool,
  Dish result,
  Random random, {
  int steps = 16,
}) => [
  for (var i = 0; i < steps; i++) pool[random.nextInt(pool.length)],
  result,
];
