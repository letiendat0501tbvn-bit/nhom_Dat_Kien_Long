import '../data/models/enums.dart';
import '../data/repositories/table_repository.dart';
import 'formatters.dart';

// Toàn bộ chuỗi chữ của giao diện nằm ở file này. QUY TẮC: không viết cứng chữ
// trong widget; thêm một StrKey mới thì phải thêm cả bản VI và bản EN
// (test l10n_test.dart sẽ báo nếu thiếu).
//
// Cách dùng trong widget:  final t = context.strings;  Text(t(StrKey.tabExplore))
//
// Lưu ý: tên món, mô tả món, tên khu vực/quán là DỮ LIỆU (data/), không phải chuỗi
// giao diện nên chưa dịch. Riêng tên danh mục món có dịch (xem categoryLabel).
enum StrKey {
  // Chung
  appName,
  appNameWithEyes,
  tagline,
  notBuiltYet,
  // Thanh dưới
  tabExplore,
  tabTables,
  tabSchedule,
  tabMe,
  createTable,
  // Top bar
  semLanguage,
  semDice,
  semProfile,
  chooseLocation,
  // Khám phá + chọn món
  exploreTitle,
  exploreSubtitle,
  searchHint,
  dishesEmpty,
  dishesError,
  retry,
  findTable,
  dishDetailPending,
  seeAllDishes, // có {n}
  allDishesTitle,
  // Gợi ý cho bạn
  suggestTitle,
  suggestSubtitle,
  tabTaste,
  tabMood,
  tabHot,
  suggestPickTaste,
  suggestPickMood,
  tasteSpicy,
  tasteGrilled,
  tasteVegetarian,
  tasteNoodleSoup,
  tasteRice,
  tasteSeafood,
  tasteSweet,
  tasteCoffee,
  moodCozy,
  moodLight,
  moodSocial,
  moodEnergetic,
  moodSweetTooth,
  moodRefreshing,
  // Gói trọn hương vị ba miền
  regionsTitle,
  regionsSubtitle,
  regionsMore,
  regionHanoi,
  regionCentral,
  regionSaigonNight,
  regionThreeRegions,
  catNoodles,
  catSavoryCakes,
  catRolls,
  catRice,
  catHotpot,
  catSnacks,
  catDrinks,
  // Bảng "Bộ lọc & giờ ăn"
  filterTitle,
  filterMealTime,
  mealMorning,
  mealNoon,
  mealAfternoon,
  mealEvening,
  mealLateNight,
  filterRadius,
  filterTimeWindow,
  filterFrom,
  filterTo,
  filterAnyTime,
  filterTimeNote,
  filterDate,
  today,
  tomorrow,
  weekdayMon,
  weekdayTue,
  weekdayWed,
  weekdayThu,
  weekdayFri,
  weekdaySat,
  weekdaySun,
  filterApply,
  filterReset,
  // Chọn vị trí / khu vực
  areaSheetTitle,
  areaSheetBody,
  allowLocation,
  maybeLater,
  areaOrChoose,
  areaCenterNote,
  locationComingSoon,
  areaClear,
  changeArea,
  // Danh sách bàn và nút tham gia
  tablesError,
  tablesEmpty,
  seeTomorrow,
  seeToday,
  widenRadius, // có {radius}
  joinTable,
  tableFull,
  tableJoined,
  seatsLeft, // có {left}, {total}
  seatsFull, // có {total}
  noDishChosen,
  joinSuccess,
  joinFailed,
  // Bàn ăn
  tablesTitle,
  tablesSubtitle,
  chooseArea,
  chooseAreaHint,
  // Hồ sơ
  profileTitle,
  profileSubtitle,
  tabMyTables,
  tabAccount,
  myTablesHeading,
  myTablesGuest,
  myTablesMemberPlaceholder,
  guestTitle,
  guestBody,
  signIn,
  signOut,
  privateFeedback,
  reportsSent,
  blockList,
  // Bảng đăng nhập
  loginTitle,
  loginBody,
  continueWithGoogle,
  loginNote,
  privacyPolicy,
  termsOfUse,
  loginFailed,
  // Lỗi khi thao tác với bàn (ứng với TableError)
  errTableNotFound,
  errTableFull,
  errTableStarted,
  errTableCancelled,
  errTableEnded,
  errTableOverlap,
  errTableInvalidTime,
  errTableInvalidCapacity,
  errTableAlreadyMember,
  errTableNotMember,
  errTableNotHost,
}

