import 'enums.dart';

// Các bán kính tới quán được phép chọn (mét): 100 m, 500 m, 1 km, 10 km.
const radiusOptionsM = [100, 500, 1000, 10000];

// Cài đặt người dùng: ngôn ngữ, khu vực, bộ lọc. Giai đoạn đầu chỉ giữ trong bộ nhớ.
class AppSettings {
  const AppSettings({
    this.language = AppLanguage.vi,
    this.selectedAreaId,
    this.radiusM = 1000, // mặc định 1 km
    this.mealTime,
    this.useDeviceLocation = false,
  });

  final AppLanguage language;
  final String? selectedAreaId;
  final int radiusM; // 100, 500, 1000, 10000
  final MealTime? mealTime;
  final bool useDeviceLocation;

  // clearArea / clearMealTime: đặt lại về "chưa chọn" (null không đủ để phân biệt).
  AppSettings copyWith({
    AppLanguage? language,
    String? selectedAreaId,
    bool clearArea = false,
    int? radiusM,
    MealTime? mealTime,
    bool clearMealTime = false,
    bool? useDeviceLocation,
  }) {
    return AppSettings(
      language: language ?? this.language,
      selectedAreaId: clearArea
          ? null
          : (selectedAreaId ?? this.selectedAreaId),
      radiusM: radiusM ?? this.radiusM,
      mealTime: clearMealTime ? null : (mealTime ?? this.mealTime),
      useDeviceLocation: useDeviceLocation ?? this.useDeviceLocation,
    );
  }
}
