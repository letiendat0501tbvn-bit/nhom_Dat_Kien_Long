import 'dart:math';

import '../models/area.dart';
import '../models/chat_message.dart';
import '../models/dining_table.dart';
import '../models/enums.dart';
import '../models/restaurant.dart';
import '../models/user.dart';

// DỮ LIỆU MẪU TỰ SOẠN (không phải dữ liệu thật). Tên quán, người dùng đều là tên giả.
// Giờ của bàn và tin nhắn sinh theo `now` truyền vào, không viết cứng ngày.
class MockData {
  const MockData({
    required this.areas,
    required this.restaurants,
    required this.users,
    required this.tables,
    required this.messages,
  });

  final List<Area> areas;
  final List<Restaurant> restaurants;
  final List<User> users;
  final List<DiningTable> tables;
  final List<ChatMessage> messages;

  factory MockData.build(DateTime now) {
    final tables = _buildTables(now);
    return MockData(
      areas: mockAreas,
      restaurants: mockRestaurants,
      users: mockUsers,
      tables: tables,
      messages: _buildMessages(now),
    );
  }
}

// ---------- Khu vực (mục 4.9 SPEC) ----------

const mockAreas = <Area>[
  Area(id: 'hcm-q1', city: 'Hồ Chí Minh', district: 'Quận 1', lat: 10.7769, lng: 106.7009),
  Area(id: 'hcm-binh-thanh', city: 'Hồ Chí Minh', district: 'Bình Thạnh', lat: 10.8106, lng: 106.7091),
  Area(id: 'hcm-thu-duc', city: 'Hồ Chí Minh', district: 'Thủ Đức', lat: 10.8494, lng: 106.7537),
  Area(id: 'hn-hoan-kiem', city: 'Hà Nội', district: 'Hoàn Kiếm', lat: 21.0285, lng: 105.8542),
  Area(id: 'dn-hai-chau', city: 'Đà Nẵng', district: 'Hải Châu', lat: 16.0678, lng: 108.2208),
  Area(id: 'hue-phu-hoi', city: 'Huế', district: 'Phú Hội', lat: 16.4600, lng: 107.5900),
  Area(id: 'ha-minh-an', city: 'Hội An', district: 'Minh An', lat: 15.8801, lng: 108.3380),
  Area(id: 'ct-ninh-kieu', city: 'Cần Thơ', district: 'Ninh Kiều', lat: 10.0341, lng: 105.7880),
];

// ---------- Quán (tên giả) ----------

// Rải quán quanh tâm khu vực theo vòng xoắn: quán thứ i cách tâm khoảng 167 m × (i+1),
// để test bán kính 100 m / 500 m / 1 km / 10 km có kết quả khác nhau.
List<Restaurant> _spread(String prefix, Area area, List<String> names) {
  return [
    for (var i = 0; i < names.length; i++)
      Restaurant(
        id: '$prefix-${i + 1}',
        name: names[i],
        address: '${10 + i * 7} Đường Mẫu, ${area.district}, ${area.city}',
        areaId: area.id,
        lat: area.lat + 0.0015 * (i + 1) * cos(i * 2.4),
        lng: area.lng + 0.0015 * (i + 1) * sin(i * 2.4),
      ),
  ];
}

Area _area(String id) => mockAreas.firstWhere((a) => a.id == id);

