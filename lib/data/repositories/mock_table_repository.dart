import '../logic/table_rules.dart';
import '../mock/mock_support.dart';
import '../models/area.dart';
import '../models/dining_table.dart';
import '../models/enums.dart';
import '../models/restaurant.dart';
import 'table_repository.dart';

// Bản mock của TableRepository: bàn lưu trong bộ nhớ, áp dụng quy tắc mục 7 SPEC.
// `now` và `latency` truyền vào được để test dùng giờ cố định, không chờ.
class MockTableRepository implements TableRepository {
  MockTableRepository({
    required List<DiningTable> tables,
    required List<Restaurant> restaurants,
    required List<Area> areas,
    this.now = systemClock,
    this.latency = randomLatency,
    this.blockedIdsOf,
  }) : _tables = List.of(tables),
       _restaurants = {for (final r in restaurants) r.id: r},
       _areas = {for (final a in areas) a.id: a};

  final Clock now;
  final Latency latency;
  // Id những người mà một người dùng đã chặn (để ẩn bàn và chặn tham gia). null: không ai bị chặn.
  final Future<Set<String>> Function(String userId)? blockedIdsOf;
  final List<DiningTable> _tables;
  final Map<String, Restaurant> _restaurants;
  final Map<String, Area> _areas;
  var _nextId = 1000;

  Future<void> _wait() => Future<void>.delayed(latency());

  int _indexOf(String id) {
    final i = _tables.indexWhere((t) => t.id == id);
    if (i < 0) throw const TableException(TableError.notFound);
    return i;
  }

  // Bàn phải còn mở và chưa bắt đầu thì mới tham gia/rời được.
  // Báo riêng từng lý do để giao diện nói đúng: đã huỷ / đã kết thúc / đã bắt đầu.
  void _ensureOpenForChange(DiningTable t) {
    if (t.status == TableStatus.cancelled) {
      throw const TableException(TableError.cancelled);
    }
    if (t.status == TableStatus.ended) {
      throw const TableException(TableError.ended);
    }
    if (hasStarted(t, now())) {
      throw const TableException(TableError.alreadyStarted);
    }
  }

  // Cập nhật bàn trong danh sách và trả về bản mới.
  DiningTable _save(int index, DiningTable t) {
    _tables[index] = t;
    return t;
  }

  @override
  Future<List<DiningTable>> getTables(TableQuery query) async {
    await _wait();
    final viewer = query.viewerId;
    final lookup = blockedIdsOf;
    return filterTables(
      tables: _tables,
      query: query,
      restaurants: _restaurants,
      areas: _areas,
      now: now(),
      viewerId: viewer,
      blockedHostIds: viewer == null || lookup == null
          ? const {}
          : await lookup(viewer),
    );
  }

  @override
  Future<DiningTable?> getTable(String id) async {
    await _wait();
    for (final t in _tables) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  Future<List<DiningTable>> getMyTables(String userId) async {
    await _wait();
    return _tables.where((t) => t.memberIds.contains(userId)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  @override
  Future<DiningTable> createTable({
    required String hostId,
    String? dishId,
    required String restaurantId,
    required DateTime startAt,
    required int durationMin,
    required int capacity,
    String note = '',
  }) async {
    await _wait();
    final error = validateNewTable(
      now: now(),
      startAt: startAt,
      durationMin: durationMin,
      capacity: capacity,
    );
    if (error != null) throw TableException(error);

    final table = DiningTable(
      id: 't${_nextId++}',
      dishId: dishId,
      restaurantId: restaurantId,
      hostId: hostId,
      startAt: startAt,
      durationMin: durationMin,
      capacity: capacity,
      note: note,
      memberIds: [hostId], // chủ bàn là thành viên đầu tiên
    );
    if (hasOverlap(_tables, hostId, table)) {
      throw const TableException(TableError.overlap);
    }
    _tables.add(table);
    return table;
  }

  @override
  Future<DiningTable> joinTable(String tableId, String userId) async {
    await _wait();
    final i = _indexOf(tableId);
    final t = _tables[i];
    _ensureOpenForChange(t);
    if (t.memberIds.contains(userId)) {
      throw const TableException(TableError.alreadyMember);
    }
    // Không tham gia được bàn của người mình đã chặn
    final lookup = blockedIdsOf;
    if (lookup != null && (await lookup(userId)).contains(t.hostId)) {
      throw const TableException(TableError.blockedHost);
    }
    if (t.isFull) throw const TableException(TableError.full);
    if (hasOverlap(_tables, userId, t)) {
      throw const TableException(TableError.overlap);
    }

    final members = [...t.memberIds, userId];
    final full = members.length >= t.capacity;
    return _save(
      i,
      t.copyWith(
        memberIds: members,
        status: full ? TableStatus.full : TableStatus.open,
      ),
    );
  }

  @override
  Future<DiningTable> leaveTable(String tableId, String userId) async {
    await _wait();
    final i = _indexOf(tableId);
    final t = _tables[i];
    if (!t.memberIds.contains(userId)) {
      throw const TableException(TableError.notMember);
    }
    _ensureOpenForChange(t);

    final remaining = t.memberIds.where((m) => m != userId).toList();
    // Chủ bàn rời mà không còn ai: bàn tự huỷ
    if (remaining.isEmpty) {
      return _save(
        i,
        t.copyWith(memberIds: remaining, status: TableStatus.cancelled),
      );
    }
    // Chủ bàn rời: chuyển quyền cho người vào bàn sớm nhất (đứng đầu danh sách còn lại)
    final newHost = userId == t.hostId ? remaining.first : t.hostId;
    return _save(
      i,
      t.copyWith(
        hostId: newHost,
        memberIds: remaining,
        status: TableStatus.open, // vừa trả lại một chỗ
      ),
    );
  }

  @override
  Future<DiningTable> cancelTable(String tableId, String userId) async {
    await _wait();
    final i = _indexOf(tableId);
    final t = _tables[i];
    if (t.hostId != userId) throw const TableException(TableError.notHost);
    _ensureOpenForChange(t);
    return _save(i, t.copyWith(status: TableStatus.cancelled));
  }
}
