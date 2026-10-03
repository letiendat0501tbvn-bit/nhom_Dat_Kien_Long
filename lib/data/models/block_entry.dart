// Một dòng trong danh sách chặn của người dùng.
class BlockEntry {
  const BlockEntry({
    required this.userId,
    required this.blockedUserId,
    required this.createdAt,
  });

  final String userId; // người chặn
  final String blockedUserId; // người bị chặn
  final DateTime createdAt;
}
