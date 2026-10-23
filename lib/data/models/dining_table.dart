import '../../core/entity.dart';
import '../../core/map_utils.dart';
import 'enums.dart';

// Một bàn ăn tại quán. Bất biến: mọi thay đổi đi qua copyWith.
class DiningTable extends Entity<String> {
  const DiningTable({
    required String id,
    this.dishId,
    required this.restaurantId,
    required this.hostId,
    required this.startAt,
    required this.durationMin,
    required this.capacity,
    this.note = '',
    this.status = TableStatus.open,
    required this.memberIds,
  }) : super(id);

  factory DiningTable.fromMap(String id, Map<String, dynamic> map) =>
      DiningTable(
        id: id,
        dishId: map['dishId'] as String?,
        restaurantId: map['restaurantId'] as String,
        hostId: map['hostId'] as String,
        startAt: readDate(map['startAt']),
        durationMin: readInt(map['durationMin']),
        capacity: readInt(map['capacity']),
        note: map['note'] as String? ?? '',
        status: readEnum(TableStatus.values, map['status'], TableStatus.open),
        memberIds: readStrings(map['memberIds']),
      );

  final String? dishId; // có thể chưa chọn món
  final String restaurantId;
  final String hostId;
  final DateTime startAt; // giờ Việt Nam
  final int durationMin; // 30–120
  final int capacity; // tổng chỗ, gồm cả chủ bàn (2–8)
  final String note;
  final TableStatus status;
  // Thứ tự = thứ tự vào bàn; chủ bàn đứng đầu (dùng khi chuyển quyền).
  final List<String> memberIds;

  DateTime get endAt => startAt.add(Duration(minutes: durationMin));
  int get seatsLeft => capacity - memberIds.length;
  bool get isFull => seatsLeft <= 0;

  DiningTable copyWith({
    String? hostId,
    String? note,
    TableStatus? status,
    List<String>? memberIds,
  }) {
    return DiningTable(
      id: id,
      dishId: dishId,
      restaurantId: restaurantId,
      hostId: hostId ?? this.hostId,
      startAt: startAt,
      durationMin: durationMin,
      capacity: capacity,
      note: note ?? this.note,
      status: status ?? this.status,
      memberIds: memberIds ?? this.memberIds,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    'dishId': dishId,
    'restaurantId': restaurantId,
    'hostId': hostId,
    'startAt': startAt,
    'durationMin': durationMin,
    'capacity': capacity,
    'note': note,
    'status': status.name,
    'memberIds': memberIds,
  };

  @override
  String get label => '$restaurantId @ $startAt';
}
