import 'dish.dart';

// DỮ LIỆU MẪU (mock). Sau này thay bằng API/Firebase chỉ cần sửa lớp này.
class DishRepository {
  const DishRepository();

  static const _dishes = <Dish>[
    Dish(
      id: 'pho',
      name: 'Phở',
      category: 'Bún & mì',
      description: 'Nước dùng thơm, bánh phở mềm, thịt bò tái chín.',
      emoji: '🍜',
      tint: 0xFFEADFCB,
    ),
    Dish(
      id: 'banh-mi-chao',
      name: 'Bánh mì chảo',
      category: 'Bánh mặn',
      description: 'Bánh mì nóng, trứng ốp la vàng, pate và xúc xích.',
      emoji: '🍳',
      tint: 0xFFF3D9C4,
    ),
    Dish(
      id: 'bun-bo-hue',
      name: 'Bún bò Huế',
      category: 'Bún & mì',
      description: 'Sả thơm, vị cay nồng, nước dùng đậm đà đặc trưng.',
      emoji: '🌶️',
      tint: 0xFFF2D6C2,
    ),
    Dish(
      id: 'banh-xeo',
      name: 'Bánh xèo',
      category: 'Cuốn & bánh',
      description: 'Vỏ bánh giòn rụm, cuốn rau sống chấm nước mắm chua ngọt.',
      emoji: '🥞',
      tint: 0xFFF5E6A8,
    ),
    Dish(
      id: 'com-tam',
      name: 'Cơm tấm',
      category: 'Cơm',
      description: 'Sườn nướng thơm lừng, bì, chả, trứng và mỡ hành.',
      emoji: '🍚',
      tint: 0xFFE9E2D6,
    ),
    Dish(
      id: 'mi-quang',
      name: 'Mì Quảng',
      category: 'Bún & mì',
      description: 'Sợi mì dày, nước sền sệt, ăn kèm bánh tráng và rau sống.',
      emoji: '🍝',
      tint: 0xFFF4DCA6,
    ),
    Dish(
      id: 'lau',
      name: 'Lẩu',
      category: 'Lẩu & nướng',
      description: 'Nồi lẩu nóng hổi, nhiều topping, hợp ăn nhóm đông người.',
      emoji: '🍲',
      tint: 0xFFF1CFC6,
    ),
    Dish(
      id: 'oc',
      name: 'Ốc',
      category: 'Ăn vặt',
      description: 'Ốc xào, ốc luộc chấm muối ớt, nhâm nhi cùng bạn bè.',
      emoji: '🐚',
      tint: 0xFFE3E8DA,
    ),
    Dish(
      id: 'goi-cuon',
      name: 'Gỏi cuốn',
      category: 'Cuốn & bánh',
      description: 'Tôm, thịt, bún và rau thơm cuốn bánh tráng, chấm tương.',
      emoji: '🥬',
      tint: 0xFFDDEBD2,
    ),
  ];

  // Lấy danh sách món, có thể lọc theo từ khoá tên và danh mục.
  List<Dish> getDishes({String query = '', String? category}) {
    final q = query.trim().toLowerCase();
    return _dishes.where((d) {
      final okName = q.isEmpty || d.name.toLowerCase().contains(q);
      final okCategory = category == null || d.category == category;
      return okName && okCategory;
    }).toList();
  }

  // Các danh mục có trong dữ liệu, dùng cho bộ lọc.
  List<String> get categories =>
      _dishes.map((d) => d.category).toSet().toList();
}
