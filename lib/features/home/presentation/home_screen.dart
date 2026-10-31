import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../prayer_times/presentation/city_picker_sheet.dart';
import '../../prayer_times/presentation/prayer_providers.dart';
import 'fasting_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCityAsync = ref.watch(selectedCityProvider);
    final cityName = selectedCityAsync.value?.name ?? 'Dhaka';
    final countryName = selectedCityAsync.value?.countryName ?? 'Bangladesh';
    final fasting = ref.watch(fastingProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: CustomScrollView(
        slivers: [
          // Islamic Gradient Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.islamicGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Bar: Greeting + Location & Notification Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Assalamualaikum!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              InkWell(
                                onTap: () => CityPickerSheet.show(context),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$cityName, $countryName',
                                        style: const TextStyle(
                                          color: AppColors.textLightSubdued,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.textLightSubdued,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Notification Bell
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  color: AppColors.primaryDark,
                                  size: 22,
                                ),
                                Positioned(
                                  top: 10,
                                  right: 11,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.gold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Live Avatar Stories Row
                      _buildLiveStoriesRow(),

                      const SizedBox(height: 20),

                      // "Explore Ramadan" Banner Card
                      _buildExploreRamadanCard(context),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // White Content Area with Rounded Corners
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                children: [
                  // Social / Islamic Inspiration Card
                  _buildInspirationPostCard(),

                  const SizedBox(height: 16),

                  // Fasting Habit Tracker Card ("Do You Fast Today?")
                  _buildFastingCard(ref, fasting),

                  const SizedBox(height: 16),

                  // Second Feed Preview
                  _buildLecturePostPreview(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStoriesRow() {
    final stories = [
      {'title': 'Makkah', 'isLive': true, 'img': 'https://images.unsplash.com/photo-1591604129939-f1efa4d9f7fa?w=150'},
      {'title': 'Madinah', 'isLive': true, 'img': 'https://images.unsplash.com/photo-1564769625905-50e93615e769?w=150'},
      {'title': 'Al-Aqsa', 'isLive': false, 'img': 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=150'},
      {'title': 'Istanbul', 'isLive': false, 'img': 'https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?w=150'},
      {'title': 'Cairo', 'isLive': false, 'img': 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=150'},
    ];

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final s = stories[index];
          final isLive = s['isLive'] as bool;
          return Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isLive ? AppColors.gold : Colors.white24,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(s['img'] as String),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (isLive)
                    Positioned(
                      bottom: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.dangerRed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Colors.white, size: 4),
                            SizedBox(width: 2),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                s['title'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExploreRamadanCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C4631),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        image: const DecorationImage(
          image: AssetImage('assets/images/app_logo.jpg'),
          alignment: Alignment.centerRight,
          opacity: 0.15,
          fit: BoxFit.contain,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Explore Ramadan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text('✨', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Discover the Essence of a Journey of Spiritual Awakening.',
                  style: TextStyle(
                    color: AppColors.textLightSubdued,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => context.go('/checklist'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldBright,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Watch Ramadan Special',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.mosque_rounded,
                color: AppColors.gold,
                size: 52,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspirationPostCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100'),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Himaad Aziz added Islamic Picture',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSubdued),
                          SizedBox(width: 2),
                          Text(
                            'Hanoi, NJ • Jun 4 at 7:32 pm',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSubdued,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textSubdued),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Mosque Image Banner
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1542838132-92c53300491e?w=800'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Interaction Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: AppColors.dangerRed, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      '23',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                // Indicator dots
                Row(
                  children: List.generate(
                    4,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: i == 0 ? 14 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: i == 0 ? AppColors.activeGreen : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.share_outlined, size: 16, color: AppColors.textSubdued),
                    SizedBox(width: 4),
                    Text(
                      'Share',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSubdued,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFastingCard(WidgetRef ref, FastingState fasting) {
    final progress = (fasting.completedDays / fasting.targetDays).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Do You Fast Today?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Build a fasting habit with Ramadan App',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSubdued,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => ref.read(fastingProvider.notifier).toggleTodayFast(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: fasting.isFastToday
                        ? AppColors.activeGreen.withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    fasting.isFastToday
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: fasting.isFastToday
                        ? AppColors.activeGreen
                        : AppColors.inactiveMuted,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '${fasting.completedDays.toString().padLeft(2, '0')}/${fasting.targetDays}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSubdued,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE8F5E9),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.activeGreen),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text('🌙', style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLecturePostPreview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100'),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ustad Sultan added Islamic Lecture',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Dallas, NJ • Jun 4 at 8:32 pm',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSubdued,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.more_horiz_rounded, color: AppColors.textSubdued),
        ],
      ),
    );
  }
}
