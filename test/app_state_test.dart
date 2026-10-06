import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/mock/mock_support.dart';
import 'package:giua_ki_app/data/models/app_settings.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/models/user.dart';
import 'package:giua_ki_app/data/repositories/auth_repository.dart';
import 'package:giua_ki_app/l10n/strings.dart';
import 'package:giua_ki_app/state/app_state.dart';

import 'test_helpers.dart';

// AuthRepository giả: đăng nhập luôn lỗi.
class _FailingAuthRepository implements AuthRepository {
  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<User> signIn() async => throw Exception('Không có mạng');

  @override
  Future<void> signOut() async {}

  @override
  Future<User?> getUser(String id) async => null;
}

// Đếm số lần AppState báo thay đổi.
int countNotifications(AppState app, void Function() action) {
  var n = 0;
  app.addListener(() => n++);
  action();
  return n;
}

void main() {
  late AppState app;

  setUp(() => app = makeAppState());
  tearDown(() => app.dispose());

  group('ngôn ngữ', () {
    test('mặc định là tiếng Việt', () {
      expect(app.language, AppLanguage.vi);
      expect(app.strings(StrKey.tabExplore), 'Khám phá');
    });

    test('đổi ngôn ngữ cập nhật chuỗi và báo cho giao diện', () {
      final n = countNotifications(app, () => app.setLanguage(AppLanguage.en));
      expect(n, 1);
      expect(app.language, AppLanguage.en);
      expect(app.strings(StrKey.tabExplore), 'Explore');
    });

    test('đặt lại đúng ngôn ngữ đang dùng thì không báo thay đổi', () {
      final n = countNotifications(app, () => app.setLanguage(AppLanguage.vi));
      expect(n, 0);
    });

    test('toggleLanguage đổi qua lại VI <-> EN', () {
      app.toggleLanguage();
      expect(app.language, AppLanguage.en);
      app.toggleLanguage();
      expect(app.language, AppLanguage.vi);
    });

    test('nút ngôn ngữ hiện ngôn ngữ sẽ chuyển sang', () {
      expect(languageButtonLabel(AppLanguage.vi), 'EN');
      expect(languageButtonLabel(AppLanguage.en), 'VI');
    });
  });

  group('đăng nhập / đăng xuất', () {
    test('lúc đầu là khách', () {
      expect(app.isLoggedIn, isFalse);
      expect(app.currentUser, isNull);
    });

    test('đăng nhập thành công: có người dùng, và báo thay đổi', () async {
      var n = 0;
      app.addListener(() => n++);
      await app.signIn();
      expect(app.isLoggedIn, isTrue);
      expect(app.currentUser?.displayName, 'Minh Anh');
      expect(app.isSigningIn, isFalse);
      expect(n, greaterThanOrEqualTo(2)); // bắt đầu đăng nhập + xong
    });

    test('đăng nhập không tự tham gia hay mở bàn', () async {
      final before = await app.tableRepository.getMyTables('u1');
      await app.signIn();
      final after = await app.tableRepository.getMyTables('u1');
      expect(after.map((t) => t.id), before.map((t) => t.id));
    });

    test('đăng xuất quay lại khách', () async {
      await app.signIn();
      await app.signOut();
      expect(app.isLoggedIn, isFalse);
      expect(await app.authRepository.getCurrentUser(), isNull);
    });

    test('load() nạp lại người dùng đã đăng nhập', () async {
      await app.authRepository.signIn(); // đăng nhập thẳng ở repository
      expect(app.isLoggedIn, isFalse);
      await app.load();
      expect(app.isLoggedIn, isTrue);
    });

    test(
      'đăng nhập lỗi: vẫn là khách, cờ đang đăng nhập được tắt, lỗi ném lại',
      () async {
        final failing = AppState(
          dishRepository: app.dishRepository,
          tableRepository: app.tableRepository,
          authRepository: _FailingAuthRepository(),
          chatRepository: app.chatRepository,
          safetyRepository: app.safetyRepository,
          locationRepository: app.locationRepository,
          now: () => testNow,
        );
        addTearDown(failing.dispose);

        await expectLater(failing.signIn(), throwsException);
        expect(failing.isLoggedIn, isFalse);
        expect(failing.isSigningIn, isFalse);
      },
    );
  });

  group('khu vực', () {
    test('chọn và bỏ chọn khu vực', () {
      expect(app.selectedAreaId, isNull);
      app.selectArea('hn-hoan-kiem');
      expect(app.selectedAreaId, 'hn-hoan-kiem');
      app.selectArea(null);
      expect(app.selectedAreaId, isNull);
    });

    test('chọn khu vực không làm mất cài đặt khác', () {
      app.setLanguage(AppLanguage.en);
      app.setRadius(500);
      app.selectArea('hcm-q1');
      expect(app.language, AppLanguage.en);
      expect(app.radiusM, 500);
    });

    test('getSelectedArea trả về khu vực đã chọn', () async {
      expect(await app.getSelectedArea(), isNull);
      app.selectArea('hcm-q1');
      final area = await app.getSelectedArea();
      expect(area?.label, 'Hồ Chí Minh · Quận 1');
    });
  });

  group('bộ lọc bàn', () {
    test('mặc định: không lọc gì, bán kính 1 km', () {
      final q = app.tableQuery();
      expect(q.areaId, isNull);
      expect(q.mealTime, isNull);
      expect(q.date, DateTime(2026, 10, 5)); // mặc định "Hôm nay"
      expect(q.fromMinute, isNull);
      expect(q.toMinute, isNull);
      expect(q.radiusM, 1000);
    });

    test('đặt buổi ăn, bán kính, ngày, khung giờ và truyền vào TableQuery', () {
      app.selectArea('hcm-q1');
      app.setMealTime(MealTime.evening);
      app.setRadius(500);
      app.setDate(DateTime(2026, 10, 6, 15, 30)); // chỉ giữ phần ngày
      app.setTimeWindow(fromMinute: 17 * 60, toMinute: 20 * 60 + 30);

      final q = app.tableQuery(dishId: 'pho');
      expect(q.areaId, 'hcm-q1');
      expect(q.dishId, 'pho');
      expect(q.mealTime, MealTime.evening);
      expect(q.radiusM, 500);
      expect(q.date, DateTime(2026, 10, 6));
      expect(q.fromMinute, 1020);
      expect(q.toMinute, 1230);
    });

    test('bán kính chỉ nhận 100 m, 500 m, 1 km, 10 km', () {
      for (final r in radiusOptionsM) {
        app.setRadius(r);
        expect(app.radiusM, r);
      }
      expect(() => app.setRadius(2000), throwsArgumentError);
      expect(app.radiusM, 10000); // giá trị cũ được giữ
    });

    test('khung giờ phải hợp lệ', () {
      expect(() => app.setTimeWindow(fromMinute: -1), throwsArgumentError);
      expect(() => app.setTimeWindow(toMinute: 1440), throwsArgumentError);
      expect(
        () => app.setTimeWindow(fromMinute: 600, toMinute: 500),
        throwsArgumentError,
      );
      app.setTimeWindow(fromMinute: 600); // chỉ có đầu "từ" thì được
      expect(app.fromMinute, 600);
      expect(app.toMinute, isNull);
    });

    test('bỏ lọc buổi ăn bằng null, ngày null trở về hôm nay', () {
      app.setMealTime(MealTime.noon);
      app.setDate(DateTime(2026, 10, 6));
      app.setMealTime(null);
      app.setDate(null);
      expect(app.mealTime, isNull);
      expect(app.date, DateTime(2026, 10, 5));
      expect(app.isDateDefault, isTrue);
    });

    test('resetFilters đặt lại bộ lọc nhưng giữ ngôn ngữ và khu vực', () {
      app.setLanguage(AppLanguage.en);
      app.selectArea('hn-hoan-kiem');
      app.setMealTime(MealTime.morning);
      app.setRadius(10000);
      app.setDate(DateTime(2026, 10, 6));
      app.setTimeWindow(fromMinute: 300, toMinute: 600);

      app.resetFilters();

      expect(app.mealTime, isNull);
      expect(app.radiusM, 1000);
      expect(app.date, DateTime(2026, 10, 5));
      expect(app.isDateDefault, isTrue);
      expect(app.fromMinute, isNull);
      expect(app.toMinute, isNull);
      expect(app.hasActiveFilters, isFalse);
      expect(app.language, AppLanguage.en);
      expect(app.selectedAreaId, 'hn-hoan-kiem');
    });

    test('lọc bàn thật theo khu vực và bộ lọc của AppState', () async {
      app.selectArea('hcm-q1');
      app.setRadius(10000);
      final all = await app.tableRepository.getTables(app.tableQuery());
      expect(all, isNotEmpty);

      app.setMealTime(MealTime.afternoon); // buổi xế
      final afternoon = await app.tableRepository.getTables(app.tableQuery());
      expect(afternoon.length, lessThan(all.length));
      for (final t in afternoon) {
        expect(t.startAt.hour, inInclusiveRange(14, 16));
      }
    });
  });

  group('ngày lọc mặc định là "Hôm nay"', () {
    test('lúc đầu là hôm nay theo đồng hồ truyền vào', () {
      expect(app.isDateDefault, isTrue);
      expect(app.date, DateTime(2026, 10, 5));
    });

    test('chọn đúng hôm nay (dù kèm giờ) vẫn là ngày mặc định', () {
      app.setDate(DateTime(2026, 10, 5, 18, 45));
      expect(app.isDateDefault, isTrue);
      expect(app.hasActiveFilters, isFalse);
    });

    test('chọn ngày khác thì không còn là mặc định', () {
      app.setDate(DateTime(2026, 10, 6));
      expect(app.isDateDefault, isFalse);
      expect(app.date, DateTime(2026, 10, 6));
      expect(app.hasActiveFilters, isTrue);
    });

    test('ngày mặc định đi theo đồng hồ, qua nửa đêm vẫn là "hôm nay"', () {
      var current = DateTime(2026, 10, 5, 23, 50);
      final a = AppState.mock(now: () => current, latency: noLatency);
      addTearDown(a.dispose);
      expect(a.date, DateTime(2026, 10, 5));
      current = DateTime(2026, 10, 6, 0, 10);
      expect(a.date, DateTime(2026, 10, 6));
    });

    test('ngày đã chọn rõ ràng thì không bị đổi theo đồng hồ', () {
      var current = DateTime(2026, 10, 5, 10);
      final a = AppState.mock(now: () => current, latency: noLatency);
      addTearDown(a.dispose);
      a.setDate(DateTime(2026, 10, 7));
      current = DateTime(2026, 10, 6, 9);
      expect(a.date, DateTime(2026, 10, 7));
    });
  });

  group('applyFilters (nút Áp dụng)', () {
    test('đặt cả bộ lọc trong một lần và chỉ báo thay đổi một lần', () {
      final n = countNotifications(
        app,
        () => app.applyFilters(
          mealTime: MealTime.evening,
          radiusM: 500,
          date: DateTime(2026, 10, 6),
          fromMinute: 17 * 60,
          toMinute: 21 * 60,
        ),
      );
      expect(n, 1);
      expect(app.mealTime, MealTime.evening);
      expect(app.radiusM, 500);
      expect(app.date, DateTime(2026, 10, 6));
      expect(app.fromMinute, 1020);
      expect(app.toMinute, 1260);
      expect(app.hasActiveFilters, isTrue);
    });

    test('mealTime null bỏ lọc buổi ăn đã đặt trước đó', () {
      app.setMealTime(MealTime.noon);
      app.applyFilters(radiusM: 1000);
      expect(app.mealTime, isNull);
      expect(app.hasActiveFilters, isFalse);
    });

    test('giá trị sai thì ném lỗi và KHÔNG đổi gì', () {
      app.applyFilters(mealTime: MealTime.noon, radiusM: 500);
      var n = 0;
      app.addListener(() => n++);

      expect(() => app.applyFilters(radiusM: 2000), throwsArgumentError);
      expect(
        () => app.applyFilters(radiusM: 100, fromMinute: 700, toMinute: 600),
        throwsArgumentError,
      );
      expect(
        () => app.applyFilters(radiusM: 100, toMinute: 2000),
        throwsArgumentError,
      );

      expect(n, 0);
      expect(app.mealTime, MealTime.noon);
      expect(app.radiusM, 500);
    });

    test('giữ nguyên ngôn ngữ và khu vực', () {
      app.setLanguage(AppLanguage.en);
      app.selectArea('hcm-q1');
      app.applyFilters(mealTime: MealTime.morning, radiusM: 100);
      expect(app.language, AppLanguage.en);
      expect(app.selectedAreaId, 'hcm-q1');
    });

    test('hasActiveFilters bật khi khác mặc định ở bất kỳ mục nào', () {
      expect(app.hasActiveFilters, isFalse);
      app.setRadius(500);
      expect(app.hasActiveFilters, isTrue);
      app.setRadius(1000);
      expect(app.hasActiveFilters, isFalse);
      app.setTimeWindow(toMinute: 600);
      expect(app.hasActiveFilters, isTrue);
    });
  });

  group('đồng hồ', () {
    test('now truyền vào được và dùng cho dữ liệu mẫu', () async {
      expect(app.now(), testNow);
      final tables = await app.tableRepository.getTables(app.tableQuery());
      expect(tables.every((t) => t.startAt.isAfter(testNow)), isTrue);
    });
  });
}
