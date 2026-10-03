import '../models/dish.dart';
import '../models/enums.dart';

// Giao diện lấy dữ liệu món. UI chỉ biết lớp này; bản Mock/Firebase đứng sau.
// Dùng Future để UI xử lý được trạng thái đang tải / lỗi.
// Bản mock: MockDishRepository trong data/mock_dishes.dart.
abstract class DishRepository {
  Future<List<Dish>> getDishes({
    String query = '',
    String? category,
    MealTime? mealTime,
  });

  Future<Dish?> getDish(String id);

  Future<List<String>> getCategories();
}
