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
      messages: _buildMessages(now, tables),
    );
  }
}

// ---------- Khu vực (mục 4.9 SPEC) ----------

const mockAreas = <Area>[
  Area(
    id: 'hcm-q1',
    city: 'Hồ Chí Minh',
    district: 'Quận 1',
    lat: 10.7769,
    lng: 106.7009,
  ),
  Area(
    id: 'hcm-binh-thanh',
    city: 'Hồ Chí Minh',
    district: 'Bình Thạnh',
    lat: 10.8106,
    lng: 106.7091,
  ),
  Area(
    id: 'hcm-thu-duc',
    city: 'Hồ Chí Minh',
    district: 'Thủ Đức',
    lat: 10.8494,
    lng: 106.7537,
  ),
  Area(
    id: 'hn-hoan-kiem',
    city: 'Hà Nội',
    district: 'Hoàn Kiếm',
    lat: 21.0285,
    lng: 105.8542,
  ),
  Area(
    id: 'dn-hai-chau',
    city: 'Đà Nẵng',
    district: 'Hải Châu',
    lat: 16.0678,
    lng: 108.2208,
  ),
  Area(
    id: 'hue-phu-hoi',
    city: 'Huế',
    district: 'Phú Hội',
    lat: 16.4600,
    lng: 107.5900,
  ),
  Area(
    id: 'ha-minh-an',
    city: 'Hội An',
    district: 'Minh An',
    lat: 15.8801,
    lng: 108.3380,
  ),
  Area(
    id: 'ct-ninh-kieu',
    city: 'Cần Thơ',
    district: 'Ninh Kiều',
    lat: 10.0341,
    lng: 105.7880,
  ),
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
    'Quán Nhà Lá',
    'Tiệm Hẻm Nhỏ',
    'Bếp Bà Tư',
    'Quán Gió Sài Gòn',
    'Tiệm Mười Hai',
    'Quán Góc Phố',
    'Bếp Hoa Sữa',
    'Quán Trăng Non',
    'Tiệm Lửa Hồng',
    'Quán Bốn Mùa',
  ]),
  ..._spread('hk', _area('hn-hoan-kiem'), const [
    'Quán Phố Cổ Mẫu',
    'Tiệm Hàng Mẫu',
    'Bếp Ngõ Nhỏ',
    'Quán Sen Hồ',
    'Tiệm Chiều Thu',
    'Quán Mái Ngói',
    'Bếp Cửa Đông',
    'Quán Gốc Đa',
    'Tiệm Hương Cốm',
    'Quán Mùa Đông',
  ]),
  ..._spread('bt', _area('hcm-binh-thanh'), const [
    'Quán Cầu Nhỏ',
    'Tiệm Bến Sông',
    'Bếp Chợ Mẫu',
  ]),
  ..._spread('td', _area('hcm-thu-duc'), const [
    'Quán Sân Trường',
    'Tiệm Đồi Thông',
    'Bếp Ngã Tư',
  ]),
  ..._spread('hc', _area('dn-hai-chau'), const [
    'Quán Gió Biển',
    'Tiệm Cầu Rồng Mẫu',
    'Bếp Sông Hàn',
  ]),
  ..._spread('ph', _area('hue-phu-hoi'), const [
    'Quán Vườn Cau',
    'Tiệm Mưa Huế',
    'Bếp Cố Đô Mẫu',
  ]),
  ..._spread('ma', _area('ha-minh-an'), const [
    'Quán Đèn Lồng Mẫu',
    'Tiệm Phố Cổ Nhỏ',
    'Bếp Sông Hoài Mẫu',
  ]),
  ..._spread('nk', _area('ct-ninh-kieu'), const [
    'Quán Chợ Nổi Mẫu',
    'Tiệm Bến Ninh Kiều',
    'Bếp Miệt Vườn',
  ]),
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

// Người dùng đăng nhập giả lập là Minh Anh (u1). Các người dùng mẫu còn lại (u2–u8) là
// "những người khác": chủ bàn và thành viên của các bàn mẫu đều lấy từ nhóm này.
const _meId = 'u1';

// Làm tròn LÊN bội số 15 phút tiếp theo.
DateTime _roundUp15(DateTime t) {
  final base = DateTime(t.year, t.month, t.day, t.hour, t.minute);
  final extra = (15 - base.minute % 15) % 15;
  final r = base.add(Duration(minutes: extra));
  return r.isAfter(t) ? r : r.add(const Duration(minutes: 15));
}

