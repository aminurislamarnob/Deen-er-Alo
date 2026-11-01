import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/allah_name_model.dart';

class NameDetailSheet extends StatelessWidget {
  final AllahName name;

  const NameDetailSheet({super.key, required this.name});

  static void show(BuildContext context, AllahName name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NameDetailSheet(name: name),
    );
  }

  void _copyToClipboard(BuildContext context) {
    final text =
        '${name.nameArabic}\n'
        '${name.pronunciationBn} (${name.transliteration})\n'
        'অর্থ: ${name.meaningBn}\n'
        'তাৎপর্য: ${name.description}\n\n'
        'দ্বীনের আলো (Deener Alo)';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.copyCheck, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('নাম ও অর্থ কপি করা হয়েছে'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    final idBn = name.id.toString().split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? bnDigits[i] : c;
    }).join();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Number badge & Transliteration
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'নাম নং $idBn (#${name.id})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyToClipboard(context),
                    icon: const Icon(
                      LucideIcons.copy,
                      size: 20,
                      color: AppColors.textSubdued,
                    ),
                    tooltip: 'কপি করুন',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Arabic calligraphy banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: AppColors.cardHeaderGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.nameArabic,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldLight,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Pronunciation & Transliteration
              Text(
                name.pronunciationBn,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name.transliteration,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSubdued,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),

              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 16),

              // Meaning
              _buildInfoRow('অর্থ (Meaning)', name.meaningBn, name.meaningEn),
              const SizedBox(height: 14),

              // Theological Virtue / Description
              if (name.description.isNotEmpty) ...[
                _buildDescriptionSection('তাৎপর্য ও ফজিলত', name.description),
                const SizedBox(height: 20),
              ],
              if (name.quranReference.isNotEmpty ||
                  name.hadithReference.isNotEmpty) ...[
                _buildReferencesSection(),
                const SizedBox(height: 20),
              ],

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ঠিক আছে',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String valueBn, String valueEn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSubdued,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valueBn,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          if (valueEn.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              valueEn,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSubdued,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReferencesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.goldMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'প্রাসঙ্গিক সূত্র',
            style: TextStyle(
              color: AppColors.goldDark,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (name.quranReference.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'কুরআন: ${name.quranReference}',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          if (name.hadithReference.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'হাদিস: ${name.hadithReference}',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(String label, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.sparkles,
                size: 14,
                color: AppColors.goldDark,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