final mockRestaurants = <Restaurant>[
  ..._spread('q1', _area('hcm-q1'), const [
    'Quán Nhà Lá', 'Tiệm Hẻm Nhỏ', 'Bếp Bà Tư', 'Quán Gió Sài Gòn',
    'Tiệm Mười Hai', 'Quán Góc Phố', 'Bếp Hoa Sữa', 'Quán Trăng Non',
    'Tiệm Lửa Hồng', 'Quán Bốn Mùa',
  ]),
  ..._spread('hk', _area('hn-hoan-kiem'), const [
    'Quán Phố Cổ Mẫu', 'Tiệm Hàng Mẫu', 'Bếp Ngõ Nhỏ', 'Quán Sen Hồ',
    'Tiệm Chiều Thu', 'Quán Mái Ngói', 'Bếp Cửa Đông', 'Quán Gốc Đa',
    'Tiệm Hương Cốm', 'Quán Mùa Đông',
  ]),
  ..._spread('bt', _area('hcm-binh-thanh'),
      const ['Quán Cầu Nhỏ', 'Tiệm Bến Sông', 'Bếp Chợ Mẫu']),
  ..._spread('td', _area('hcm-thu-duc'),
      const ['Quán Sân Trường', 'Tiệm Đồi Thông', 'Bếp Ngã Tư']),
  ..._spread('hc', _area('dn-hai-chau'),
      const ['Quán Gió Biển', 'Tiệm Cầu Rồng Mẫu', 'Bếp Sông Hàn']),
  ..._spread('ph', _area('hue-phu-hoi'),
      const ['Quán Vườn Cau', 'Tiệm Mưa Huế', 'Bếp Cố Đô Mẫu']),
  ..._spread('ma', _area('ha-minh-an'),
      const ['Quán Đèn Lồng Mẫu', 'Tiệm Phố Cổ Nhỏ', 'Bếp Sông Hoài Mẫu']),
  ..._spread('nk', _area('ct-ninh-kieu'),
      const ['Quán Chợ Nổi Mẫu', 'Tiệm Bến Ninh Kiều', 'Bếp Miệt Vườn']),
];

// ---------- Người dùng mẫu ----------

const mockUsers = <User>[
  User(id: 'u1', displayName: 'Minh Anh', email: 'minhanh@example.com'),
  User(id: 'u2', displayName: 'Quốc Bảo', email: 'quocbao@example.com'),
  User(id: 'u3', displayName: 'Thu Hà', email: 'thuha@example.com'),
  User(id: 'u4', displayName: 'Gia Huy', email: 'giahuy@example.com'),
  User(id: 'u5', displayName: 'Ngọc Lan', email: 'ngoclan@example.com'),
  User(id: 'u6', displayName: 'Đức Khoa', email: 'duckhoa@example.com'),
  User(id: 'u7', displayName: 'Phương Linh', email: 'phuonglinh@example.com'),
  User(id: 'u8', displayName: 'Tuấn Kiệt', email: 'tuankiet@example.com'),
];

// ---------- Bàn mẫu ----------

// Làm tròn LÊN bội số 15 phút tiếp theo.
DateTime _roundUp15(DateTime t) {
  final base = DateTime(t.year, t.month, t.day, t.hour, t.minute);
  final extra = (15 - base.minute % 15) % 15;
  final r = base.add(Duration(minutes: extra));
  return r.isAfter(t) ? r : r.add(const Duration(minutes: 15));
}

// (dishId, restaurantId, thời lượng, tổng chỗ, số thành viên, ghi chú)
typedef _Spec = (String, String, int, int, int, String);

