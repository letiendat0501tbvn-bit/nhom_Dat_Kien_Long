import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/mock/mock_data.dart';
import '../data/mock/mock_support.dart';
import '../data/mock_dishes.dart';
import '../data/models/app_settings.dart';
import '../data/models/enums.dart';
import '../data/models/area.dart';
import '../data/models/dish.dart';
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
    Random? random,
    this._settings = const AppSettings(),
  }) : random = random ?? Random();

  // Bản dùng dữ liệu mẫu cho cả app. `now`/`latency` truyền vào được để test.
  // simulateReplies: bật phản hồi giả lập trong chat (CHỈ ĐỂ DEMO); test để tắt.
  factory AppState.mock({
    Clock now = systemClock,
    Latency latency = randomLatency,
    bool simulateReplies = false,
    Random? random,
  }) {
    final data = MockData.build(now());
    final safety = MockSafetyRepository(now: now, latency: latency);
    // Chặn người dùng được áp dụng ở repository (ẩn bàn, ẩn tin, không cho tham gia)
    Future<Set<String>> blockedIdsOf(String id) async =>
        safety.blockedIdsOf(id);
    final tables = MockTableRepository(
      tables: data.tables,
      restaurants: data.restaurants,
      areas: data.areas,
      now: now,
      latency: latency,
      blockedIdsOf: blockedIdsOf,
    );
    return AppState(
      now: now,
      random: random,
      dishRepository: MockDishRepository(latency: latency),
      tableRepository: tables,
      authRepository: MockAuthRepository(
        users: data.users,
        latency: latency,
        now: now,
      ),
      chatRepository: MockChatRepository(
        messages: data.messages,
        now: now,
        latency: latency,
        blockedIdsOf: blockedIdsOf,
        autoReply: simulateReplies
            ? AutoReply(
                membersOf: (id) async =>
                    (await tables.getTable(id))?.memberIds ?? const [],
              )
            : null,
      ),
      safetyRepository: safety,
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
  // Nguồn ngẫu nhiên (cho Lắc món); truyền vào được để test cho kết quả xác định.
  final Random random;

  AppSettings _settings;
  User? _currentUser; // null = khách ghé chơi
  var _areas = <Area>[];
  var _signingIn = false;
  final _dishCache = <String, Dish>{}; // món đã lấy theo id

  // Bộ lọc theo ngày/khung giờ (không thuộc AppSettings vì không cần nhớ giữa các lần mở app).
  // _date == null nghĩa là "Hôm nay".
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

  void toggleLanguage() =>
      setLanguage(language == AppLanguage.vi ? AppLanguage.en : AppLanguage.vi);

  // ---------- Người dùng ----------

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isSigningIn => _signingIn;

  // Nạp người dùng đang đăng nhập và danh sách khu vực khi mở app.
  Future<void> load() async {
    final (user, areas) = await (
      authRepository.getCurrentUser(),
      locationRepository.getAreas(),
    ).wait;
    _currentUser = user;
    _areas = areas;
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

  // Đăng nhập bằng email + mật khẩu (tài khoản đăng ký trong app). Dùng chung cờ đang đăng
  // nhập với signIn để không bấm hai nơi cùng lúc. Lỗi (AuthException...) ném lại cho giao diện.
  Future<void> signInWithEmail(String email, String password) async {
    if (_signingIn) return;
    _signingIn = true;
    notifyListeners();
    try {
      _currentUser = await authRepository.signInWithPassword(
        email: email,
        password: password,
      );
    } finally {
      _signingIn = false;
      notifyListeners();
    }
  }

  // Đăng ký tài khoản mới. KHÔNG tự đăng nhập: người dùng quay về màn đăng nhập.
  Future<User> register({
    required String displayName,
    required String email,
    required String password,
  }) => authRepository.register(
    displayName: displayName,
    email: email,
    password: password,
  );

  Future<void> signOut() async {
    await authRepository.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ---------- Làm mới danh sách bàn ----------

  // Tăng mỗi khi dữ liệu bàn đổi (ví dụ vừa mở bàn mới) để các danh sách bàn tự tải lại.
  var _tablesVersion = 0;
  int get tablesVersion => _tablesVersion;

  void notifyTablesChanged() {
    _tablesVersion++;
    notifyListeners();
  }

  // ---------- Món (đệm theo id) ----------

  // Lấy các món theo id, chỉ gọi repository cho id chưa có trong bộ đệm.
  // Id không tồn tại thì bỏ qua (không có trong kết quả).
  Future<Map<String, Dish>> dishesByIds(Iterable<String> ids) async {
    final wanted = ids.toSet();
    final missing = wanted.where((id) => !_dishCache.containsKey(id)).toList();
    if (missing.isNotEmpty) {
      final found = await Future.wait(missing.map(dishRepository.getDish));
      for (final dish in found) {
        if (dish != null) _dishCache[dish.id] = dish;
      }
    }
    return {
      for (final id in wanted)
        if (_dishCache[id] != null) id: _dishCache[id]!,
    };
  }

  // ---------- Khu vực ----------

  String? get selectedAreaId => _settings.selectedAreaId;

  // Danh sách khu vực (nạp ở load()); rỗng cho tới khi nạp xong.
  List<Area> get areas => _areas;

  // Khu vực đang chọn, null nếu chưa chọn (hoặc danh sách khu vực chưa nạp xong).
  Area? get selectedArea {
    final id = selectedAreaId;
    if (id == null) return null;
    for (final a in _areas) {
      if (a.id == id) return a;
    }
    return null;
  }

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

  static const defaultRadiusM = 1000; // mặc định 1 km

  MealTime? get mealTime => _settings.mealTime;
  int get radiusM => _settings.radiusM;
  int? get fromMinute => _fromMinute;
  int? get toMinute => _toMinute;

  // Ngày lọc. Chưa chọn thì là "Hôm nay" (mục 4.8 SPEC), tính theo đồng hồ `now`
  // nên qua nửa đêm vẫn đúng.
  DateTime get date => _date ?? _dateOnly(now());

  // Hôm nay (bỏ phần giờ), theo đồng hồ `now`.
  DateTime get today => _dateOnly(now());

  // true khi đang dùng ngày mặc định "Hôm nay".
  bool get isDateDefault => _date == null;

  // Có bộ lọc nào khác mặc định không (để tô sáng nút lọc).
  bool get hasActiveFilters =>
      mealTime != null ||
      radiusM != defaultRadiusM ||
      _date != null ||
      _fromMinute != null ||
      _toMinute != null;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // Kiểm tra giá trị bộ lọc; ném ArgumentError nếu sai.
  static void _validate(int radiusM, int? fromMinute, int? toMinute) {
    if (!radiusOptionsM.contains(radiusM)) {
      throw ArgumentError.value(
        radiusM,
        'radiusM',
        'phải là một trong $radiusOptionsM',
      );
    }
    for (final m in [fromMinute, toMinute]) {
      if (m != null && (m < 0 || m > 1439)) {
        throw ArgumentError.value(m, 'minute', 'phải trong 0–1439');
      }
    }
    if (fromMinute != null && toMinute != null && fromMinute > toMinute) {
      throw ArgumentError('Giờ bắt đầu phải trước giờ kết thúc');
    }
  }

  // Đặt cả bộ lọc trong một lần (nút "Áp dụng" của bảng lọc), chỉ báo thay đổi một lần.
  // date null hoặc đúng hôm nay = ngày mặc định.
  void applyFilters({
    MealTime? mealTime,
    required int radiusM,
    DateTime? date,
    int? fromMinute,
    int? toMinute,
  }) {
    _validate(radiusM, fromMinute, toMinute);
    _settings = _settings.copyWith(
      radiusM: radiusM,
      mealTime: mealTime,
      clearMealTime: mealTime == null,
    );
    _date = _storedDate(date);
    _fromMinute = fromMinute;
    _toMinute = toMinute;
    notifyListeners();
  }

  // Hôm nay lưu là null để "Hôm nay" luôn đúng, không bị cũ sau nửa đêm.
  DateTime? _storedDate(DateTime? date) {
    if (date == null) return null;
    final d = _dateOnly(date);
    return d == _dateOnly(now()) ? null : d;
  }

  // null = bỏ lọc theo buổi ăn.
  void setMealTime(MealTime? mealTime) {
    _settings = mealTime == null
        ? _settings.copyWith(clearMealTime: true)
        : _settings.copyWith(mealTime: mealTime);
    notifyListeners();
  }

  void setRadius(int radiusM) {
    _validate(radiusM, _fromMinute, _toMinute);
    _settings = _settings.copyWith(radiusM: radiusM);
    notifyListeners();
  }

  // Chỉ giữ phần ngày; null (hoặc hôm nay) = ngày mặc định.
  void setDate(DateTime? date) {
    _date = _storedDate(date);
    notifyListeners();
  }

  // Khung giờ trong ngày, tính bằng phút (0–1439). null = không giới hạn đầu đó.
  void setTimeWindow({int? fromMinute, int? toMinute}) {
    _validate(radiusM, fromMinute, toMinute);
    _fromMinute = fromMinute;
    _toMinute = toMinute;
    notifyListeners();
  }

  // Đặt lại bộ lọc về mặc định. Giữ nguyên ngôn ngữ và khu vực đã chọn.
  void resetFilters() {
    _settings = _settings.copyWith(
      clearMealTime: true,
      radiusM: defaultRadiusM,
    );
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
    date: date,
    fromMinute: _fromMinute,
    toMinute: _toMinute,
    radiusM: _settings.radiusM,
    viewerId: _currentUser?.id,
  );

  // ---------- Chặn người dùng ----------

  // Tăng mỗi khi danh sách chặn đổi, để chat và danh sách tải lại nội dung.
  var _blocksVersion = 0;
  int get blocksVersion => _blocksVersion;

  // Chặn/bỏ chặn rồi báo mọi màn tải lại (bàn và tin nhắn hiện/ẩn ngay).
  // Lỗi (SafetyException...) được ném lại cho giao diện. Cần đã đăng nhập.
  Future<void> blockUser(String blockedUserId) async {
    final me = _currentUser;
    if (me == null) return;
    await safetyRepository.blockUser(me.id, blockedUserId);
    _blocksVersion++;
    notifyTablesChanged();
  }

  Future<void> unblockUser(String blockedUserId) async {
    final me = _currentUser;
    if (me == null) return;
    await safetyRepository.unblockUser(me.id, blockedUserId);
    _blocksVersion++;
    notifyTablesChanged();
  }
}