const Map<StrKey, String> viStrings = {
  StrKey.appName: 'Ăn Gì Đây Ta?',
  StrKey.appNameWithEyes: 'Ăn Gì Đây Ta? 👀',
  StrKey.tagline: 'Món ngon • Bạn mới • Kết nối thật',
  StrKey.notBuiltYet: 'Tính năng này chưa làm.',
  StrKey.tabExplore: 'Khám phá',
  StrKey.tabTables: 'Bàn ăn',
  StrKey.tabSchedule: 'Lịch hẹn',
  StrKey.tabMe: 'Tôi',
  StrKey.createTable: 'Tạo bàn mới',
  StrKey.semLanguage: 'Đổi ngôn ngữ',
  StrKey.semDice: 'Lắc món',
  StrKey.semProfile: 'Hồ sơ',
  StrKey.chooseLocation: 'Chọn vị trí',
  StrKey.exploreTitle: 'Chọn món để lên kèo',
  StrKey.exploreSubtitle: 'Chọn món → Xem quán và giờ hẹn → Xác nhận tham gia.',
  StrKey.searchHint: 'Tìm món ăn…',
  StrKey.dishesEmpty: 'Không tìm thấy món phù hợp.',
  StrKey.dishesError:
      'Không tải được danh sách món. Kiểm tra mạng rồi thử lại nhé.',
  StrKey.retry: 'Thử lại',
  StrKey.findTable: 'Tìm bàn ăn',
  StrKey.dishDetailPending: 'Chi tiết món: chưa có thiết kế.',
  StrKey.seeAllDishes: 'Xem tất cả {n} món ngon',
  StrKey.allDishesTitle: 'Tất cả món ngon',
  StrKey.suggestTitle: 'Gợi ý cho bạn',
  StrKey.suggestSubtitle:
      'Chọn theo khẩu vị, tâm trạng hoặc xem món đang được thèm.',
  StrKey.tabTaste: 'Hợp vị',
  StrKey.tabMood: 'Tâm trạng',
  StrKey.tabHot: 'Đang hot',
  StrKey.suggestPickTaste: 'Chọn một khẩu vị để xem món gợi ý.',
  StrKey.suggestPickMood: 'Chọn một tâm trạng để xem món gợi ý.',
  StrKey.tasteSpicy: 'Cay tê',
  StrKey.tasteGrilled: 'Thịt nướng',
  StrKey.tasteVegetarian: 'Chay thanh đạm',
  StrKey.tasteNoodleSoup: 'Sợi / Nước dùng',
  StrKey.tasteRice: 'Cơm dẻo',
  StrKey.tasteSeafood: 'Hải sản',
  StrKey.tasteSweet: 'Chè ngọt',
  StrKey.tasteCoffee: 'Cà phê đậm',
  StrKey.moodCozy: 'Ấm bụng',
  StrKey.moodLight: 'Nhẹ nhàng',
  StrKey.moodSocial: 'Tụ tập',
  StrKey.moodEnergetic: 'Cần năng lượng',
  StrKey.moodSweetTooth: 'Thèm ngọt',
  StrKey.moodRefreshing: 'Giải nhiệt',
  StrKey.regionsTitle: 'Gói trọn hương vị ba miền',
  StrKey.regionsSubtitle: 'Không chỉ là ăn ngon, mà còn là câu chuyện văn hoá.',
  StrKey.regionsMore: 'Khám phá thêm món Việt',
  StrKey.regionHanoi: 'Hà Nội',
  StrKey.regionCentral: 'Miền Trung',
  StrKey.regionSaigonNight: 'Sài Gòn đêm',
  StrKey.regionThreeRegions: 'Hương vị ba miền',
  StrKey.catNoodles: 'Bún & mì',
  StrKey.catSavoryCakes: 'Bánh mặn',
  StrKey.catRolls: 'Cuốn & bánh',
  StrKey.catRice: 'Cơm & xôi',
  StrKey.catHotpot: 'Món lẩu',
  StrKey.catSnacks: 'Ăn vặt',
  StrKey.catDrinks: 'Đồ uống',
  StrKey.filterTitle: 'Bộ lọc & giờ ăn',
  StrKey.filterMealTime: 'Buổi ăn',
  StrKey.mealMorning: 'Sáng',
  StrKey.mealNoon: 'Trưa',
  StrKey.mealAfternoon: 'Xế',
  StrKey.mealEvening: 'Tối',
  StrKey.mealLateNight: 'Khuya',
  StrKey.filterRadius: 'Bán kính tới quán',
  StrKey.filterTimeWindow: 'Khung giờ',
  StrKey.filterFrom: 'Từ',
  StrKey.filterTo: 'Đến',
  StrKey.filterAnyTime: 'Bất kỳ',
  StrKey.filterTimeNote: 'Giờ Việt Nam · 30–120 phút · khung 15 phút',
  StrKey.filterDate: 'Ngày',
  StrKey.today: 'Hôm nay',
  StrKey.tomorrow: 'Ngày mai',
  StrKey.weekdayMon: 'T2',
  StrKey.weekdayTue: 'T3',
  StrKey.weekdayWed: 'T4',
  StrKey.weekdayThu: 'T5',
  StrKey.weekdayFri: 'T6',
  StrKey.weekdaySat: 'T7',
  StrKey.weekdaySun: 'CN',
  StrKey.filterApply: 'Áp dụng',
  StrKey.filterReset: 'Đặt lại',
  StrKey.areaSheetTitle: 'Vị trí của bạn',
  StrKey.areaSheetBody:
      'Cho phép vị trí để tìm điểm hẹn tại quán gần đây. Vị trí không được dùng để ghép người và không hiển thị cho người khác.',
  StrKey.allowLocation: 'Cho phép vị trí',
  StrKey.maybeLater: 'Để sau',
  StrKey.areaOrChoose: 'Hoặc chọn khu vực',
  StrKey.areaCenterNote: 'Dùng tâm khu vực đã chọn để tìm kiếm.',
  StrKey.locationComingSoon: 'Tính năng này sẽ có ở bản sau.',
  StrKey.areaClear: 'Bỏ chọn khu vực',
  StrKey.changeArea: 'Đổi',
  StrKey.tablesError:
      'Không tải được danh sách bàn. Kiểm tra mạng rồi thử lại nhé.',
  StrKey.tablesEmpty: 'Chưa có bàn nào quanh đây. Mở bàn mới nhé?',
  StrKey.seeTomorrow: 'Xem ngày mai',
  StrKey.seeToday: 'Xem hôm nay',
  StrKey.widenRadius: 'Nới bán kính lên {radius}',
  StrKey.joinTable: 'Tham gia',
  StrKey.tableFull: 'Đã đầy',
  StrKey.tableJoined: 'Đã tham gia',
  StrKey.seatsLeft: 'Còn {left}/{total} chỗ',
  StrKey.seatsFull: 'Đủ {total}/{total} chỗ',
  StrKey.noDishChosen: 'Chưa chọn món',
  StrKey.joinSuccess: 'Đã tham gia bàn. Hẹn gặp bạn tại quán!',
  StrKey.joinFailed: 'Chưa tham gia được bàn. Thử lại nhé.',
  StrKey.tablesTitle: 'Bàn còn chỗ',
  StrKey.tablesSubtitle: 'Chọn điểm hẹn tại quán và giờ ăn phù hợp.',
  StrKey.chooseArea: 'Chọn khu vực',
  StrKey.chooseAreaHint: 'Dùng vị trí để tìm điểm hẹn tại quán.',
  StrKey.profileTitle: 'Hồ sơ của bạn',
  StrKey.profileSubtitle:
      'Bàn ăn, phản hồi riêng tư, báo cáo và danh sách chặn.',
  StrKey.tabMyTables: 'Bàn của tôi',
  StrKey.tabAccount: 'Tài khoản',
  StrKey.myTablesHeading: 'Bàn ăn của bạn',
  StrKey.myTablesGuest: 'Đăng nhập để xem những bàn ăn của bạn.',
  StrKey.myTablesMemberPlaceholder: 'Danh sách bàn của bạn sẽ hiện ở đây.',
  StrKey.guestTitle: 'Khách ghé chơi',
  StrKey.guestBody:
      'Đăng nhập để xem lại bàn, trò chuyện và quản lý phản hồi riêng tư.',
  StrKey.signIn: 'Đăng nhập',
  StrKey.signOut: 'Đăng xuất',
  StrKey.privateFeedback: 'Phản hồi riêng tư',
  StrKey.reportsSent: 'Báo cáo đã gửi',
  StrKey.blockList: 'Danh sách chặn',
  StrKey.loginTitle: 'Vào hội thôi!',
  StrKey.loginBody: 'Đăng nhập để xem thành viên, tham gia bàn và trò chuyện. Đăng nhập không tự tham gia hay mở bàn.',
  StrKey.continueWithGoogle: 'Tiếp tục với Google',
  StrKey.loginNote: 'Không cần mật khẩu. Chỉ cần một chiếc bụng đói.',
  StrKey.privacyPolicy: 'Chính sách quyền riêng tư',
  StrKey.termsOfUse: 'Điều khoản sử dụng',
  StrKey.loginFailed: 'Đăng nhập chưa thành công. Thử lại nhé.',
  StrKey.errTableNotFound: 'Không tìm thấy bàn này.',
  StrKey.errTableFull: 'Bàn này đã đầy.',
  StrKey.errTableStarted: 'Bàn này đã bắt đầu rồi.',
  StrKey.errTableCancelled: 'Bàn này đã bị huỷ.',
  StrKey.errTableEnded: 'Bàn này đã kết thúc.',
  StrKey.errTableOverlap: 'Bạn đã có một bàn khác trùng khung giờ này.',
  StrKey.errTableInvalidTime: 'Giờ chưa hợp lệ: phải ở tương lai, theo bước 15 phút, kéo dài 30–120 phút.',
  StrKey.errTableInvalidCapacity: 'Số chỗ phải từ 2 đến 8.',
  StrKey.errTableAlreadyMember: 'Bạn đã ở trong bàn này rồi.',
  StrKey.errTableNotMember: 'Bạn không ở trong bàn này.',
  StrKey.errTableNotHost: 'Chỉ chủ bàn mới làm được việc này.',
};

