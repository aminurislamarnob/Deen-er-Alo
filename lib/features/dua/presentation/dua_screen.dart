import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_back_button.dart';
import '../domain/dua_search.dart';
import '../domain/search_normalizer.dart';
import '../../../core/widgets/arabic_text.dart';
import '../domain/dua_content_parser.dart';
import 'dua_bookmark_provider.dart';

class DuaScreen extends ConsumerStatefulWidget {
  const DuaScreen({super.key});

  @override
  ConsumerState<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends ConsumerState<DuaScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedCategoryIndex = 0; // 0 = Bookmarks, 1..N = Categories
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DuaSearchIndex _searchIndex = DuaSearchIndex(const []);

  @override
  void initState() {
    super.initState();
    _loadDuas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDuas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final jsonStr = await rootBundle.loadString('assets/data/dua.json');
      final data = json.decode(jsonStr) as List<dynamic>;
      final index = DuaSearchIndex(_flattenDuas(data));
      if (!mounted) return;
      setState(() {
        _categories = data;
        _searchIndex = index;
        _isLoading = false;
        // Default to first real category if any
        if (_categories.isNotEmpty) {
          _selectedCategoryIndex = 1;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'দুআ লোড করা যায়নি। আবার চেষ্টা করুন।';
      });
    }
  }

  String _cleanContent(String html) => SearchNormalizer.htmlToPlainText(html);