// (dishId, restaurantId, thời lượng, tổng chỗ, số thành viên, ghi chú)
typedef _Spec = (String, String, int, int, int, String);

// Bàn của Minh Anh: ĐÚNG hai bàn, để demo "Sắp tới" và "Đã qua".
//  - t1: Sắp tới, Minh Anh là chủ bàn, bắt đầu sau khoảng 1 giờ 45 phút, còn 1 chỗ.
//  - t2: Đã qua, đã kết thúc (bắt đầu cách đây 3 giờ, dài 60 phút), Minh Anh là thành viên.
// Hai bàn không trùng giờ nhau.
const _upcomingOffsetMin = 105;
const _pastOffsetMin = -180;

// Bàn demo CÓ CHỦ Ý trùng giờ với bàn Sắp tới của Minh Anh (t1): ở Quận 1, còn chỗ, để
// thử "Tham gia" thì thấy lỗi trùng giờ. Mọi bàn mở khác của Quận 1 KHÔNG trùng giờ với
// bàn nào của Minh Anh, nên tham gia các bàn đó sẽ thành công.
const _overlapDemoOffsetMin = 120;

List<DiningTable> _buildTables(DateTime now) {
  final base = _roundUp15(now);
  DateTime today(int offsetMin) => base.add(Duration(minutes: offsetMin));
  DateTime tomorrow(int h, int m) =>
      DateTime(now.year, now.month, now.day + 1, h, m);

  // Các bàn của người khác: (đặc tả, giờ bắt đầu). Giữ đa dạng: bàn đầy, còn 1 chỗ, sắp
  // đến giờ, hôm nay, ngày mai; nhiều bàn ở Quận 1 và Hoàn Kiếm.
  final specs = <(_Spec, DateTime)>[
    // Hôm nay (tính từ bây giờ)
    (('pho', 'q1-1', 60, 2, 2, 'Bàn đã đầy, vào danh sách chờ nhé'), today(0)),
    (('banh-mi-chao', 'q1-2', 60, 4, 3, 'Còn 1 chỗ, sắp đến giờ'), today(15)),
    (('pho', 'hk-1', 60, 3, 2, 'Còn 1 chỗ'), today(15)),
    (('bun-cha', 'hk-2', 75, 4, 1, ''), today(300)),
    (('banh-xeo', 'bt-1', 60, 4, 1, ''), today(285)),
    (('banh-khot', 'hc-1', 60, 4, 1, ''), today(285)),
    // Bàn demo trùng giờ với bàn Sắp tới của Minh Anh (xem chú thích ở trên)
    (('banh-xeo', 'q1-8', 60, 4, 2, 'Còn 2 chỗ'), today(_overlapDemoOffsetMin)),
    (('lau', 'q1-5', 120, 6, 3, 'Lẩu nhóm đông cho vui'), today(165)),
    (('goi-cuon', 'hk-4', 60, 2, 2, 'Đã đầy'), today(180)),
    (('oc', 'q1-6', 90, 2, 2, 'Đã đầy'), today(225)),
    // Ngày mai
    (('pho', 'q1-1', 60, 4, 2, 'Phở sáng trước giờ làm'), tomorrow(7, 30)),
    (('bun-cha', 'hk-2', 60, 4, 1, ''), tomorrow(12, 15)),
    (('com-tam', 'q1-2', 60, 2, 2, 'Đã đầy'), tomorrow(12, 0)),
    (('lau', 'hk-5', 120, 4, 3, 'Còn đúng 1 chỗ'), tomorrow(18, 30)),
  ];

  // Mọi bàn (kể cả hai bàn của Minh Anh). Thứ tự trong danh sách = thứ tự id (t1, t2...).
  final upcomingStart = today(_upcomingOffsetMin);
  final pastStart = today(_pastOffsetMin);
  final drafts = <_Draft>[
    // t1: Sắp tới, Minh Anh là chủ bàn, còn 1 chỗ
    _Draft(
      'bun-bo-hue',
      'q1-3',
      upcomingStart,
      60,
      4,
      3,
      'Ai thích cay thì vào nha',
      mePosition: 0,
    ),
    // t2: Đã qua, đã kết thúc; Minh Anh là thành viên, chủ bàn là người khác
    _Draft(
      'banh-xeo',
      'q1-4',
      pastStart,
      60,
      4,
      3,
      '',
      mePosition: 1,
      status: TableStatus.ended,
    ),
    for (final (spec, start) in specs)
      _Draft(spec.$1, spec.$2, start, spec.$3, spec.$4, spec.$5, spec.$6),
  ];

  // Gán người: duyệt các bàn theo giờ bắt đầu tăng dần; mỗi bàn chọn người ít bàn nhất
  // (theo thứ tự u2..u8) mà không bị trùng giờ với bàn họ đã ở. Nhờ vậy không ai bị trùng
  // giờ, ở bất kỳ thời điểm nào trong ngày.
  final others = [
    for (final u in mockUsers)
      if (u.id != _meId) u.id,
  ];
  final load = {for (final id in others) id: 0};
  final busy = {for (final id in others) id: <(DateTime, DateTime)>[]};

  final byTime = [...drafts]..sort((a, b) => a.start.compareTo(b.start));
  for (final d in byTime) {
    final end = d.start.add(Duration(minutes: d.durationMin));
    final need = d.mePosition == null ? d.count : d.count - 1;
    final free =
        [
          for (final id in others)
            if (!busy[id]!.any(
              (b) => d.start.isBefore(b.$2) && b.$1.isBefore(end),
            ))
              id,
        ]..sort(
          (a, b) => load[a]!.compareTo(load[b]!),
        ); // sort ổn định: giữ thứ tự u2..u8
    assert(free.length >= need, 'Không đủ người rảnh cho bàn mẫu');
    d.others = free.take(need).toList();
    for (final id in d.others) {
      load[id] = load[id]! + 1;
      busy[id]!.add((d.start, end));
    }
  }

  return [
    for (var i = 0; i < drafts.length; i++) drafts[i].toTable('t${i + 1}'),
  ];
}

