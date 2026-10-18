// Câu 1 (Generics): lớp cha chung mô tả mọi đối tượng có danh tính trong app (món, quán,
// người dùng, bàn, tin nhắn...). ID là kiểu của khoá nhận dạng (hiện là String).
// Hai đối tượng bằng nhau khi CÙNG LỚP (runtimeType) và cùng id, bất kể các trường khác.
abstract class Entity<ID> {
  const Entity(this.id);

  final ID id;

  // Tên ngắn dùng để hiển thị/ghi log; mỗi lớp con tự định nghĩa.
  String get label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entity<ID> &&
          other.runtimeType == runtimeType &&
          other.id == id);

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @override
  String toString() => '$runtimeType(id: $id, label: $label)';
}

// Câu 2b (Object + Type): mô tả MỌI đối tượng bất kỳ (tham số kiểu Object). Entity thì ghi
// thêm id và label, còn lại chỉ ghi lớp (runtimeType) và giá trị.
String describe(Object o) => o is Entity
    ? '${o.runtimeType} #${o.id}: ${o.label}'
    : '${o.runtimeType}: $o';

// Gom các đối tượng theo lớp thật của chúng (Type), ví dụ để đếm số món, số quán...
Map<Type, List<Object>> groupByType(Iterable<Object> items) {
  final result = <Type, List<Object>>{};
  for (final item in items) {
    result.putIfAbsent(item.runtimeType, () => []).add(item);
  }
  return result;
}
