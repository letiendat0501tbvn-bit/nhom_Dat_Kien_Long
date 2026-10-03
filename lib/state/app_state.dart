import 'package:flutter/foundation.dart';

import '../data/mock/mock_data.dart';
import '../data/mock/mock_support.dart';
import '../data/mock_dishes.dart';
import '../data/models/app_settings.dart';
import '../data/models/enums.dart';
import '../data/models/area.dart';
import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/dish_repository.dart';
import '../data/repositories/location_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../data/repositories/mock_chat_repository.dart';
import '../data/repositories/mock_location_repository.dart';
import '../data/repositories/mock_safety_repository.dart';
import '../data/repositories/mock_table_repository.dart';
import '../data/repositories/safety_repository.dart';
import '../data/repositories/table_repository.dart';
import '../l10n/strings.dart';

// Trạng thái chung của app: ngôn ngữ, khu vực, bộ lọc, người dùng hiện tại và
// các repository. Giai đoạn đầu giữ trong bộ nhớ (chưa lưu bền).
class AppState extends ChangeNotifier {
  AppState({
    required this.dishRepository,
    required this.tableRepository,
    required this.authRepository,
    required this.chatRepository,
    required this.safetyRepository,
    required this.locationRepository,
    this.now = systemClock,
    this._settings = const AppSettings(),
  });

  // Bản dùng dữ liệu mẫu cho cả app. `now`/`latency` truyền vào được để test.
  factory AppState.mock({Clock now = systemClock, Latency latency = randomLatency}) {
    final data = MockData.build(now());
    return AppState(
      now: now,
      dishRepository: MockDishRepository(latency: latency),
      tableRepository: MockTableRepository(
        tables: data.tables,
        restaurants: data.restaurants,
        areas: data.areas,
        now: now,
        latency: latency,
      ),
      authRepository: MockAuthRepository(users: data.users, latency: latency),
      chatRepository: MockChatRepository(
        messages: data.messages,
        now: now,
        latency: latency,
      ),
      safetyRepository: MockSafetyRepository(now: now, latency: latency),
      locationRepository: MockLocationRepository(
        areas: data.areas,
        restaurants: data.restaurants,
        latency: latency,
      ),
    );
  }

  final DishRepository dishRepository;
  final TableRepository tableRepository;
  final AuthRepository authRepository;
  final ChatRepository chatRepository;
  final SafetyRepository safetyRepository;
  final LocationRepository locationRepository;
  final Clock now;

  AppSettings _settings;
  User? _currentUser; // null = khách ghé chơi
  var _signingIn = false;

  // Bộ lọc theo ngày/khung giờ (không thuộc AppSettings vì không cần nhớ giữa các lần mở app)
  DateTime? _date;
  int? _fromMinute;
  int? _toMinute;

  // ---------- Ngôn ngữ ----------

  AppSettings get settings => _settings;
  AppLanguage get language => _settings.language;
  Strings get strings => Strings(_settings.language);

  void setLanguage(AppLanguage language) {
    if (language == _settings.language) return;
    _settings = _settings.copyWith(language: language);
    notifyListeners();
  }

  void toggleLanguage() => setLanguage(
      language == AppLanguage.vi ? AppLanguage.en : AppLanguage.vi);

  // ---------- Người dùng ----------

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isSigningIn => _signingIn;

  // Nạp người dùng đang đăng nhập khi mở app.
  Future<void> load() async {
    final user = await authRepository.getCurrentUser();
    if (user == _currentUser) return;
    _currentUser = user;
    notifyListeners();
  }

  // Đăng nhập giả lập. Chỉ đổi trạng thái người dùng, KHÔNG tự tham gia hay mở bàn.
  // Lỗi được ném lại cho giao diện hiện thông báo.
  Future<void> signIn() async {
    if (_signingIn) return;
    _signingIn = true;
    notifyListeners();
    try {
      _currentUser = await authRepository.signIn();
    } finally {
      _signingIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await authRepository.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ---------- Khu vực ----------

  String? get selectedAreaId => _settings.selectedAreaId;

  // null = bỏ chọn khu vực.
  void selectArea(String? areaId) {
    if (areaId == _settings.selectedAreaId) return;
    _settings = areaId == null
        ? _settings.copyWith(clearArea: true)
        : _settings.copyWith(selectedAreaId: areaId);
    notifyListeners();
  }

  Future<Area?> getSelectedArea() async {
    final id = selectedAreaId;
    if (id == null) return null;
    final areas = await locationRepository.getAreas();
    for (final a in areas) {
      if (a.id == id) return a;
    }
    return null;
  }

  // ---------- Bộ lọc bàn ----------

  MealTime? get mealTime => _settings.mealTime;
  int get radiusM => _settings.radiusM;
  DateTime? get date => _date;
  int? get fromMinute => _fromMinute;
  int? get toMinute => _toMinute;

  // null = bỏ lọc theo buổi ăn.
  void setMealTime(MealTime? mealTime) {
    _settings = mealTime == null
        ? _settings.copyWith(clearMealTime: true)
        : _settings.copyWith(mealTime: mealTime);
    notifyListeners();
  }

  void setRadius(int radiusM) {
    if (!radiusOptionsM.contains(radiusM)) {
      throw ArgumentError.value(radiusM, 'radiusM', 'phải là một trong $radiusOptionsM');
    }
    _settings = _settings.copyWith(radiusM: radiusM);
    notifyListeners();
  }

  // Chỉ giữ phần ngày; null = bỏ lọc theo ngày.
  void setDate(DateTime? date) {
    _date = date == null ? null : DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  // Khung giờ trong ngày, tính bằng phút (0–1439). null = không giới hạn đầu đó.
  void setTimeWindow({int? fromMinute, int? toMinute}) {
    for (final m in [fromMinute, toMinute]) {
      if (m != null && (m < 0 || m > 1439)) {
        throw ArgumentError.value(m, 'minute', 'phải trong 0–1439');
      }
    }
    if (fromMinute != null && toMinute != null && fromMinute > toMinute) {
      throw ArgumentError('Giờ bắt đầu phải trước giờ kết thúc');
    }
    _fromMinute = fromMinute;
    _toMinute = toMinute;
    notifyListeners();
  }

  // Đặt lại bộ lọc về mặc định. Giữ nguyên ngôn ngữ và khu vực đã chọn.
  void resetFilters() {
    _settings = _settings.copyWith(clearMealTime: true, radiusM: 1000);
    _date = null;
    _fromMinute = null;
    _toMinute = null;
    notifyListeners();
  }

  // Điều kiện lọc bàn hiện tại, truyền thẳng cho TableRepository.getTables.
  TableQuery tableQuery({String? dishId}) => TableQuery(
        areaId: _settings.selectedAreaId,
        dishId: dishId,
        mealTime: _settings.mealTime,
        date: _date,
        fromMinute: _fromMinute,
        toMinute: _toMinute,
        radiusM: _settings.radiusM,
      );
}