const Map<StrKey, String> enStrings = {
  StrKey.appName: 'Ăn Gì Đây Ta?',
  StrKey.appNameWithEyes: 'Ăn Gì Đây Ta? 👀',
  StrKey.tagline: 'Good food • New friends • Real connections',
  StrKey.notBuiltYet: 'This feature is not built yet.',
  StrKey.tabExplore: 'Explore',
  StrKey.tabTables: 'Tables',
  StrKey.tabSchedule: 'Schedule',
  StrKey.tabMe: 'Me',
  StrKey.createTable: 'New table',
  StrKey.semLanguage: 'Change language',
  StrKey.semDice: 'Spin for a dish',
  StrKey.semProfile: 'Profile',
  StrKey.chooseLocation: 'Choose location',
  StrKey.exploreTitle: 'Pick a dish to start a meetup',
  StrKey.exploreSubtitle:
      'Pick a dish → See venues and times → Confirm to join.',
  StrKey.searchHint: 'Search dishes…',
  StrKey.dishesEmpty: 'No matching dishes found.',
  StrKey.dishesError:
      "Couldn't load the dishes. Check your connection and try again.",
  StrKey.retry: 'Try again',
  StrKey.findTable: 'Find a table',
  StrKey.dishDetailPending: 'Dish details: no design yet.',
  StrKey.seeAllDishes: 'See all {n} dishes',
  StrKey.allDishesTitle: 'All dishes',
  StrKey.suggestTitle: 'Picks for you',
  StrKey.suggestSubtitle:
      'Pick by taste, by mood, or see what everyone is craving.',
  StrKey.tabTaste: 'By taste',
  StrKey.tabMood: 'By mood',
  StrKey.tabHot: 'Trending',
  StrKey.suggestPickTaste: 'Pick a taste to see suggested dishes.',
  StrKey.suggestPickMood: 'Pick a mood to see suggested dishes.',
  StrKey.tasteSpicy: 'Spicy & numbing',
  StrKey.tasteGrilled: 'Grilled meat',
  StrKey.tasteVegetarian: 'Light & vegetarian',
  StrKey.tasteNoodleSoup: 'Noodles & broth',
  StrKey.tasteRice: 'Fluffy rice',
  StrKey.tasteSeafood: 'Seafood',
  StrKey.tasteSweet: 'Sweet desserts',
  StrKey.tasteCoffee: 'Strong coffee',
  StrKey.moodCozy: 'Warm & cozy',
  StrKey.moodLight: 'Light & easy',
  StrKey.moodSocial: 'Hanging out',
  StrKey.moodEnergetic: 'Need energy',
  StrKey.moodSweetTooth: 'Sweet tooth',
  StrKey.moodRefreshing: 'Cool down',
  StrKey.regionsTitle: 'Flavors of three regions',
  StrKey.regionsSubtitle: 'More than good food, a story of culture.',
  StrKey.regionsMore: 'Discover more Vietnamese dishes',
  StrKey.regionHanoi: 'Hanoi',
  StrKey.regionCentral: 'Central Vietnam',
  StrKey.regionSaigonNight: 'Saigon at night',
  StrKey.regionThreeRegions: 'Tastes of every region',
  StrKey.catNoodles: 'Noodles',
  StrKey.catSavoryCakes: 'Savory cakes',
  StrKey.catRolls: 'Rolls & pancakes',
  StrKey.catRice: 'Rice & sticky rice',
  StrKey.catHotpot: 'Hot pot',
  StrKey.catSnacks: 'Snacks',
  StrKey.catDrinks: 'Drinks',
  StrKey.filterTitle: 'Filters & meal time',
  StrKey.filterMealTime: 'Meal time',
  StrKey.mealMorning: 'Morning',
  StrKey.mealNoon: 'Noon',
  StrKey.mealAfternoon: 'Afternoon',
  StrKey.mealEvening: 'Evening',
  StrKey.mealLateNight: 'Late night',
  StrKey.filterRadius: 'Distance to venue',
  StrKey.filterTimeWindow: 'Time window',
  StrKey.filterFrom: 'From',
  StrKey.filterTo: 'To',
  StrKey.filterAnyTime: 'Any',
  StrKey.filterTimeNote: 'Vietnam time · 30–120 min · 15-minute steps',
  StrKey.filterDate: 'Date',
  StrKey.today: 'Today',
  StrKey.tomorrow: 'Tomorrow',
  StrKey.weekdayMon: 'Mon',
  StrKey.weekdayTue: 'Tue',
  StrKey.weekdayWed: 'Wed',
  StrKey.weekdayThu: 'Thu',
  StrKey.weekdayFri: 'Fri',
  StrKey.weekdaySat: 'Sat',
  StrKey.weekdaySun: 'Sun',
  StrKey.filterApply: 'Apply',
  StrKey.filterReset: 'Reset',
  StrKey.areaSheetTitle: 'Your location',
  StrKey.areaSheetBody:
      'Allow location to find nearby meeting spots. Your location is never used to match people and is never shown to others.',
  StrKey.allowLocation: 'Allow location',
  StrKey.maybeLater: 'Not now',
  StrKey.areaOrChoose: 'Or choose an area',
  StrKey.areaCenterNote: "We'll search around the center of the area you pick.",
  StrKey.locationComingSoon: 'This feature will be available in a later version.',
  StrKey.areaClear: 'Clear area',
  StrKey.changeArea: 'Change',
  StrKey.tablesError:
      "Couldn't load the tables. Check your connection and try again.",
  StrKey.tablesEmpty: 'No tables around here yet. Why not open a new one?',
  StrKey.seeTomorrow: 'See tomorrow',
  StrKey.seeToday: 'See today',
  StrKey.widenRadius: 'Widen radius to {radius}',
  StrKey.joinTable: 'Join',
  StrKey.tableFull: 'Full',
  StrKey.tableJoined: 'Joined',
  StrKey.seatsLeft: '{left}/{total} seats left',
  StrKey.seatsFull: '{total}/{total} seats taken',
  StrKey.noDishChosen: 'No dish chosen yet',
  StrKey.joinSuccess: "You're in! See you at the table.",
  StrKey.joinFailed: "Couldn't join the table. Please try again.",
  StrKey.tablesTitle: 'Tables with seats',
  StrKey.tablesSubtitle: 'Choose a venue and a time that suit you.',
  StrKey.chooseArea: 'Choose area',
  StrKey.chooseAreaHint: 'Use your location to find meeting spots nearby.',
  StrKey.profileTitle: 'Your profile',
  StrKey.profileSubtitle:
      'Tables, private feedback, reports and your block list.',
  StrKey.tabMyTables: 'My tables',
  StrKey.tabAccount: 'Account',
  StrKey.myTablesHeading: 'Your tables',
  StrKey.myTablesGuest: 'Sign in to see your tables.',
  StrKey.myTablesMemberPlaceholder: 'Your tables will show up here.',
  StrKey.guestTitle: 'Guest visitor',
  StrKey.guestBody:
      'Sign in to revisit your tables, chat and manage private feedback.',
  StrKey.signIn: 'Sign in',
  StrKey.signOut: 'Sign out',
  StrKey.privateFeedback: 'Private feedback',
  StrKey.reportsSent: 'Reports sent',
  StrKey.blockList: 'Block list',
  StrKey.loginTitle: "Let's get in!",
  StrKey.loginBody: 'Sign in to see members, join tables and chat. Signing in never joins or opens a table for you.',
  StrKey.continueWithGoogle: 'Continue with Google',
  StrKey.loginNote: 'No password needed. Just an empty stomach.',
  StrKey.privacyPolicy: 'Privacy Policy',
  StrKey.termsOfUse: 'Terms of Use',
  StrKey.loginFailed: "Couldn't sign in. Please try again.",
  StrKey.errTableNotFound: "We couldn't find this table.",
  StrKey.errTableFull: 'This table is full.',
  StrKey.errTableStarted: 'This table has already started.',
  StrKey.errTableCancelled: 'This table was cancelled.',
  StrKey.errTableEnded: 'This table has ended.',
  StrKey.errTableOverlap: 'You already have another table at this time.',
  StrKey.errTableInvalidTime: 'Invalid time: it must be in the future, on a 15-minute step, lasting 30–120 minutes.',
  StrKey.errTableInvalidCapacity: 'Seats must be between 2 and 8.',
  StrKey.errTableAlreadyMember: "You're already at this table.",
  StrKey.errTableNotMember: "You're not at this table.",
  StrKey.errTableNotHost: 'Only the host can do this.',
};

