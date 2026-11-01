import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_colors.dart';

class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key});

  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDuas();
  }

  Future<void> _loadDuas() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/dua.json');
      final data = json.decode(jsonStr) as List<dynamic>;
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Dua & Zikr (দুআ ও যিক্‌র)'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : Container(
              decoration: const BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Categories Horizontal Bar
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = index == _selectedCategoryIndex;
                        return InkWell(
                          onTap: () {
                            setState(() => _selectedCategoryIndex = index);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
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
                            child: Center(
                              child: Text(
                                cat['categoryName'] as String? ?? '',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textDark,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Dua List for Selected Category
                  Expanded(
                    child: _buildDuaList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDuaList() {
    if (_categories.isEmpty) {
      return const Center(child: Text('No duas found'));
    }

    final selectedCat = _categories[_selectedCategoryIndex];
    final List<dynamic> contentList =
        (selectedCat['contentList'] as List<dynamic>?) ?? [];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      physics: const BouncingScrollPhysics(),
      itemCount: contentList.length,
      itemBuilder: (context, index) {
        final dua = contentList[index];
        final title = dua['title'] as String? ?? '';
        final subtitle = dua['subtitle'] as String? ?? '';
        final content = dua['content'] as String? ?? '';

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
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      content,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
