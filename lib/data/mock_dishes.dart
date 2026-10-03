import 'logic/text_search.dart';
import 'mock/mock_support.dart';
import 'models/dish.dart';
import 'models/enums.dart';
import 'repositories/dish_repository.dart';

// DỮ LIỆU MẪU (mock) gồm 56 món. Mô tả của 9 món đầu (Phở, Bánh mì chảo, Bún bò Huế,
// Bánh xèo, Cơm tấm, Mì Quảng, Lẩu, Ốc, Bún chả) lấy theo web gốc; các món còn lại
// là mô tả TỰ SOẠN. Sau này thay bằng API/Firebase chỉ cần viết lớp Repository khác.

// Khẩu vị (trùng các chip ở mục "Gợi ý cho bạn")
const _cay = 'Cay tê';
const _nuong = 'Thịt nướng';
const _chay = 'Chay thanh đạm';
const _soi = 'Sợi / Nước dùng';
const _com = 'Cơm dẻo';
const _hai = 'Hải sản';
const _che = 'Chè ngọt';
const _cf = 'Cà phê đậm';

// Tâm trạng
const _am = 'Ấm bụng';
const _nhe = 'Nhẹ nhàng';
const _tu = 'Tụ tập';
const _nangLuong = 'Cần năng lượng';
const _ngot = 'Thèm ngọt';
const _giai = 'Giải nhiệt';

// Màu nền ảnh tạm theo danh mục
const _tints = <String, int>{
  'Bún & mì': 0xFFEADFCB,
  'Bánh mặn': 0xFFF3D9C4,
  'Cuốn & bánh': 0xFFF5E6A8,
  'Cơm & xôi': 0xFFE9E2D6,
  'Món lẩu': 0xFFF1CFC6,
  'Ăn vặt': 0xFFE3E8DA,
  'Đồ uống': 0xFFDDEBD2,
};

// Nhóm ở khối giới thiệu cuối trang Khám phá, suy ra từ danh mục.
const _groups = <String, String>{
  'Bún & mì': 'Món nước & sợi',
  'Bánh mặn': 'Cơm & chắc bụng',
  'Cuốn & bánh': 'Ăn vặt & trà chiều',
  'Cơm & xôi': 'Cơm & chắc bụng',
  'Món lẩu': 'Kèo tụ tập',
  'Ăn vặt': 'Ăn vặt & trà chiều',
  'Đồ uống': 'Ăn vặt & trà chiều',
};

// meals: mỗi chữ là một buổi ăn. S sáng, T trưa, X xế, O tối, K khuya.
List<MealTime> _meals(String codes) => [
      for (final c in codes.split(''))
        switch (c) {
          'S' => MealTime.morning,
          'T' => MealTime.noon,
          'X' => MealTime.afternoon,
          'O' => MealTime.evening,
          _ => MealTime.lateNight,
        },
    ];

Dish _dish(
  String id,
  String name,
  String category,
  String description,
  String emoji, {
  String? group,
  List<String> tastes = const [],
  List<String> moods = const [],
  String meals = '',
  bool hot = false,
  String? region,
  String? hashtag,
}) {
  return Dish(
    id: id,
    name: name,
    category: category,
    description: description,
    emoji: emoji,
    tint: _tints[category]!,
    group: group ?? _groups[category]!,
    tastes: tastes,
    moods: moods,
    region: region,
    hashtag: hashtag,
    isTrending: hot,
    mealTimes: _meals(meals),
  );
}

