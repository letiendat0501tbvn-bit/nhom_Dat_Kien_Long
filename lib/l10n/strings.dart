import '../data/models/enums.dart';
import '../data/repositories/table_repository.dart';

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
  filterByCategory,
  all,
  dishesEmpty,
  dishesError,
  retry,
  findTable,
  catNoodles,
  catSavoryCakes,
  catRolls,
  catRice,
  catHotpot,
  catSnacks,
  catDrinks,
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
  StrKey.filterByCategory: 'Lọc theo danh mục',
  StrKey.all: 'Tất cả',
  StrKey.dishesEmpty: 'Không tìm thấy món phù hợp.',
  StrKey.dishesError:
      'Không tải được danh sách món. Kiểm tra mạng rồi thử lại nhé.',
  StrKey.retry: 'Thử lại',
  StrKey.findTable: 'Tìm bàn ăn',
  StrKey.catNoodles: 'Bún & mì',
  StrKey.catSavoryCakes: 'Bánh mặn',
  StrKey.catRolls: 'Cuốn & bánh',
  StrKey.catRice: 'Cơm & xôi',
  StrKey.catHotpot: 'Món lẩu',
  StrKey.catSnacks: 'Ăn vặt',
  StrKey.catDrinks: 'Đồ uống',
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
  StrKey.loginBody:
      'Đăng nhập để xem thành viên, tham gia bàn và trò chuyện. Đăng nhập không tự tham gia hay mở bàn.',
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
  StrKey.errTableInvalidTime:
      'Giờ chưa hợp lệ: phải ở tương lai, theo bước 15 phút, kéo dài 30–120 phút.',
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
  StrKey.filterByCategory: 'Filter by category',
  StrKey.all: 'All',
  StrKey.dishesEmpty: 'No matching dishes found.',
  StrKey.dishesError:
      "Couldn't load the dishes. Check your connection and try again.",
  StrKey.retry: 'Try again',
  StrKey.findTable: 'Find a table',
  StrKey.catNoodles: 'Noodles',
  StrKey.catSavoryCakes: 'Savory cakes',
  StrKey.catRolls: 'Rolls & pancakes',
  StrKey.catRice: 'Rice & sticky rice',
  StrKey.catHotpot: 'Hot pot',
  StrKey.catSnacks: 'Snacks',
  StrKey.catDrinks: 'Drinks',
  StrKey.tablesTitle: 'Tables with seats',
  StrKey.tablesSubtitle: 'Choose a venue and a time that suit you.',
  StrKey.chooseArea: 'Choose area',
  StrKey.chooseAreaHint: 'Use your location to find meeting spots nearby.',
  StrKey.profileTitle: 'Your profile',
  StrKey.profileSubtitle: 'Tables, private feedback, reports and your block list.',
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
  StrKey.loginBody:
      'Sign in to see members, join tables and chat. Signing in never joins or opens a table for you.',
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
  StrKey.errTableInvalidTime:
      'Invalid time: it must be in the future, on a 15-minute step, lasting 30–120 minutes.',
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

  // Tên danh mục món đã dịch. Danh mục lạ (không có trong bảng) giữ nguyên.
  String categoryLabel(String category) {
    final key = _categoryKeys[category];
    return key == null ? category : call(key);
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
