import '../dish.dart';
import '../models/enums.dart';

// Giao diện lấy dữ liệu món. UI chỉ biết lớp này; bản Mock/Firebase đứng sau.
// Dùng Future để UI xử lý được trạng thái đang tải / lỗi.
//
// LƯU Ý: lớp `DishRepository` cũ trong mock_dishes.dart (đồng bộ) vẫn đang
// được màn Khám phá dùng; sẽ đổi thành MockDishRepository ở lượt sau.
abstract class DishRepository {
  Future<List<Dish>> getDishes({
    String query = '',
    String? category,
    MealTime? mealTime,
  });

  Future<Dish?> getDish(String id);

  Future<List<String>> getCategories();
}
