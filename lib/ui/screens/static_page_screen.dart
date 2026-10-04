import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../theme/app_theme.dart';

// Trang văn bản dùng chung cho các trang tĩnh (mục 4.11 SPEC): tiêu đề, các đoạn, cuộn được.
// Nội dung nằm trong l10n và là NỘI DUNG MẪU (có dòng ghi chú rõ trên màn).
// Đoạn bắt đầu bằng "## " là tiêu đề mục.
class StaticPageScreen extends StatelessWidget {
  const StaticPageScreen({super.key, required this.page});

  final StaticPage page;

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final title = t.staticPageTitle(page);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề trang là heading cho trình đọc màn hình
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SampleNote(text: t(StrKey.pageSampleNote)),
              const SizedBox(height: 16),
              for (final p in t.staticPageParagraphs(page)) _paragraph(p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paragraph(String text) {
    if (text.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Semantics(
          header: true,
          child: Text(
            text.substring(3),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 16, height: 1.45)),
    );
  }
}

// Dòng ghi chú "nội dung mẫu".
class _SampleNote extends StatelessWidget {
  const _SampleNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.selectedBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(
            child: Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

// Mục "Thông tin" (tab Tài khoản, cả khách): danh sách bốn trang tĩnh.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(t(StrKey.infoTitle))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x1F000000)),
            ),
            child: Column(
              children: [
                for (final page in StaticPage.values)
                  // Material trong suốt để ListTile vẽ hiệu ứng bấm đúng trên nền thẻ trắng
                  Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      key: ValueKey('info-${page.name}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.staticPageTitle(page)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => openStaticPage(context, page),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Mở một trang tĩnh. Back quay về nơi đã mở (bảng đăng nhập, danh sách Thông tin...).
Future<void> openStaticPage(BuildContext context, StaticPage page) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => StaticPageScreen(page: page)),
  );
}

// Mở mục "Thông tin".
Future<void> openInfo(BuildContext context) {
  return Navigator.of(context)
      .push<void>(MaterialPageRoute<void>(builder: (_) => const InfoScreen()));
}
