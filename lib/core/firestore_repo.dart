// cloud_firestore cũng có một lớp tên Type riêng: ẩn đi để dùng Type của Dart.
import 'package:cloud_firestore/cloud_firestore.dart' hide Type;

import 'entity.dart';

// ---------- Đổi kiểu giữa Dart và Firestore ----------

// Dart -> Firestore: DateTime thành Timestamp (đệ quy trong Map và List).
Object? toFirestoreValue(Object? v) {
  if (v is DateTime) return Timestamp.fromDate(v);
  if (v is Map) {
    return {for (final e in v.entries) '${e.key}': toFirestoreValue(e.value)};
  }
  if (v is Iterable) return [for (final x in v) toFirestoreValue(x)];
  return v;
}

// Firestore -> Dart: Timestamp thành DateTime (đệ quy trong Map và List).
Object? fromFirestoreValue(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is Map) {
    return {for (final e in v.entries) '${e.key}': fromFirestoreValue(e.value)};
  }
  if (v is Iterable) return [for (final x in v) fromFirestoreValue(x)];
  return v;
}

// ORM đơn giản cho một collection của Firestore: ánh xạ document <-> Entity.
// - Ghi: E.toMap() (DateTime đổi thành Timestamp), id của Entity là id của document.
// - Đọc: Timestamp đổi lại thành DateTime rồi gọi fromMap(id, map).
// E là bất kỳ Entity<String>, nên một lớp này dùng được cho users, tables, restaurants...
// Các hàm ném lỗi của Firestore lên cho nơi gọi; repository phía trên bọc try/catch.
class FirestoreRepo<E extends Entity<String>> {
  FirestoreRepo({
    required this.firestore,
    required this.collection,
    required this.fromMap,
  });

  final FirebaseFirestore firestore;
  final String collection; // tên collection, ví dụ 'users'
  final E Function(String id, Map<String, dynamic> map) fromMap;

  // Lớp (Type) của các phần tử trong collection, ví dụ User.
  Type get kind => E;

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection(collection);

  Map<String, dynamic> _encode(E e) =>
      toFirestoreValue(e.toMap()) as Map<String, dynamic>;

  E _decode(DocumentSnapshot<Map<String, dynamic>> doc) =>
      fromMap(doc.id, fromFirestoreValue(doc.data()) as Map<String, dynamic>);

  // Sinh sẵn một id mới cho document (Firestore tự sinh, không trùng).
  String newId() => _col.doc().id;

  // Ghi (tạo mới hoặc ghi đè) document có id = e.id.
  Future<void> set(E e) => _col.doc(e.id).set(_encode(e));

  // Tạo mới; ném StateError nếu id đã có (kiểm tra và ghi trong cùng một transaction).
  Future<void> add(E e) async {
    final ref = _col.doc(e.id);
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        throw StateError('$kind with id ${e.id} already exists in $collection');
      }
      tx.set(ref, _encode(e));
    });
  }

  // Tìm theo id; null nếu không có.
  Future<E?> find(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? _decode(doc) : null;
  }

  Future<List<E>> all() async => [
    for (final d in (await _col.get()).docs) _decode(d),
  ];

  // Lọc theo một trường: bằng giá trị (isEqualTo) hoặc mảng chứa giá trị (arrayContains).
  // DateTime trong giá trị tự đổi thành Timestamp. Không truyền gì thì như all().
  Future<List<E>> where(
    String field, {
    Object? isEqualTo,
    Object? arrayContains,
  }) async => [
    for (final d in (await _query(field, isEqualTo, arrayContains).get()).docs)
      _decode(d),
  ];

  Query<Map<String, dynamic>> _query(
    String? field,
    Object? isEqualTo,
    Object? arrayContains,
  ) {
    Query<Map<String, dynamic>> q = _col;
    if (field == null) return q;
    if (isEqualTo != null) {
      q = q.where(field, isEqualTo: toFirestoreValue(isEqualTo));
    }
    if (arrayContains != null) {
      q = q.where(field, arrayContains: toFirestoreValue(arrayContains));
    }
    return q;
  }

  Future<void> delete(String id) => _col.doc(id).delete();

  // Đọc-sửa-ghi nguyên tử một document (transaction). Ném StateError nếu không có document.
  Future<E> update(String id, E Function(E current) change) {
    final ref = _col.doc(id);
    return firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw StateError('$kind with id $id not found in $collection');
      }
      final updated = change(_decode(snap));
      tx.set(ref, _encode(updated));
      return updated;
    });
  }

  // Luồng dữ liệu thời gian thực: phát lại danh sách mỗi khi collection (hoặc phần đã lọc) đổi.
  Stream<List<E>> watch({
    String? field,
    Object? isEqualTo,
    Object? arrayContains,
  }) => _query(
    field,
    isEqualTo,
    arrayContains,
  ).snapshots().map((s) => [for (final d in s.docs) _decode(d)]);
}
