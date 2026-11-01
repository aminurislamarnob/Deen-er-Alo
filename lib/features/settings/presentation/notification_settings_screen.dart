import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/app_back_button.dart';
import '../domain/notification_settings.dart';
import 'notification_settings_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 64,
        leading: const Center(
          child: Padding(
            padding: EdgeInsets.only(left: 16),
            child: AppBackButton(),
          ),
        ),
        title: const Text(
          'আযান ও অ্যালার্ম সেটিংস',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bellRing, color: AppColors.primary),
            tooltip: 'টেস্ট নোটিফিকেশন',
            onPressed: () async {
              await NotificationService.instance.requestPermissions();
              await NotificationService.instance.showInstantNotification(
                id: 9999,
                title: 'দ্বীনের আলো (নোটিফিকেশন সক্রিয়)',
                body: 'নামাজের অ্যালার্ম এবং ওয়াক্ত নোটিফিকেশন সফলভাবে কাজ করছে।',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('টেস্ট নোটিফিকেশন পাঠানো হয়েছে'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // Master Switch Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: settings.masterEnabled
                  ? AppColors.cardHeaderGradient
                  : const LinearGradient(
                      colors: [Color(0xFF64748B), Color(0xFF475569)],
                    ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.bell,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'সকল নোটিফিকেশন ও অ্যালার্ম',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'ওয়াক্ত হলে আযান বা নোটিফিকেশন শুনুন',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: settings.masterEnabled,
                  activeTrackColor: Colors.white30,
                  activeThumbColor: AppColors.gold,
                  onChanged: (val) => notifier.toggleMaster(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 5 Daily Prayers Section
          _buildSectionHeader('৫ ওয়াক্ত নামাজের আযান ও সতর্কতা'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                _buildPrayerTile(
                  context: context,
                  title: 'ফজর (Fajr)',
                  subtitle: 'ভোরের নামাজ ও তাহাজ্জুদ সমাপ্তি',
                  tone: settings.fajrTone,
                  onSelect: (tone) => notifier.setTone('fajr', tone),
                ),
                _buildDivider(),
                _buildPrayerTile(
                  context: context,
                  title: 'জোহর (Dhuhr)',
                  subtitle: 'দুপুরের নামাজ',
                  tone: settings.dhuhrTone,
                  onSelect: (tone) => notifier.setTone('dhuhr', tone),
                ),
                _buildDivider(),
                _buildPrayerTile(
                  context: context,
                  title: 'আসর (Asr)',
                  subtitle: 'বিকেলের নামাজ',
                  tone: settings.asrTone,
                  onSelect: (tone) => notifier.setTone('asr', tone),
                ),
                _buildDivider(),
                _buildPrayerTile(
                  context: context,
                  title: 'মাগরিব (Maghrib)',
                  subtitle: 'সূর্যাস্ত ও ইফতার',
                  tone: settings.maghribTone,
                  onSelect: (tone) => notifier.setTone('maghrib', tone),
                ),
                _buildDivider(),
                _buildPrayerTile(
                  context: context,
                  title: 'ইশা (Isha)',
                  subtitle: 'রাতের নামাজ ও তারাবীহ',
                  tone: settings.ishaTone,
                  onSelect: (tone) => notifier.setTone('isha', tone),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Voluntary Prayers (Sunnah)
          _buildSectionHeader('নফল সালাতের স্মরণিকা'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: LucideIcons.moon,
                  title: 'তাহাজ্জুদ সালাত',
                  subtitle: 'ফজরের ৪৫ মিনিট পূর্বে রিমাইন্ডার',
                  value: settings.tahajjudReminder,
                  onChanged: (val) => notifier.toggleTahajjud(val),
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: LucideIcons.sun,
                  title: 'সালাতুদ দুহা / চাশত',
                  subtitle: 'সূর্যোদয়ের ২৫ মিনিট পর উত্তম সময়ে নোটিফিকেশন',
                  value: settings.duhaReminder,
                  onChanged: (val) => notifier.toggleDuha(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Fasting & Ramadan Warnings
          _buildSectionHeader('রোজা ও সাহরি-ইফতারের সতর্কতা'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: LucideIcons.utensils,
                  title: 'সাহরির সমাপ্তি সতর্কবার্তা',
                  subtitle: 'সাহরি শেষ হওয়ার ১৫ মিনিট পূর্বে জরুরি অ্যালার্ম',
                  value: settings.sehriWarning,
                  onChanged: (val) => notifier.toggleSehriWarning(val),
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: LucideIcons.soup,
                  title: 'ইফতারের প্রস্তুতি স্মরণিকা',
                  subtitle: 'মাগরিবের ১০ মিনিট পূর্বে দোয়া ও প্রস্তুতির বার্তা',
                  value: settings.iftarReminder,
                  onChanged: (val) => notifier.toggleIftarReminder(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Daily Adhkar
          _buildSectionHeader('মাসনুন জিকির ও তাসবীহ'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: _buildSwitchTile(
              icon: LucideIcons.sparkles,
              title: 'সকাল ও সন্ধ্যার মাসনুন জিকির',
              subtitle: 'সকালে সূর্যোদয়ের পর এবং বিকেলে মাগরিবের পূর্বে স্মরণিকা',
              value: settings.dailyAdhkarReminder,
              onChanged: (val) => notifier.toggleAdhkar(val),
            ),
          ),

          const SizedBox(height: 24),

          // Advance Minutes Offset
          _buildSectionHeader('ওয়াক্তের কত পূর্বে অ্যালার্ম চান?'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildChip(
                  label: 'ঠিক সময়ে (০ মিনিট)',
                  selected: settings.advanceMinutes == 0,
                  onTap: () => notifier.setAdvanceMinutes(0),
                ),
                _buildChip(
                  label: '৫ মিনিট পূর্বে',
                  selected: settings.advanceMinutes == 5,
                  onTap: () => notifier.setAdvanceMinutes(5),
                ),
                _buildChip(
                  label: '১০ মিনিট পূর্বে',
                  selected: settings.advanceMinutes == 10,
                  onTap: () => notifier.setAdvanceMinutes(10),
                ),
                _buildChip(
                  label: '১৫ মিনিট পূর্বে',
                  selected: settings.advanceMinutes == 15,
                  onTap: () => notifier.setAdvanceMinutes(15),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Battery Optimization Help Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.shieldAlert,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'অ্যালার্ম ঠিক সময়ে বাজছে না?',
                        style: TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Xiaomi, Vivo, Oppo বা Samsung ফোনে ফোনের সেটিংস থেকে "ব্যাটারি সেভার / অপটিমাইজেশন" অপশন বন্ধ করুন এবং Auto-Start পারমিশন দিন, যাতে অ্যান্ড্রয়েড স্লিপ মোডে অ্যালার্ম বন্ধ না হয়।',
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSubdued,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: AppColors.cardBorder);
  }

  Widget _buildPrayerTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required NotificationAlarmTone tone,
    required ValueChanged<NotificationAlarmTone> onSelect,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
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
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tone == NotificationAlarmTone.off
              ? Colors.grey.shade100
              : AppColors.primaryLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: tone == NotificationAlarmTone.off
                ? Colors.grey.shade300
                : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tone.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tone == NotificationAlarmTone.off
                    ? Colors.grey.shade600
                    : AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronDown,
              size: 14,
              color: tone == NotificationAlarmTone.off
                  ? Colors.grey.shade600
                  : AppColors.primary,
            ),
          ],
        ),
      ),
      onTap: () => _showTonePicker(context, title, tone, onSelect),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
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
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  void _showTonePicker(
    BuildContext context,
    String prayerTitle,
    NotificationAlarmTone currentTone,
    ValueChanged<NotificationAlarmTone> onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$prayerTitle — সতর্কতা মোড',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                ...NotificationAlarmTone.values.map((tone) {
                  final isSelected = tone == currentTone;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isSelected
                          ? LucideIcons.circleCheck
                          : LucideIcons.circle,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade400,
                    ),
                    title: Text(
                      tone.label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textDark,
                      ),
                    ),
                    onTap: () {
                      onSelect(tone);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
