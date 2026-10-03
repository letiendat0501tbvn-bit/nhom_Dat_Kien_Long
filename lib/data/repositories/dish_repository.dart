import '../models/dish.dart';
import '../models/enums.dart';

// Giao diện lấy dữ liệu món. UI chỉ biết lớp này; bản Mock/Firebase đứng sau.
// Dùng Future để UI xử lý được trạng thái đang tải / lỗi.
// Bản mock: MockDishRepository trong data/mock_dishes.dart.
abstract class DishRepository {
  // Các điều kiện kết hợp với nhau (và). onlyTrending: chỉ món "đang hot".
  Future<List<Dish>> getDishes({
    String query = '',
    String? category,
    MealTime? mealTime,
    Taste? taste,
    Mood? mood,
    bool onlyTrending = false,
  });

  // Các món của mục "Gói trọn hương vị ba miền", theo thứ tự hiển thị.
  Future<List<Dish>> getRegionalDishes();

  Future<Dish?> getDish(String id);

  Future<List<String>> getCategories();
}