// Bộ chuỗi theo ngôn ngữ. Gọi như hàm: t(StrKey.tabExplore).
class Strings {
  const Strings(this.language);

  final AppLanguage language;

  Map<StrKey, String> get _table =>
      language == AppLanguage.vi ? viStrings : enStrings;

  String call(StrKey key) => _table[key] ?? key.name;

  // Điền chỗ trống dạng {tên} trong một chuỗi: fill(StrKey.seatsLeft, {'left': '2', 'total': '4'}).
  String fill(StrKey key, Map<String, Object> params) {
    var text = call(key);
    params.forEach((name, value) => text = text.replaceAll('{$name}', '$value'));
    return text;
  }

  // "Còn 2/4 chỗ"; bàn đầy thì "Đủ 4/4 chỗ".
  String seatsLabel(int left, int total) => left <= 0
      ? fill(StrKey.seatsFull, {'total': total})
      : fill(StrKey.seatsLeft, {'left': left, 'total': total});

  // "Nới bán kính lên 10 km".
  String widenRadiusLabel(int radiusM) =>
      fill(StrKey.widenRadius, {'radius': formatRadius(radiusM)});

  // Khoảng giờ của bàn theo ngôn ngữ: "11:30–12:30" (VI) hoặc "11:30 AM–12:30 PM" (EN).
  String timeRange(DateTime start, int durationMin) {
    final end = start.add(Duration(minutes: durationMin));
    return '${formatClockTime(start, language)}–${formatClockTime(end, language)}';
  }

