import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../prayer_times/presentation/city_picker_sheet.dart';
import '../../prayer_times/presentation/prayer_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCity = ref.watch(selectedCityProvider).value;
    final locationLabel = selectedCity != null
        ? '${selectedCity.name}, ${selectedCity.countryName}'
        : 'Dhaka, Bangladesh';

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Settings & More (সেটিংস)'),
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
            // App Identity Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.cardHeaderGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/app_logo.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deener Alo (দ্বীনের আলো)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Light of Faith • v1.0.0',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionHeader('PRAYER & LOCATION (নামাজ ও অবস্থান)'),
            _buildSettingTile(
              icon: LucideIcons.mapPin,
              title: 'Current Location',
              subtitle: locationLabel,
              onTap: () => CityPickerSheet.show(context),
            ),
            _buildSettingTile(
              icon: LucideIcons.landmark,
              title: 'Calculation Method',
              subtitle: 'University of Islamic Sciences, Karachi (Hanafi)',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: LucideIcons.badgeCheck,
              title: 'Islamic Foundation Timetable',
              subtitle: 'Official BD Permanent Schedule (Active)',
              trailing: const Icon(LucideIcons.circleCheck, color: AppColors.activeGreen, size: 20),
              onTap: () {},
            ),

            const SizedBox(height: 20),

            _buildSectionHeader('ISLAMIC TOOLS (ইসলামিক টুলস)'),
            _buildSettingTile(
              icon: LucideIcons.compass,
              title: 'Qibla Compass (ক্বিবলা কম্পাস)',
              subtitle: 'Find exact direction to Kaaba',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: LucideIcons.fingerprint,
              title: 'Digital Tasbeeh (ডিজিটাল তাসবীহ)',
              subtitle: 'Track your daily dhikr',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: LucideIcons.sparkles,
              title: '99 Names of Allah (আল্লাহর ৯৯টি নাম)',
              subtitle: 'With Bengali meaning & references',
              onTap: () {},
            ),

            const SizedBox(height: 20),

            _buildSectionHeader('GENERAL (সাধারণ)'),
            _buildSettingTile(
              icon: LucideIcons.languages,
              title: 'Language (ভাষা)',
              subtitle: 'English / বাংলা (Bengali)',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: LucideIcons.bellRing,
              title: 'Adhan & Prayer Alarms',
              subtitle: 'Customize Azan sounds & vibration',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: LucideIcons.info,
              title: 'About Deener Alo',
              subtitle: 'Privacy Policy & Terms',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSubdued,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSubdued,
          ),
        ),
        trailing: trailing ??
            const Icon(
              LucideIcons.chevronRight,
              color: AppColors.textSubdued,
              size: 20,
            ),
        onTap: onTap,
      ),
    );
  }
}
