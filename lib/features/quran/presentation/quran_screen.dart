import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Al-Quran (আল-কুরআন)'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.cardHeaderGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Read',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Al-Baqarah (সূরা আল-বাকারা)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ayah 255 (Ayat al-Kursi)',
                          style: TextStyle(
                            color: AppColors.textLightSubdued,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.gold,
                    size: 40,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Surahs (114)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildSurahTile(1, 'Al-Fatihah', 'আল-ফাতিহা', 'The Opening', 7, 'الفاتحة'),
            _buildSurahTile(2, 'Al-Baqarah', 'আল-বাকারা', 'The Cow', 286, 'البقرة'),
            _buildSurahTile(3, 'Ali \'Imran', 'আল-ইমরান', 'Family of Imran', 200, 'آل عمران'),
            _buildSurahTile(4, 'An-Nisa', 'আন-নিসা', 'The Women', 176, 'النساء'),
            _buildSurahTile(5, 'Al-Ma\'idah', 'আল-মায়িদাহ', 'The Table Spread', 120, 'المائدة'),
            _buildSurahTile(6, 'Al-An\'am', 'আল-আনআম', 'The Cattle', 165, 'الأنعام'),
            _buildSurahTile(36, 'Ya-Sin', 'ইয়াসীন', 'Ya-Sin', 83, 'يس'),
            _buildSurahTile(55, 'Ar-Rahman', 'আর-রহমান', 'The Beneficent', 78, 'الرحمن'),
            _buildSurahTile(67, 'Al-Mulk', 'আল-মুলক', 'The Sovereignty', 30, 'الملك'),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahTile(
    int number,
    String nameEn,
    String nameBn,
    String meaning,
    int verses,
    String arabicText,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$nameEn ($nameBn)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$meaning • $verses verses',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSubdued,
                  ),
                ),
              ],
            ),
          ),
          Text(
            arabicText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