  // Tóm tắt bộ lọc đang dùng, ví dụ "1 km · Hôm nay · 05/10 · Tối · 17:00–21:00".
  String filterSummary({
    required int radiusM,
    required DateTime date,
    required DateTime today,
    MealTime? mealTime,
    int? fromMinute,
    int? toMinute,
  }) {
    final parts = [
      formatRadius(radiusM),
      dayLabel(date, today),
      if (mealTime != null) mealTimeLabel(mealTime),
      if (fromMinute != null || toMinute != null)
        '${fromMinute == null ? '' : formatMinuteOfDay(fromMinute)}–${toMinute == null ? '' : formatMinuteOfDay(toMinute)}',
    ];
    return parts.join(' · ');
  }

  // Chuỗi có chỗ trống dạng {n}: seeAll(56) -> "Xem tất cả 56 món ngon".
  String seeAllDishesLabel(int count) =>
      call(StrKey.seeAllDishes).replaceAll('{n}', '$count');

  // Nhãn khẩu vị và tâm trạng (chip ở mục "Gợi ý cho bạn").
  String tasteLabel(Taste taste) {
    return call(switch (taste) {
      Taste.spicy => StrKey.tasteSpicy,
      Taste.grilled => StrKey.tasteGrilled,
      Taste.vegetarian => StrKey.tasteVegetarian,
      Taste.noodleSoup => StrKey.tasteNoodleSoup,
      Taste.rice => StrKey.tasteRice,
      Taste.seafood => StrKey.tasteSeafood,
      Taste.sweet => StrKey.tasteSweet,
      Taste.coffee => StrKey.tasteCoffee,
    });
  }