final List<Dish> kMockDishes = [
  // ---------- Bún & mì (14) ----------
  _dish('pho', 'Phở', 'Bún & mì',
      'Nước dùng thơm, bánh phở mềm, một tô thật ấm bụng.', '🍜',
      tastes: [_soi], moods: [_am, _nangLuong], meals: 'STK', hot: true),
  _dish('bun-bo-hue', 'Bún bò Huế', 'Bún & mì',
      'Sả thơm, vị cay nồng, nước dùng đậm chất Huế.', '🌶️',
      tastes: [_cay, _soi], moods: [_am, _nangLuong], meals: 'ST', hot: true),
  _dish('mi-quang', 'Mì Quảng', 'Bún & mì',
      'Sợi mì nghệ, nước nhưn đậm, bánh tráng mè giòn.', '🍝',
      tastes: [_soi], moods: [_nangLuong], meals: 'TO',
      region: 'Miền Trung', hashtag: '#CentralVietnam'),
  _dish('bun-cha', 'Bún chả', 'Bún & mì',
      'Thịt nướng thơm lừng, bún tươi và bát nước chấm — một nét quen của Hà Nội.',
      '🍖',
      tastes: [_nuong, _soi], moods: [_nangLuong, _tu], meals: 'T',
      region: 'Hà Nội', hashtag: '#HanoiClassic'),
  _dish('hu-tieu', 'Hủ tiếu', 'Bún & mì',
      'Sợi hủ tiếu dai nhẹ, nước dùng ngọt xương, ăn sáng hay khuya đều hợp.', '🍲',
      tastes: [_soi], moods: [_am], meals: 'SK'),
  _dish('bun-rieu', 'Bún riêu', 'Bún & mì',
      'Nước dùng chua nhẹ vị cua đồng, thêm cà chua và đậu phụ.', '🦀',
      tastes: [_soi, _hai], moods: [_am], meals: 'ST'),
  _dish('bun-dau-mam-tom', 'Bún đậu mắm tôm', 'Bún & mì',
      'Đậu hũ chiên giòn, bún lá, chả cơm, chấm mắm tôm đánh bông.', '🥢',
      tastes: [_nuong], moods: [_tu], meals: 'TX', hot: true),
  _dish('cao-lau', 'Cao lầu', 'Bún & mì',
      'Sợi mì dai đặc trưng Hội An, thịt xíu, rau sống và ít nước sốt.', '🍜',
      tastes: [_soi], moods: [_nhe], meals: 'T'),
  _dish('banh-canh', 'Bánh canh', 'Bún & mì',
      'Sợi bánh to bản, nước dùng sệt, ăn kèm giò heo hoặc cua.', '🍲',
      tastes: [_soi, _hai], moods: [_am], meals: 'SO'),
  _dish('hu-tieu-go', 'Hủ tiếu gõ', 'Bún & mì',
      'Tô hủ tiếu nhỏ bán dạo buổi tối, nước trong, thịt bằm thơm.', '🛵',
      tastes: [_soi], moods: [_am], meals: 'OK'),
  _dish('pho-chay', 'Phở chay', 'Bún & mì',
      'Nước dùng nấu từ rau củ, nấm và đậu hũ, thanh nhẹ dễ ăn.', '🍄',
      tastes: [_chay, _soi], moods: [_nhe], meals: 'ST'),
  _dish('bun-hue-chay', 'Bún Huế chay', 'Bún & mì',
      'Vị cay đặc trưng bún Huế nhưng nấu hoàn toàn bằng nguyên liệu chay.', '🌿',
      tastes: [_chay, _cay, _soi], moods: [_nhe], meals: 'ST'),
  _dish('mi-vit-tiem', 'Mì vịt tiềm', 'Bún & mì',
      'Vịt tiềm thuốc bắc mềm thơm, nước dùng đậm, mì vàng dai.', '🦆',
      tastes: [_soi], moods: [_am, _nangLuong], meals: 'TO'),
  _dish('bun-thit-nuong', 'Bún thịt nướng', 'Bún & mì',
      'Bún tươi, thịt nướng sém cạnh, rau sống và nước mắm chua ngọt.', '🍢',
      tastes: [_nuong], moods: [_nangLuong], meals: 'TO'),

  // ---------- Bánh mặn (7) ----------
  _dish('banh-mi-chao', 'Bánh mì chảo', 'Bánh mặn',
      'Bánh mì nóng, trứng ốp la và sốt đậm đà.', '🍳',
      tastes: [_nuong], moods: [_am, _nangLuong], meals: 'S'),
  _dish('banh-mi', 'Bánh mì', 'Bánh mặn',
      'Ổ bánh mì giòn rụm kẹp thịt, pate, rau và đồ chua.', '🥖',
      tastes: [_nuong], moods: [_nangLuong], meals: 'SK'),
  _dish('bot-chien', 'Bột chiên', 'Bánh mặn',
      'Bột chiên vàng giòn với trứng, hành lá, chấm tương ớt.', '🥚',
      tastes: [_cay], moods: [_tu], meals: 'XO'),
  _dish('banh-beo', 'Bánh bèo', 'Bánh mặn',
      'Bánh bèo chén nhỏ mềm, tôm chấy, mỡ hành, chan nước mắm ngọt.', '🥣',
      tastes: [_hai], moods: [_nhe], meals: 'SX'),
  _dish('banh-khot', 'Bánh khọt', 'Bánh mặn',
      'Bánh nhỏ vỏ giòn, nhân tôm, cuốn rau chấm nước mắm.', '🍤',
      tastes: [_hai], moods: [_tu], meals: 'TX', hot: false),
  _dish('banh-bao', 'Bánh bao', 'Bánh mặn',
      'Vỏ bánh xốp mềm, nhân thịt trứng cút nóng hổi.', '🥟',
      tastes: [], moods: [_am, _nhe], meals: 'SX'),
  _dish('banh-gio', 'Bánh giò', 'Bánh mặn',
      'Bánh gói lá chuối, nhân thịt nấm mộc nhĩ, ăn nóng buổi sáng.', '🍃',
      tastes: [], moods: [_nhe], meals: 'S'),

  // ---------- Cuốn & bánh (6) ----------
  _dish('banh-xeo', 'Bánh xèo', 'Cuốn & bánh',
      'Vỏ bánh giòn rụm, cuốn rau xanh chấm mắm.', '🥞',
      tastes: [_hai], moods: [_tu], meals: 'TO', hot: true,
      region: 'Hương vị ba miền', hashtag: '#CrispyPancakes'),
  _dish('goi-cuon', 'Gỏi cuốn', 'Cuốn & bánh',
      'Tôm, thịt, bún và rau thơm cuốn bánh tráng, chấm tương.', '🥬',
      tastes: [_hai, _chay], moods: [_nhe, _giai], meals: 'TX'),
  _dish('banh-cuon', 'Bánh cuốn', 'Cuốn & bánh',
      'Lớp bánh mỏng tráng nóng, nhân thịt nấm, ăn kèm chả và nước mắm.', '🫓',
      tastes: [], moods: [_nhe], meals: 'S'),
  _dish('nem-lui', 'Nem lụi', 'Cuốn & bánh',
      'Thịt xiên sả nướng thơm, tự cuốn bánh tráng với rau và chấm tương.', '🍢',
      tastes: [_nuong], moods: [_tu], meals: 'TO'),
  _dish('nem-ran', 'Nem rán', 'Cuốn & bánh',
      'Nem chiên vàng giòn, nhân thịt miến mộc nhĩ, chấm nước mắm chua ngọt.', '🥠',
      tastes: [], moods: [_tu], meals: 'TO'),
  _dish('bo-bia', 'Bò bía', 'Cuốn & bánh',
      'Cuốn củ sắn, lạp xưởng, trứng và rau, chấm tương ngọt.', '🌯',
      tastes: [], moods: [_nhe], meals: 'X'),

  // ---------- Cơm & xôi (7) ----------
  _dish('com-tam', 'Cơm tấm', 'Cơm & xôi',
      'Cơm tấm, sườn nướng và chút mỡ hành thơm.', '🍚',
      tastes: [_com, _nuong], moods: [_nangLuong], meals: 'STO'),
  _dish('com-ga', 'Cơm gà', 'Cơm & xôi',
      'Cơm nấu nước luộc gà, thịt gà xé và hành phi, kèm nước chấm gừng.', '🍗',
      tastes: [_com], moods: [_nangLuong], meals: 'TO'),
  _dish('xoi-man', 'Xôi mặn', 'Cơm & xôi',
      'Xôi dẻo, thịt chà bông, trứng cút, hành phi, ăn sáng chắc bụng.', '🍙',
      tastes: [_com], moods: [_nangLuong], meals: 'S'),
  _dish('com-nieu', 'Cơm niêu', 'Cơm & xôi',
      'Cơm nóng trong niêu đất cháy giòn đáy, ăn cùng món kho và canh.', '🍲',
      tastes: [_com], moods: [_am, _tu], meals: 'TO'),
  _dish('com-chien', 'Cơm chiên', 'Cơm & xôi',
      'Cơm chiên tơi hạt với trứng, lạp xưởng và rau củ.', '🍳',
      tastes: [_com], moods: [_nangLuong], meals: 'TO'),
  _dish('chao', 'Cháo', 'Cơm & xôi',
      'Cháo trắng nhừ ăn cùng thịt bằm, quẩy và hành, hợp khi mệt hay muộn.', '🥣',
      tastes: [_soi], moods: [_am, _nhe], meals: 'SK'),
  _dish('xoi-xeo', 'Xôi xéo', 'Cơm & xôi',
      'Xôi nếp vàng bùi đậu xanh, phủ hành phi, mỡ gà béo thơm.', '🌾',
      tastes: [_com, _chay], moods: [_nhe], meals: 'S'),

  // ---------- Món lẩu (5) ----------
  _dish('lau', 'Lẩu', 'Món lẩu',
      'Nồi lẩu nóng, cùng nhúng món và kể chuyện.', '🍲',
      tastes: [_cay, _soi], moods: [_tu, _am], meals: 'OK', hot: true),
  _dish('lau-thai', 'Lẩu Thái', 'Món lẩu',
      'Nước lẩu chua cay thơm sả, lá chanh, nhúng hải sản và rau.', '🌶️',
      tastes: [_cay, _hai], moods: [_tu], meals: 'O'),
  _dish('lau-bo', 'Lẩu bò', 'Món lẩu',
      'Nước dùng bò hầm ngọt, nhúng thịt bò tái, gân và rau.', '🥩',
      tastes: [_soi], moods: [_tu, _am], meals: 'O'),
  _dish('lau-nam', 'Lẩu nấm', 'Món lẩu',
      'Nồi lẩu nấm thanh ngọt, nhúng rau củ và đậu hũ, hợp ăn chay.', '🍄',
      tastes: [_chay], moods: [_tu, _nhe], meals: 'TO'),
  _dish('lau-ga-la-e', 'Lẩu gà lá é', 'Món lẩu',
      'Gà ta nấu nước lẩu thơm lá é, vị cay nhẹ, ăn kèm bún.', '🐔',
      tastes: [_cay], moods: [_tu, _am], meals: 'O'),

  // ---------- Ăn vặt (12) ----------
  _dish('oc', 'Ốc', 'Ăn vặt',
      'Một đĩa ốc, ly trà đá, chuyện trò cả buổi.', '🐚',
      group: 'Kèo tụ tập', tastes: [_hai, _cay], moods: [_tu], meals: 'OK',
      hot: true, region: 'Sài Gòn đêm', hashtag: '#StreetFoodCulture'),
  _dish('banh-trang-nuong', 'Bánh tráng nướng', 'Ăn vặt',
      'Bánh tráng nướng giòn, trứng, hành, xúc xích và sốt ớt.', '🫓',
      tastes: [_cay, _nuong], moods: [_tu], meals: 'XO', hot: true),
  _dish('banh-trang-tron', 'Bánh tráng trộn', 'Ăn vặt',
      'Bánh tráng cắt sợi trộn khô bò, trứng cút, xoài và rau răm.', '🥗',
      tastes: [_cay], moods: [_tu, _nhe], meals: 'X'),
  _dish('cha-ca', 'Chả cá', 'Ăn vặt',
      'Chả cá chiên vàng thơm thì là, ăn nóng chấm mắm tôm hoặc nước mắm.', '🐟',
      tastes: [_hai], moods: [_tu], meals: 'TO'),
  _dish('nem-chua-ran', 'Nem chua rán', 'Ăn vặt',
      'Nem chua chiên giòn bên ngoài, chua nhẹ bên trong, chấm tương ớt.', '🍡',
      tastes: [_cay], moods: [_tu], meals: 'XO'),
  _dish('ca-vien-chien', 'Cá viên chiên', 'Ăn vặt',
      'Cá viên chiên giòn xiên que, chấm tương xí muội hoặc tương ớt.', '🍢',
      tastes: [_cay], moods: [_tu], meals: 'X'),
  _dish('hot-vit-lon', 'Hột vịt lộn', 'Ăn vặt',
      'Trứng vịt lộn luộc nóng, ăn với muối tiêu chanh và rau răm.', '🥚',
      tastes: [], moods: [_nangLuong], meals: 'OK'),
  _dish('che-buoi', 'Chè bưởi', 'Ăn vặt',
      'Cùi bưởi giòn, đậu xanh, nước cốt dừa ngọt thanh.', '🍧',
      tastes: [_che], moods: [_ngot, _giai], meals: 'XO'),
  _dish('che-ba-mau', 'Chè ba màu', 'Ăn vặt',
      'Đậu đỏ, đậu xanh, thạch lá dứa, chan nước cốt dừa và đá bào.', '🍨',
      tastes: [_che], moods: [_ngot, _giai], meals: 'X'),
  _dish('che-thai', 'Chè thái', 'Ăn vặt',
      'Trái cây, thạch, nước cốt dừa và đá, mát lạnh ngày nóng.', '🥭',
      tastes: [_che], moods: [_ngot, _giai], meals: 'XO'),
  _dish('sua-chua-nep-cam', 'Sữa chua nếp cẩm', 'Ăn vặt',
      'Sữa chua mát chua nhẹ, nếp cẩm dẻo thơm bên dưới.', '🍚',
      tastes: [_che], moods: [_ngot, _nhe], meals: 'TX'),
  _dish('bap-xao', 'Bắp xào', 'Ăn vặt',
      'Bắp xào bơ, tép khô và hành lá, món ăn vặt chiều quen thuộc.', '🌽',
      tastes: [], moods: [_nhe], meals: 'X'),

  // ---------- Đồ uống (5) ----------
  _dish('tra-sua', 'Trà sữa', 'Đồ uống',
      'Trà sữa béo ngọt, thêm trân châu hoặc thạch tuỳ thích.', '🧋',
      tastes: [_che], moods: [_ngot], meals: 'XO', hot: true),
  _dish('ca-phe', 'Cà phê', 'Đồ uống',
      'Ly cà phê đậm, uống nóng hoặc đá, hợp ngồi lâu trò chuyện.', '☕',
      tastes: [_cf], moods: [_nangLuong, _nhe], meals: 'SX'),
  _dish('sinh-to-bo', 'Sinh tố bơ', 'Đồ uống',
      'Bơ xay mịn với sữa đặc, béo thơm và mát.', '🥑',
      tastes: [_che], moods: [_ngot, _giai], meals: 'X'),
  _dish('nuoc-mia', 'Nước mía', 'Đồ uống',
      'Nước mía ép tươi, thêm chút quất cho thơm, uống lạnh ngày nắng.', '🎋',
      tastes: [], moods: [_giai], meals: 'TX'),
  _dish('tra-dao', 'Trà đào', 'Đồ uống',
      'Trà đào thanh mát với miếng đào giòn và sả.', '🍑',
      tastes: [], moods: [_giai, _nhe], meals: 'XO'),
];

// Bản mock của DishRepository: dữ liệu trong bộ nhớ, có độ trễ giả.
class MockDishRepository implements DishRepository {
  MockDishRepository({this.latency = randomLatency, List<Dish>? dishes})
      : _dishes = dishes ?? kMockDishes;

  final Latency latency;
  final List<Dish> _dishes;

  @override
  Future<List<Dish>> getDishes({
    String query = '',
    String? category,
    MealTime? mealTime,
  }) async {
    await Future<void>.delayed(latency());
    return _dishes.where((d) {
      // Không phân biệt dấu/hoa thường: "pho" ra "Phở", "banh xeo" ra "Bánh xèo"
      final okName = matchesQuery(d.name, query);
      final okCategory = category == null || d.category == category;
      final okMeal = mealTime == null || d.mealTimes.contains(mealTime);
      return okName && okCategory && okMeal;
    }).toList();
  }

  @override
  Future<Dish?> getDish(String id) async {
    await Future<void>.delayed(latency());
    for (final d in _dishes) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  Future<List<String>> getCategories() async {
    await Future<void>.delayed(latency());
    return _dishes.map((d) => d.category).toSet().toList();
  }
}
