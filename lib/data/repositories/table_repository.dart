import '../models/dining_table.dart';
import '../models/enums.dart';

// Điều kiện lọc bàn (mục 7.6 SPEC). Trường nào null thì không lọc theo trường đó.
class TableQuery {
  const TableQuery({
    this.areaId,
    this.dishId,
    this.mealTime,
    this.date,
    this.fromMinute,
    this.toMinute,
    this.radiusM = 1000,
    this.viewerId,
  });

  final String? areaId;
  final String? dishId;
  final MealTime? mealTime;
  final DateTime? date; // chỉ phần ngày có ý nghĩa
  final int? fromMinute; // phút trong ngày, 0–1439
  final int? toMinute;
  final int radiusM;
  // Người đang xem: bàn do người họ đã chặn làm chủ bị ẩn (trừ bàn họ đã là thành viên).
  final String? viewerId;
}

// Lý do một thao tác với bàn bị từ chối (quy tắc mục 7 SPEC).
enum TableError {
  notFound,
  full,
  alreadyStarted, // bàn còn hiệu lực nhưng đã đến giờ bắt đầu
  cancelled, // chủ bàn đã huỷ bàn
  ended, // bàn đã kết thúc
  overlap, // trùng khung giờ với bàn khác của người này
  invalidTime, // quá khứ, sai bước 15 phút hoặc thời lượng ngoài 30–120
  invalidCapacity, // ngoài 2–8 chỗ
  alreadyMember,
  notMember,
  notHost,
  blockedHost, // chủ bàn là người bạn đã chặn
}

class TableException implements Exception {
  const TableException(this.error);

  final TableError error;

  @override
  String toString() => 'TableException(${error.name})';
}

// Giao diện bàn ăn. Các hàm thay đổi dữ liệu ném TableException khi vi phạm quy tắc.
abstract class TableRepository {
  Future<List<DiningTable>> getTables(TableQuery query);

  Future<DiningTable?> getTable(String id);

  // Bàn người dùng đã mở hoặc đã tham gia (cho tab "Bàn của tôi").
  Future<List<DiningTable>> getMyTables(String userId);

  // Người mở bàn tự động là thành viên đầu tiên và là chủ bàn.
  Future<DiningTable> createTable({
    required String hostId,
    String? dishId,
    required String restaurantId,
    required DateTime startAt,
    required int durationMin,
    required int capacity,
    String note = '',
  });

  Future<DiningTable> joinTable(String tableId, String userId);

  // Chủ bàn rời: chuyển quyền cho thành viên vào sớm nhất; chỉ còn chủ bàn thì huỷ bàn.
  Future<DiningTable> leaveTable(String tableId, String userId);

  // Chỉ chủ bàn được huỷ.
  Future<DiningTable> cancelTable(String tableId, String userId);
}