  String moodLabel(Mood mood) {
    return call(switch (mood) {
      Mood.cozy => StrKey.moodCozy,
      Mood.light => StrKey.moodLight,
      Mood.social => StrKey.moodSocial,
      Mood.energetic => StrKey.moodEnergetic,
      Mood.sweetTooth => StrKey.moodSweetTooth,
      Mood.refreshing => StrKey.moodRefreshing,
    });
  }

  // Tên vùng ở dải "ba miền" (dữ liệu lưu tiếng Việt). Vùng lạ giữ nguyên.
  String regionLabel(String region) {
    final key = _regionKeys[region];
    return key == null ? region : call(key);
  }

  // Tên danh mục món đã dịch. Danh mục lạ (không có trong bảng) giữ nguyên.
  String categoryLabel(String category) {
    final key = _categoryKeys[category];
    return key == null ? category : call(key);
  }

  // Nhãn buổi ăn: Sáng, Trưa, Xế, Tối, Khuya.
  String mealTimeLabel(MealTime meal) {
    return call(switch (meal) {
      MealTime.morning => StrKey.mealMorning,
      MealTime.noon => StrKey.mealNoon,
      MealTime.afternoon => StrKey.mealAfternoon,
      MealTime.evening => StrKey.mealEvening,
      MealTime.lateNight => StrKey.mealLateNight,
    });
  }

