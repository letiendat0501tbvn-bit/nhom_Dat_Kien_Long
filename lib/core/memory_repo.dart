import 'entity.dart';

// Kho lưu trong bộ nhớ dùng chung cho mọi Entity (Generics): thêm, tìm theo id, liệt kê.
// E phải là Entity có khoá kiểu ID, nên một lớp này thay cho các vòng lặp "tìm theo id"
// viết lặp lại trong từng Mock repository.
class MemoryRepo<E extends Entity<ID>, ID> {
  MemoryRepo([Iterable<E> items = const []]) : _items = [...items];

  final List<E> _items;

  // Lớp (Type) của các phần tử trong kho, ví dụ Dish hay Restaurant.
  Type get kind => E;

  int get length => _items.length;

  // Ném StateError nếu id đã có (tránh hai đối tượng cùng danh tính trong một kho).
  void add(E item) {
    if (find(item.id) != null) {
      throw StateError(
        '$kind with id ${item.id} already exists: ${describe(item)}',
      );
    }
    _items.add(item);
  }

  // Tìm theo id; null nếu không có.
  E? find(ID id) {
    for (final e in _items) {
      if (e.id == id) return e;
    }
    return null;
  }

  // Bản sao danh sách (sửa bản sao không ảnh hưởng kho).
  List<E> all() => List.of(_items);

  List<E> where(bool Function(E) test) => _items.where(test).toList();
}
