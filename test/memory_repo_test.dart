import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/core/entity.dart';
import 'package:giua_ki_app/core/memory_repo.dart';
import 'package:giua_ki_app/data/mock/mock_data.dart';
import 'package:giua_ki_app/data/models/area.dart';
import 'package:giua_ki_app/data/models/dish.dart';
import 'package:giua_ki_app/data/models/restaurant.dart';
import 'package:giua_ki_app/data/models/user.dart';
import 'package:giua_ki_app/data/mock_dishes.dart';

void main() {
  group('MemoryRepo<E, ID>', () {
    test('thêm, tìm theo id, liệt kê; kind trả về Type của phần tử', () {
      final repo = MemoryRepo<Restaurant, String>(mockRestaurants);
      expect(repo.kind, Restaurant);
      expect(repo.length, mockRestaurants.length);
      expect(repo.find('q1-1')?.name, 'Quán Nhà Lá');
      expect(repo.find('khong-co'), isNull);
      expect(repo.all().length, repo.length);
    });

    test('dùng cho kiểu khác chỉ cần đổi tham số kiểu', () {
      expect(MemoryRepo<Area, String>(mockAreas).kind, Area);
      expect(
        MemoryRepo<User, String>(mockUsers).find('u1')?.displayName,
        'Minh Anh',
      );
      expect(MemoryRepo<Dish, String>(kMockDishes).kind, Dish);
    });

    test('kind phân biệt các kho khác nhau', () {
      expect(
        MemoryRepo<Area, String>().kind == MemoryRepo<User, String>().kind,
        isFalse,
      );
    });

    test('thêm id trùng thì ném StateError; thêm id mới thì tìm được', () {
      final repo = MemoryRepo<User, String>(mockUsers);
      expect(() => repo.add(mockUsers.first), throwsStateError);
      const u = User(id: 'x1', displayName: 'Mới', email: 'moi@example.com');
      repo.add(u);
      expect(repo.find('x1'), u);
    });

    test('all() là bản sao: sửa bản sao không đổi kho', () {
      final repo = MemoryRepo<User, String>(mockUsers);
      repo.all().clear();
      expect(repo.length, mockUsers.length);
    });

    test('where lọc theo điều kiện', () {
      final repo = MemoryRepo<Restaurant, String>(mockRestaurants);
      expect(repo.where((r) => r.areaId == 'hcm-q1').length, 10);
    });
  });

  group('describe / groupByType (Object + Type)', () {
    test('Entity ghi runtimeType, id và label', () {
      expect(describe(mockAreas.first), startsWith('Area #'));
      expect(describe(mockUsers.first), 'User #u1: Minh Anh');
    });

    test('đối tượng bất kỳ chỉ ghi lớp và giá trị', () {
      expect(describe(42), 'int: 42');
      expect(describe('abc'), 'String: abc');
    });

    test('groupByType gom theo lớp thật của từng phần tử', () {
      final groups = groupByType([...mockUsers, ...mockAreas, 'x', 7]);
      expect(groups[User]!.length, mockUsers.length);
      expect(groups[Area]!.length, mockAreas.length);
      expect(groups[String]!.length, 1);
      expect(groups[int]!.length, 1);
      expect(groups.keys.toSet(), {User, Area, String, int});
    });
  });
}