  // Nhãn ngày kèm ngày thực tế: "Hôm nay · 05/10", "Ngày mai · 06/10", "T4 · 07/10".
  String dayLabel(DateTime date, DateTime today) {
    final String name;
    if (isSameDay(date, today)) {
      name = call(StrKey.today);
    } else if (isSameDay(date, today.add(const Duration(days: 1)))) {
      name = call(StrKey.tomorrow);
    } else {
      name = call(_weekdayKeys[date.weekday - 1]);
    }
    return '$name · ${formatDayMonth(date)}';
  }

  // Thông báo cho từng lý do lỗi khi thao tác với bàn.
  String tableError(TableError error) {
    return call(switch (error) {
      TableError.notFound => StrKey.errTableNotFound,
      TableError.full => StrKey.errTableFull,
      TableError.alreadyStarted => StrKey.errTableStarted,
      TableError.cancelled => StrKey.errTableCancelled,
      TableError.ended => StrKey.errTableEnded,
      TableError.overlap => StrKey.errTableOverlap,
      TableError.invalidTime => StrKey.errTableInvalidTime,
      TableError.invalidCapacity => StrKey.errTableInvalidCapacity,
      TableError.alreadyMember => StrKey.errTableAlreadyMember,
      TableError.notMember => StrKey.errTableNotMember,
      TableError.notHost => StrKey.errTableNotHost,
    });
  }
}

