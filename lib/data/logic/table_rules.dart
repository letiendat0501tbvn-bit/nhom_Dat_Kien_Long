import 'dart:math';

import '../models/area.dart';
import '../models/dining_table.dart';
import '../models/enums.dart';
import '../models/restaurant.dart';
import '../repositories/table_repository.dart';

// Các quy tắc nghiệp vụ về bàn ăn (mục 7 SPEC), viết thành hàm thuần để dễ test.

const minCapacity = 2;
const maxCapacity = 8;
const minDurationMin = 30;
const maxDurationMin = 120;
const slotMinutes = 15; // khung 15 phút

// Các mốc giờ trong ngày theo bước 15 phút (phút tính từ 00:00), nằm trong [min, max].
List<int> timeSlots({int min = 0, int max = 1439}) => [
  for (var m = 0; m < 24 * 60; m += slotMinutes)
    if (m >= min && m <= max) m,
];

// Buổi ăn theo giờ bắt đầu: Sáng 05–10, Trưa 11–13, Xế 14–16, Tối 17–21, Khuya 22–04.
MealTime mealTimeOfHour(int hour) {
  if (hour >= 5 && hour <= 10) return MealTime.morning;
  if (hour >= 11 && hour <= 13) return MealTime.noon;
  if (hour >= 14 && hour <= 16) return MealTime.afternoon;
  if (hour >= 17 && hour <= 21) return MealTime.evening;
  return MealTime.lateNight;
}

// Khoảng cách giữa hai toạ độ (mét), công thức haversine.
double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      pow(sin(dLat / 2), 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLng / 2), 2);
  return 2 * earthRadius * asin(sqrt(a));
}

// Hai bàn có trùng khung giờ không (đầu mút chạm nhau thì không tính là trùng).
bool tablesOverlap(DiningTable a, DiningTable b) =>
    a.startAt.isBefore(b.endAt) && b.startAt.isBefore(a.endAt);

// Bàn còn hiệu lực (chưa huỷ, chưa kết thúc).
bool isActive(DiningTable t) =>
    t.status == TableStatus.open || t.status == TableStatus.full;

// Trạng thái nút ở thẻ bàn: Tham gia / Đã đầy / Đã tham gia.
enum TableJoinState { canJoin, full, joined }

// Đã ở trong bàn thì luôn là "Đã tham gia" (kể cả bàn đã đầy); chưa tham gia mà
// hết chỗ thì "Đã đầy"; còn lại là "Tham gia". Khách (userId == null) chưa bao giờ "đã tham gia".
TableJoinState joinStateOf(DiningTable table, String? userId) {
  if (userId != null && table.memberIds.contains(userId)) {
    return TableJoinState.joined;
  }
  return table.isFull ? TableJoinState.full : TableJoinState.canJoin;
}

// Bàn đã bắt đầu (hoặc đã qua) thì không tham gia/rời được nữa.
bool hasStarted(DiningTable t, DateTime now) => !t.startAt.isAfter(now);

// Trạng thái hiển thị của bàn ở màn Chi tiết bàn.
enum TableDisplayStatus { upcoming, full, started, cancelled, ended }

// Bàn đã huỷ/kết thúc thì giữ nguyên; còn hiệu lực mà đã đến giờ thì "đã bắt đầu";
// còn lại là "đã đầy" hoặc "sắp diễn ra".
TableDisplayStatus displayStatusOf(DiningTable t, DateTime now) {
  if (t.status == TableStatus.cancelled) return TableDisplayStatus.cancelled;
  if (t.status == TableStatus.ended) return TableDisplayStatus.ended;
  if (hasStarted(t, now)) return TableDisplayStatus.started;
  return t.isFull ? TableDisplayStatus.full : TableDisplayStatus.upcoming;
}

// Các thao tác một người được làm với bàn (userId null = khách).
class TableActions {
  const TableActions({
    this.canJoin = false,
    this.canLeave = false,
    this.canCancel = false,
    this.showFull = false,
  });

  final bool canJoin; // khách cũng thấy; bấm thì mở bảng đăng nhập
  final bool canLeave; // thành viên (kể cả chủ bàn)
  final bool canCancel; // chỉ chủ bàn
  final bool showFull; // hết chỗ và chưa tham gia: chỉ hiện nút "Đã đầy"

  bool get none => !canJoin && !canLeave && !canCancel && !showFull;
}

// Bàn đã huỷ, đã kết thúc hoặc đã bắt đầu thì không có thao tác nào.
TableActions tableActionsOf(DiningTable t, String? userId, DateTime now) {
  if (!isActive(t) || hasStarted(t, now)) return const TableActions();
  final member = userId != null && t.memberIds.contains(userId);
  return TableActions(
    canJoin: !member && !t.isFull,
    canLeave: member,
    canCancel: member && t.hostId == userId,
    showFull: !member && t.isFull,
  );
}

// ---------- Chat của bàn ----------

const maxChatLength = 500;

// Tin nhắn hợp lệ: không rỗng/toàn khoảng trắng và tối đa 500 ký tự.
bool isValidChatText(String text) =>
    text.trim().isNotEmpty && text.length <= maxChatLength;

// Quyền với chat của một bàn.
enum ChatAccess {
  none, // không thấy gì (bàn đã huỷ, hoặc không phải thành viên và bàn không còn nhận người)
  joinToChat, // chưa là thành viên nhưng còn tham gia được: chỉ hiện lời mời
  write, // thành viên của bàn còn hiệu lực: xem và gửi
  readOnly, // thành viên của bàn đã bắt đầu/kết thúc: chỉ xem
}

