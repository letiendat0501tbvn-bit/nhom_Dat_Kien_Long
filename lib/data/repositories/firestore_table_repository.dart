import '../../core/firestore_repo.dart';
import '../logic/table_rules.dart';
import '../mock/mock_support.dart';
import '../models/area.dart';
import '../models/dining_table.dart';
import '../models/enums.dart';
import '../models/restaurant.dart';
import 'firebase_errors.dart';
import 'table_repository.dart';

// TableRepository lưu bàn ăn ở collection Firestore `tables`.
// Mọi quy tắc nằm ở table_rules.dart (2–8 chỗ, khung 15 phút, giờ ở tương lai, không trùng giờ,
// chuyển chủ bàn khi chủ rời...) và được kiểm tra TRƯỚC khi ghi; các thao tác sửa bàn chạy trong
// transaction của Firestore nên hai người cùng tham gia chỗ cuối không cùng vào được.
//
// shortcut: getTables đọc cả collection rồi lọc trong bộ nhớ (đủ cho vài trăm bàn);
// khi dữ liệu lớn thì lọc ở máy chủ bằng truy vấn có chỉ mục.
class FirestoreTableRepository implements TableRepository {
  FirestoreTableRepository({
    required this.tables,
    required this.restaurants,
    required this.areas,
    this.now = systemClock,
    this.blockedIdsOf,
  });

  final FirestoreRepo<DiningTable> tables; // collection 'tables'
  final FirestoreRepo<Restaurant> restaurants; // collection 'restaurants'
  final FirestoreRepo<Area> areas; // collection 'areas'
  final Clock now;
  // Id những người mà một người dùng đã chặn (để ẩn bàn và chặn tham gia). null: không ai bị chặn.
  final Future<Set<String>> Function(String userId)? blockedIdsOf;

  @override
  Future<List<DiningTable>> getTables(TableQuery query) => guardData(() async {
    final viewer = query.viewerId;
    final lookup = blockedIdsOf;
    final (all, rs, areaList) = await (
      tables.all(),
      restaurants.all(),
      areas.all(),
    ).wait;
    return filterTables(
      tables: all,
      query: query,
      restaurants: {for (final r in rs) r.id: r},
      areas: {for (final a in areaList) a.id: a},
      now: now(),
      viewerId: viewer,
      blockedHostIds: viewer == null || lookup == null
          ? const {}
          : await lookup(viewer),
    );
  });

  @override
  Future<DiningTable?> getTable(String id) => guardData(() => tables.find(id));

  @override
  Future<List<DiningTable>> getMyTables(String userId) => guardData(() async {
    final mine = await tables.where('memberIds', arrayContains: userId);
    return mine..sort((a, b) => a.startAt.compareTo(b.startAt));
  });

  @override
  Future<DiningTable> createTable({
    required String hostId,
    String? dishId,
    required String restaurantId,
    required DateTime startAt,
    required int durationMin,
    required int capacity,
    String note = '',
  }) => guardData(() async {
    final error = validateNewTable(
      now: now(),
      startAt: startAt,
      durationMin: durationMin,
      capacity: capacity,
    );
    if (error != null) throw TableException(error);

    final table = DiningTable(
      id: tables.newId(),
      dishId: dishId,
      restaurantId: restaurantId,
      hostId: hostId,
      startAt: startAt,
      durationMin: durationMin,
      capacity: capacity,
      note: note,
      memberIds: [hostId], // chủ bàn là thành viên đầu tiên
    );
    final mine = await tables.where('memberIds', arrayContains: hostId);
    if (hasOverlap(mine, hostId, table)) {
      throw const TableException(TableError.overlap);
    }
    await tables.add(table);
    return table;
  });

  @override
  Future<DiningTable> joinTable(String tableId, String userId) =>
      guardData(() async {
        final t = await _require(tableId);
        ensureOpenForChange(t, now());
        if (t.memberIds.contains(userId)) {
          throw const TableException(TableError.alreadyMember);
        }
        // Không tham gia được bàn của người mình đã chặn
        final lookup = blockedIdsOf;
        if (lookup != null && (await lookup(userId)).contains(t.hostId)) {
          throw const TableException(TableError.blockedHost);
        }
        if (t.isFull) throw const TableException(TableError.full);
        final mine = await tables.where('memberIds', arrayContains: userId);
        if (hasOverlap(mine, userId, t)) {
          throw const TableException(TableError.overlap);
        }
        // Kiểm tra lại trong transaction: bàn có thể vừa đầy/huỷ/bắt đầu từ lúc đọc ở trên
        return tables.update(tableId, (cur) {
          ensureOpenForChange(cur, now());
          if (cur.memberIds.contains(userId)) {
            throw const TableException(TableError.alreadyMember);
          }
          if (cur.isFull) throw const TableException(TableError.full);
          return tableAfterJoin(cur, userId);
        });
      });

  @override
  Future<DiningTable> leaveTable(String tableId, String userId) =>
      guardData(() async {
        await _require(tableId);
        return tables.update(tableId, (cur) {
          if (!cur.memberIds.contains(userId)) {
            throw const TableException(TableError.notMember);
          }
          ensureOpenForChange(cur, now());
          return tableAfterLeave(cur, userId);
        });
      });

  @override
  Future<DiningTable> cancelTable(String tableId, String userId) =>
      guardData(() async {
        await _require(tableId);
        return tables.update(tableId, (cur) {
          if (cur.hostId != userId) {
            throw const TableException(TableError.notHost);
          }
          ensureOpenForChange(cur, now());
          return cur.copyWith(status: TableStatus.cancelled);
        });
      });

  Future<DiningTable> _require(String id) async {
    final t = await tables.find(id);
    if (t == null) throw const TableException(TableError.notFound);
    return t;
  }
}