// Bàn mẫu đang soạn. mePosition: vị trí của Minh Anh trong danh sách thành viên
// (0 = chủ bàn, 1 = thành viên thứ hai); null = bàn không có Minh Anh.
class _Draft {
  _Draft(
    this.dish,
    this.restaurant,
    this.start,
    this.durationMin,
    this.capacity,
    this.count,
    this.note, {
    this.mePosition,
    this.status,
  });

  final String dish;
  final String restaurant;
  final DateTime start;
  final int durationMin;
  final int capacity;
  final int count; // tổng số thành viên (gồm Minh Anh nếu có)
  final String note;
  final int? mePosition;
  final TableStatus? status;
  var others = <String>[]; // người khác được gán

  DiningTable toTable(String id) {
    final members = [...others];
    if (mePosition != null) members.insert(mePosition!, _meId);
    return DiningTable(
      id: id,
      dishId: dish,
      restaurantId: restaurant,
      hostId: members.first,
      startAt: start,
      durationMin: durationMin,
      capacity: capacity,
      note: note,
      status:
          status ??
          (members.length >= capacity ? TableStatus.full : TableStatus.open),
      memberIds: members,
    );
  }
}

// ---------- Tin nhắn mẫu ----------

List<ChatMessage> _buildMessages(DateTime now, List<DiningTable> tables) {
  ChatMessage m(
    String id,
    String table,
    String sender,
    String text,
    int minAgo,
  ) {
    return ChatMessage(
      id: id,
      tableId: table,
      senderId: sender,
      text: text,
      sentAt: now.subtract(Duration(minutes: minAgo)),
    );
  }

  // Tin nhắn do chính thành viên của bàn gửi: t1 (bàn Sắp tới của Minh Anh) và
  // t2 (bàn Đã qua), để demo chat và chat chỉ đọc.
  DiningTable table(String id) => tables.firstWhere((t) => t.id == id);
  final t1 = table('t1').memberIds; // [u1, a, b]
  final t2 = table('t2').memberIds; // [chủ bàn, u1, c]
  return [
    m('m1', 't1', t1[1], 'Mình ngồi bàn gần cửa, áo đỏ nha!', 40),
    m('m2', 't1', t1[2], 'Ok, mình tới trước 5 phút.', 35),
    m('m3', 't1', t1[1], 'Mình hơi trễ chút, mọi người cứ gọi trước.', 12),
    m('m4', 't2', t2[0], 'Quán này đông, mình đặt bàn tên Bảo.', 200),
    m('m5', 't2', t2[2], 'Mình ăn cay ổn nhé.', 190),
  ];
}