// Chỉ thành viên mới xem được chat. Bàn đã huỷ thì mất quyền xem ngay.
ChatAccess chatAccessOf(DiningTable t, String? userId, DateTime now) {
  if (t.status == TableStatus.cancelled) return ChatAccess.none;
  final member = userId != null && t.memberIds.contains(userId);
  final open = isActive(t) && !hasStarted(t, now);
  if (member) return open ? ChatAccess.write : ChatAccess.readOnly;
  return open ? ChatAccess.joinToChat : ChatAccess.none;
}

// Kiểm tra thông tin khi mở bàn; trả về lỗi đầu tiên hoặc null nếu hợp lệ.
TableError? validateNewTable({
  required DateTime now,
  required DateTime startAt,
  required int durationMin,
  required int capacity,
}) {
  if (!startAt.isAfter(now) ||
      startAt.minute % slotMinutes != 0 ||
      startAt.second != 0 ||
      startAt.millisecond != 0 ||
      durationMin < minDurationMin ||
      durationMin > maxDurationMin ||
      durationMin % slotMinutes != 0) {
    return TableError.invalidTime;
  }
  if (capacity < minCapacity || capacity > maxCapacity) {
    return TableError.invalidCapacity;
  }
  return null;
}

const maxNoteLength = 140;

// Các trường của form mở bàn, để báo lỗi đúng chỗ.
enum NewTableField { restaurant, time, duration, capacity, note }

enum NewTableIssue {
  restaurantRequired,
  timeRequired,
  timePast,
  timeStep, // không đúng bước 15 phút
  durationInvalid,
  capacityInvalid,
  noteTooLong,
  overlap, // trùng giờ với bàn khác của người mở
}

// Kiểm tra cả form mở bàn, trả về lỗi của TỪNG trường (rỗng = hợp lệ).
// overlaps: người mở đã ở bàn khác trùng giờ (do nơi gọi tính bằng hasOverlap).
Map<NewTableField, NewTableIssue> validateNewTableForm({
  required DateTime now,
  required String? restaurantId,
  required DateTime? startAt,
  required int durationMin,
  required int capacity,
  String note = '',
  bool overlaps = false,
}) {
  final issues = <NewTableField, NewTableIssue>{};
  if (restaurantId == null) {
    issues[NewTableField.restaurant] = NewTableIssue.restaurantRequired;
  }
  if (startAt == null) {
    issues[NewTableField.time] = NewTableIssue.timeRequired;
  } else if (!startAt.isAfter(now)) {
    issues[NewTableField.time] = NewTableIssue.timePast;
  } else if (startAt.minute % slotMinutes != 0 ||
      startAt.second != 0 ||
      startAt.millisecond != 0) {
    issues[NewTableField.time] = NewTableIssue.timeStep;
  } else if (overlaps) {
    issues[NewTableField.time] = NewTableIssue.overlap;
  }
  if (durationMin < minDurationMin ||
      durationMin > maxDurationMin ||
      durationMin % slotMinutes != 0) {
    issues[NewTableField.duration] = NewTableIssue.durationInvalid;
  }
  if (capacity < minCapacity || capacity > maxCapacity) {
    issues[NewTableField.capacity] = NewTableIssue.capacityInvalid;
  }
  if (note.length > maxNoteLength) {
    issues[NewTableField.note] = NewTableIssue.noteTooLong;
  }
  return issues;
}

// Người này có đang ở bàn khác trùng giờ với [target] không.
bool hasOverlap(Iterable<DiningTable> all, String userId, DiningTable target) {
  return all.any(
    (t) =>
        t.id != target.id &&
        isActive(t) &&
        t.memberIds.contains(userId) &&
        tablesOverlap(t, target),
  );
}

// Lọc bàn theo TableQuery (mục 7.6 SPEC). Chỉ giữ bàn còn hiệu lực và chưa
// bắt đầu; bàn đầy vẫn giữ lại để giao diện hiện "Đã đầy". Kết quả xếp theo giờ.
List<DiningTable> filterTables({
  required Iterable<DiningTable> tables,
  required TableQuery query,
  required Map<String, Restaurant> restaurants,
  required Map<String, Area> areas,
  required DateTime now,
  String? viewerId,
  Set<String> blockedHostIds = const {},
}) {
  final area = query.areaId == null ? null : areas[query.areaId];

  bool keep(DiningTable t) {
    if (!isActive(t) || hasStarted(t, now)) return false;
    if (query.dishId != null && t.dishId != query.dishId) return false;
    // Ẩn bàn do người đã chặn làm chủ; bàn mình đã là thành viên thì vẫn giữ để còn rời được
    if (blockedHostIds.contains(t.hostId) &&
        !(viewerId != null && t.memberIds.contains(viewerId))) {
      return false;
    }

    final restaurant = restaurants[t.restaurantId];
    if (query.areaId != null) {
      if (restaurant == null || area == null) return false;
      if (restaurant.areaId != query.areaId) return false;
      final d = distanceMeters(
        area.lat,
        area.lng,
        restaurant.lat,
        restaurant.lng,
      );
      if (d > query.radiusM) return false;
    }

    final s = t.startAt;
    if (query.mealTime != null && mealTimeOfHour(s.hour) != query.mealTime) {
      return false;
    }
    final date = query.date;
    if (date != null &&
        (s.year != date.year || s.month != date.month || s.day != date.day)) {
      return false;
    }
    final minuteOfDay = s.hour * 60 + s.minute;
    if (query.fromMinute != null && minuteOfDay < query.fromMinute!) {
      return false;
    }
    if (query.toMinute != null && minuteOfDay > query.toMinute!) return false;
    return true;
  }

  final result = tables.where(keep).toList()
    ..sort((a, b) => a.startAt.compareTo(b.startAt));
  return result;
}