List<DiningTable> _buildTables(DateTime now) {
  final base = _roundUp15(now);
  DateTime today(int offsetMin) => base.add(Duration(minutes: offsetMin));
  DateTime tomorrow(int h, int m) =>
      DateTime(now.year, now.month, now.day + 1, h, m);

  final specs = <(_Spec, DateTime)>[
    // Hôm nay (tính từ bây giờ)
    (('pho', 'q1-1', 60, 4, 4, 'Bàn đã đầy, vào danh sách chờ nhé'), today(0)),
    (('banh-mi-chao', 'q1-2', 60, 4, 3, 'Còn 1 chỗ, sắp đến giờ'), today(15)),
    (('bun-bo-hue', 'q1-3', 75, 6, 2, 'Ai thích cay thì vào nha'), today(30)),
    (('pho', 'hk-1', 60, 4, 3, 'Còn 1 chỗ'), today(15)),
    (('bun-cha', 'hk-2', 75, 6, 2, ''), today(45)),
    (('com-tam', 'q1-4', 60, 5, 4, 'Còn 1 chỗ'), today(75)),
    (('banh-xeo', 'bt-1', 60, 4, 2, ''), today(105)),
    (('goi-cuon', 'hk-4', 60, 5, 5, 'Đã đầy'), today(75)),
    (('mi-quang', 'td-1', 60, 3, 3, 'Đã đầy'), today(135)),
    (('banh-khot', 'hc-1', 60, 4, 2, ''), today(105)),
    (('lau', 'q1-5', 120, 8, 5, 'Lẩu nhóm đông cho vui'), today(165)),
    (('bun-bo-hue', 'ph-1', 60, 4, 3, 'Còn 1 chỗ'), today(165)),
    (('oc', 'q1-6', 90, 6, 6, 'Đã đầy'), today(225)),
    (('nem-lui', 'ma-1', 90, 6, 3, ''), today(225)),
    (('hu-tieu', 'nk-1', 60, 4, 2, ''), today(45)),
    (('ca-phe', 'hk-3', 60, 4, 1, 'Cà phê chiều, nói chuyện nhẹ nhàng'), today(315)),
    // Ngày mai
    (('pho', 'q1-1', 60, 6, 2, 'Phở sáng trước giờ làm'), tomorrow(7, 30)),
    (('bun-cha', 'hk-2', 60, 4, 2, ''), tomorrow(12, 15)),
    (('com-tam', 'q1-2', 60, 4, 4, 'Đã đầy'), tomorrow(12, 0)),
    (('tra-sua', 'q1-7', 60, 4, 1, ''), tomorrow(15, 0)),
    (('lau', 'hk-5', 120, 8, 7, 'Còn đúng 1 chỗ'), tomorrow(18, 30)),
    (('oc', 'q1-6', 90, 6, 3, 'Ốc đêm'), tomorrow(20, 0)),
  ];

  return [
    for (var i = 0; i < specs.length; i++)
      _table(i, specs[i].$1, specs[i].$2),
  ];
}

DiningTable _table(int index, _Spec s, DateTime startAt) {
  final (dishId, restaurantId, duration, capacity, count, note) = s;
  // Chủ bàn luân phiên; các thành viên là những người kế tiếp trong danh sách
  final members = [
    for (var k = 0; k < count; k++) mockUsers[(index + k) % mockUsers.length].id,
  ];
  return DiningTable(
    id: 't${index + 1}',
    dishId: dishId,
    restaurantId: restaurantId,
    hostId: members.first,
    startAt: startAt,
    durationMin: duration,
    capacity: capacity,
    note: note,
    status: count >= capacity ? TableStatus.full : TableStatus.open,
    memberIds: members,
  );
}

// ---------- Tin nhắn mẫu ----------

List<ChatMessage> _buildMessages(DateTime now) {
  ChatMessage m(String id, String table, String sender, String text, int minAgo) {
    return ChatMessage(
      id: id,
      tableId: table,
      senderId: sender,
      text: text,
      sentAt: now.subtract(Duration(minutes: minAgo)),
    );
  }

  // Bàn t2: chủ bàn u2, thành viên u2, u3, u4
  // Bàn t3: chủ bàn u3, thành viên u3, u4
  // Bàn t4: chủ bàn u4, thành viên u4, u5, u6
  return [
    m('m1', 't2', 'u2', 'Mình ngồi bàn gần cửa, áo đỏ nha!', 40),
    m('m2', 't2', 'u3', 'Ok, mình tới trước 5 phút.', 35),
    m('m3', 't2', 'u4', 'Mình hơi trễ chút, mọi người cứ gọi trước.', 12),
    m('m4', 't3', 'u3', 'Quán này cay vừa, ai ăn cay được không?', 90),
    m('m5', 't3', 'u4', 'Mình ăn cay ổn nhé.', 80),
    m('m6', 't4', 'u4', 'Mình đặt bàn tên Gia Huy.', 20),
  ];
}