// Thứ trong tuần theo DateTime.weekday (1 = thứ Hai ... 7 = Chủ nhật).
const _weekdayKeys = [
  StrKey.weekdayMon,
  StrKey.weekdayTue,
  StrKey.weekdayWed,
  StrKey.weekdayThu,
  StrKey.weekdayFri,
  StrKey.weekdaySat,
  StrKey.weekdaySun,
];

// Dữ liệu món lưu tên vùng bằng tiếng Việt; bảng này nối sang khoá chuỗi.
const _regionKeys = <String, StrKey>{
  'Hà Nội': StrKey.regionHanoi,
  'Miền Trung': StrKey.regionCentral,
  'Sài Gòn đêm': StrKey.regionSaigonNight,
  'Hương vị ba miền': StrKey.regionThreeRegions,
};

// Dữ liệu món lưu tên danh mục bằng tiếng Việt; bảng này nối sang khoá chuỗi.
const _categoryKeys = <String, StrKey>{
  'Bún & mì': StrKey.catNoodles,
  'Bánh mặn': StrKey.catSavoryCakes,
  'Cuốn & bánh': StrKey.catRolls,
  'Cơm & xôi': StrKey.catRice,
  'Món lẩu': StrKey.catHotpot,
  'Ăn vặt': StrKey.catSnacks,
  'Đồ uống': StrKey.catDrinks,
};

// Mã ngôn ngữ ngắn hiện trên nút đổi ngôn ngữ: hiện NGÔN NGỮ SẼ CHUYỂN SANG.
String languageButtonLabel(AppLanguage current) =>
    current == AppLanguage.vi ? 'EN' : 'VI';