  void _copyDua(String title, String content) {
    final clean = _cleanContent(content);
    final fullText = '$title\n\n$clean\n\nদ্বীনের আলো (Deener Alo)';
    Clipboard.setData(ClipboardData(text: fullText));
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.copyCheck, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('দুআ কপি করা হয়েছে'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareDua(String title, String content) async {
    final clean = _cleanContent(content);
    await Share.share('$title\n\n$clean\n\nদ্বীনের আলো (Deener Alo)');
  }

  List<Map<String, dynamic>> _getAllDuas() => _flattenDuas(_categories);

  static List<Map<String, dynamic>> _flattenDuas(List<dynamic> categories) {
    final List<Map<String, dynamic>> all = [];
    for (final cat in categories) {
      final list = (cat['contentList'] as List<dynamic>?) ?? [];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          all.add(item);
        }
      }
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkedIds = ref.watch(duaBookmarkProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        leadingWidth: 62,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: AppBackButton(),
        ),
        title: const Text('দুআ ও যিক্‌র (Duas & Adhkar)'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _errorMessage != null
            ? _buildErrorState()
            : Column(
                children: [
                  const SizedBox(height: 16),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() => _searchQuery = val.trim());
                        },
                        decoration: InputDecoration(
                          hintText: 'দুআ বা যিক্‌র খুঁজুন...',
                          hintStyle: const TextStyle(
                            color: AppColors.textSubdued,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            LucideIcons.search,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  tooltip: 'খোঁজা মুছুন',
                                  icon: const Icon(
                                    LucideIcons.x,
                                    color: AppColors.textSubdued,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // If searching, hide category horizontal scrollbar
                  if (_searchQuery.isEmpty) ...[
                    // Categories Horizontal Bar
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _categories.length + 1, // 0 is Bookmarks
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final isBookmarkTab = index == 0;
                          final isSelected = index == _selectedCategoryIndex;
                          final title = isBookmarkTab
                              ? 'সংরক্ষিত (${bookmarkedIds.length})'
                              : (_categories[index - 1]['categoryName']
                                        as String? ??
                                    '');

                          return InkWell(
                            onTap: () {
                              setState(() => _selectedCategoryIndex = index);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.cardBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isBookmarkTab) ...[
                                    Icon(
                                      LucideIcons.bookmark,
                                      size: 14,
                                      color: isSelected
                                          ? AppColors.gold
                                          : AppColors.goldDark,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textDark,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Dua List View
                  Expanded(child: _buildDuaList(bookmarkedIds)),
                ],
              ),
      ),
    );
  }

  Widget _buildDuaList(Set<int> bookmarkedIds) {
    List<Map<String, dynamic>> itemsToShow = [];

    if (_searchQuery.isNotEmpty) {
      // Global search across all Duas
      itemsToShow = _searchIndex.search(_searchQuery);

      if (itemsToShow.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.searchX,
                size: 44,
                color: AppColors.textSubdued.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'কোনো দুআ খুঁজে পাওয়া যায়নি',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSubdued,
                ),
              ),
            ],
          ),
        );
      }
    } else if (_selectedCategoryIndex == 0) {
      // Saved / Bookmarks Tab
      final all = _getAllDuas();
      itemsToShow = all
          .where((d) => bookmarkedIds.contains(d['id'] as int? ?? -1))
          .toList();

      if (itemsToShow.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.bookmark,
                size: 48,
                color: AppColors.gold.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'কোনো সংরক্ষিত দুআ নেই',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'পছন্দের দুআর বুকমার্ক আইকনে ট্যাপ করে সংরক্ষণ করুন।',
                style: TextStyle(fontSize: 12, color: AppColors.textSubdued),
              ),
            ],
          ),
        );
      }
    } else {
      // Specific Category
      final catIndex = _selectedCategoryIndex - 1;
      if (catIndex >= 0 && catIndex < _categories.length) {
        final selectedCat = _categories[catIndex];
        final list = (selectedCat['contentList'] as List<dynamic>?) ?? [];
        itemsToShow = list.map((e) => e as Map<String, dynamic>).toList();
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      physics: const BouncingScrollPhysics(),
      itemCount: itemsToShow.length,
      itemBuilder: (context, index) {
        final dua = itemsToShow[index];
        final id = dua['id'] as int? ?? 0;
        final title = dua['title'] as String? ?? '';
        final subtitle = dua['subtitle'] as String? ?? '';
        final content = dua['content'] as String? ?? '';
        final isBookmarked = bookmarkedIds.contains(id);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.goldDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              subtitle: subtitle.isNotEmpty
                  ? Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSubdued,
                      ),
                    )
                  : null,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _DuaContent(html: content),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          children: [
                            _buildDuaAction(
                              onPressed: () => _copyDua(title, content),
                              icon: LucideIcons.copy,
                              label: 'কপি',
                              tooltip: 'দুআ কপি করুন',
                            ),
                            _buildDuaAction(
                              onPressed: () => _shareDua(title, content),
                              icon: LucideIcons.share2,
                              label: 'শেয়ার',
                              tooltip: 'দুআ শেয়ার করুন',
                            ),
                            _buildDuaAction(
                              onPressed: () {
                                ref
                                    .read(duaBookmarkProvider.notifier)
                                    .toggleBookmark(id);
                                HapticFeedback.selectionClick();
                              },
                              icon: isBookmarked
                                  ? LucideIcons.bookmarkCheck
                                  : LucideIcons.bookmark,
                              iconSize: 15,
                              label: isBookmarked ? 'সংরক্ষিত' : 'সংরক্ষণ',
                              tooltip: isBookmarked
                                  ? 'সংরক্ষণ থেকে সরান'
                                  : 'দুআ সংরক্ষণ করুন',
                              color: isBookmarked
                                  ? AppColors.goldDark
                                  : AppColors.textSubdued,
                              selected: isBookmarked,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Compact text action with a >=48dp tap target, tooltip and semantics.
  Widget _buildDuaAction({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required String tooltip,
    double iconSize = 14,
    Color color = AppColors.textSubdued,
    bool? selected,
  }) {
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        label: tooltip,
        selected: selected,
        button: true,
        excludeSemantics: true,
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.padded,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          icon: Icon(icon, size: iconSize, color: color),
          label: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.cloudOff,
              color: AppColors.textSubdued,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadDuas,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a dua's HTML as typed blocks: Arabic right-to-left in the Arabic
/// font, headings, narrator chain, Bengali text and source reference.
class _DuaContent extends StatelessWidget {
  final String html;

  const _DuaContent({required this.html});

  @override
  Widget build(BuildContext context) {
    final blocks = DuaContentParser.parse(html);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) SizedBox(height: _gapBefore(blocks[i].kind)),
          _buildBlock(blocks[i]),
        ],
      ],
    );
  }

  static double _gapBefore(DuaBlockKind kind) {
    switch (kind) {
      case DuaBlockKind.heading:
        return 16;
      case DuaBlockKind.arabic:
        return 12;
      default:
        return 8;
    }
  }

  Widget _buildBlock(DuaBlock block) {
    switch (block.kind) {
      case DuaBlockKind.heading:
        return Text(
          block.text,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1.5,
          ),
        );
      case DuaBlockKind.arabic:
        return ArabicText(
          block.text,
          fontSize: 23,
          color: AppColors.textDark,
          height: 2.0,
        );
      case DuaBlockKind.narrator:
        return Text(
          block.text,
          style: const TextStyle(
            fontSize: 13,
            height: 1.6,
            color: AppColors.textSubdued,
          ),
        );
      case DuaBlockKind.body:
        return Text(
          block.text,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textDark,
          ),
        );
      case DuaBlockKind.reference:
        return Text(
          block.text,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSubdued,
          ),
        );
    }
  }
}
