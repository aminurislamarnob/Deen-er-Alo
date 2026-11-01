import '../../../core/utils/bangla_numbers.dart';
import '../domain/hijri_utils.dart';
import '../domain/islamic_event.dart';

class IslamicEventsRepository {
  static const String _tashreeqDescription =
      'ফরজ নামাজের পর তাকবীরে তাশরীক পাঠ করা ওয়াজিব এবং কুরবানির দিন। এ দিনগুলোতে রোজা রাখা নিষিদ্ধ।';

  static const String akhiriChaharShombaTitleBn = 'আখেরী চাহার শোম্বা';

  static const List<IslamicEvent> _events = [
    // Muharram (1)
    IslamicEvent(
      hijriMonth: 1,
      hijriDay: 1,
      titleBn: 'পবিত্র হিজরি নববর্ষ',
      titleEn: 'Islamic New Year (1st Muharram)',
      descriptionBn: 'হিজরি সনের প্রথম দিন ও পবিত্র মাস মুহররমের সূচনা।',
      isMajor: true,
    ),
    IslamicEvent(
      hijriMonth: 1,
      hijriDay: 9,
      titleBn: 'পবিত্র তাসূআ রোজা',
      titleEn: 'Day of Tasu\'a',
      descriptionBn:
          'আশুরার পূর্বে বা পরে মিলিয়ে রোজা রাখার নির্দেশ দিয়েছেন রাসূলুল্লাহ (সা.)।',
      isFastingRecommended: true,
    ),
    IslamicEvent(
      hijriMonth: 1,
      hijriDay: 10,
      titleBn: 'পবিত্র আশুরা',
      titleEn: 'Day of Ashura',
      descriptionBn:
          'মুসা (আ.) ও বনী ইসরাঈলকে ফেরাউনের হাত থেকে পরিত্রাণের ঐতিহাসিক দিবস। এদিনের রোজায় পূর্ববর্তী এক বছরের গুনাহ মাফ হয়।',
      isMajor: true,
      isFastingRecommended: true,
    ),

    // Safar (2): Akhiri Chahar Shomba is the LAST WEDNESDAY of Safar, so its
    // day varies per year. It is resolved per Gregorian date in
    // [IslamicEventsRepository.getEventsForDate].

    // Rabiul Awwal (3)
    IslamicEvent(
      hijriMonth: 3,
      hijriDay: 12,
      titleBn: 'সিরাতুন্নবী (সা.) / ঈদে মিলাদুন্নবী',
      titleEn: 'Mawlid al-Nabi / Seerat-un-Nabi',
      descriptionBn:
          'বিশ্বনবী হযরত মুহাম্মদ (সা.)-এর শুভ জন্মদিন ও সিরাত চর্চার বিশেষ দিন।',
      isMajor: true,
    ),

    // Rajab (7)
    IslamicEvent(
      hijriMonth: 7,
      hijriDay: 1,
      titleBn: 'পবিত্র রজব মাস সূচনা',
      titleEn: 'Start of Rajab',
      descriptionBn:
          'চারটি সম্মানিত (হারাম) মাসের অন্যতম। বেশি বেশি দোয়া ও রোজা রাখার মাস।',
    ),
    IslamicEvent(
      hijriMonth: 7,
      hijriDay: 27,
      titleBn: 'পবিত্র শবে মেরাজ',
      titleEn: 'Lailatul Miraj',
      descriptionBn:
          'রাসূলুল্লাহ (সা.)-এর উর্ধ্বাকাশ ভ্রমণ ও পাঁচ ওয়াক্ত সালাত ফরজ হওয়ার ঐতিহাসিক পবিত্র রজনী।',
      isMajor: true,
    ),

    // Sha'ban (8)
    IslamicEvent(
      hijriMonth: 8,
      hijriDay: 15,
      titleBn: 'পবিত্র শবে বরাত (লাইলাতুল বারাআত)',
      titleEn: 'Lailatul Barat (15th Sha\'ban)',
      descriptionBn: 'মধ্য শাবানের ফজিলতপূর্ণ রজনী ও পরদিন নফল রোজা পালন।',
      isMajor: true,
      isFastingRecommended: true,
    ),

    // Ramadan (9)
    IslamicEvent(
      hijriMonth: 9,
      hijriDay: 1,
      titleBn: 'পবিত্র মাহে রমজান শুরু',
      titleEn: 'First Day of Ramadan',
      descriptionBn: 'রহমত, মাগফিরাত ও নাজাতের মাস। সিয়াম সাধনার সূচনা।',
      isMajor: true,
      isFastingRecommended: true,
    ),
    IslamicEvent(
      hijriMonth: 9,
      hijriDay: 17,
      titleBn: 'ঐতিহাসিক বদর দিবস',
      titleEn: 'Battle of Badr Day',
      descriptionBn:
          'দ্বিতীয় হিজরির ১৭ রমজান সত্য-মিথ্যার চূড়ান্ত ফয়সালার ঐতিহাসিক যুদ্ধ।',
    ),
    IslamicEvent(
      hijriMonth: 9,
      hijriDay: 20,
      titleBn: 'ঐতিহাসিক মক্কা বিজয়',
      titleEn: 'Conquest of Makkah Day',
      descriptionBn:
          '৮ম হিজরির ২০ রমজান রক্তপাতহীন মক্কা বিজয় ও তাওহিদের পুনঃপ্রতিষ্ঠা।',
    ),
    IslamicEvent(
      hijriMonth: 9,
      hijriDay: 27,
      titleBn: 'পবিত্র শবে কদর (লাইলাতুল কদর)',
      titleEn: 'Lailatul Qadr',
      descriptionBn:
          'হাজার মাসের চেয়েও শ্রেষ্ঠ রজনী। রমজানের শেষ দশকের বিজোড় রাতগুলোতে কদর অন্বেষণ করুন।',
      isMajor: true,
    ),

    // Shawwal (10)
    IslamicEvent(
      hijriMonth: 10,
      hijriDay: 1,
      titleBn: 'পবিত্র ঈদুল ফিতর',
      titleEn: 'Eid-ul-Fitr',
      descriptionBn:
          'রমজানের সিয়াম সাধনা সমাপ্তির মহা আনন্দোৎসব ও সদকাতুল ফিতর আদায়ের দিন।',
      isMajor: true,
    ),
    IslamicEvent(
      hijriMonth: 10,
      hijriDay: 2,
      titleBn: 'শাওয়ালের ছয় রোজা সূচনা',
      titleEn: 'Six Fasts of Shawwal',
      descriptionBn:
          'রমজানের পর শাওয়ালের ৬টি নফল রোজা রাখলে সারাবছর রোজা রাখার সওয়াব মিলে।',
      isFastingRecommended: true,
    ),

    // Dhul Qadah (11)
    IslamicEvent(
      hijriMonth: 11,
      hijriDay: 1,
      titleBn: 'পবিত্র জিলকদ মাস সূচনা',
      titleEn: 'Start of Dhul Qadah',
      descriptionBn:
          'সম্মানিত চার মাসের অন্যতম। পবিত্র হজের প্রস্তুতি ও সফরের মাস।',
    ),

    // Dhul Hijjah (12)
    IslamicEvent(
      hijriMonth: 12,
      hijriDay: 1,
      titleBn: 'জিলহজের প্রথম দশক সূচনা',
      titleEn: 'First 10 Days of Dhul Hijjah',
      descriptionBn:
          'বছরের সর্বশ্রেষ্ঠ দিনসমূহ। বেশি বেশি তাকবীর, তাহলীল, তাসবীহ ও নফল রোজা রাখার উত্তম দিন।',
      isFastingRecommended: true,
    ),
    IslamicEvent(
      hijriMonth: 12,
      hijriDay: 8,
      titleBn: 'পবিত্র হজের সূচনা (তারবিয়া দিবস)',
      titleEn: 'Day of Tarwiyah',
      descriptionBn:
          'বিশ্ব মুসলিমের মিনায় অবস্থানের মধ্য দিয়ে হজ পালনের আনুষ্ঠানিক শুভ সূচনা।',
      isMajor: true,
    ),
    IslamicEvent(
      hijriMonth: 12,
      hijriDay: 9,
      titleBn: 'আরাফাহ দিবস ও হজ',
      titleEn: 'Day of Arafah',
      descriptionBn:
          'হজের প্রধান রুকন আরাফাতের ময়দানে অবস্থান। হাজি ব্যতীত অন্যদের জন্য এদিন রোজা রাখা পূর্ব ও পরের বছরের গুনাহের কাফফারা।',
      isMajor: true,
      isFastingRecommended: true,
    ),
    IslamicEvent(
      hijriMonth: 12,
      hijriDay: 10,
      titleBn: 'পবিত্র ঈদুল আজহা ও কুরবানি',
      titleEn: 'Eid-ul-Adha',
      descriptionBn:
          'হযরত ইব্রাহিম (আ.) ও ইসমাইল (আ.)-এর ত্যাগের স্মরণে ঈদের নামাজ ও পশু কুরবানির উৎসব।',
      isMajor: true,
    ),
    IslamicEvent(
      hijriMonth: 12,
      hijriDay: 11,
      titleBn: 'আইয়ামে তাশরীক (১ম দিন)',
      titleEn: 'Days of Tashreeq (11th)',
      descriptionBn: _tashreeqDescription,
    ),
    IslamicEvent(
      hijriMonth: 12,
      hijriDay: 12,
      titleBn: 'আইয়ামে তাশরীক (২য় দিন)',
      titleEn: 'Days of Tashreeq (12th)',
      descriptionBn: _tashreeqDescription,
    ),
    IslamicEvent(
      hijriMonth: 12,
      hijriDay: 13,
      titleBn: 'আইয়ামে তাশরীক (৩য় দিন)',
      titleEn: 'Days of Tashreeq (13th)',
      descriptionBn: _tashreeqDescription,
    ),
  ];

  List<IslamicEvent> getAllEvents() => _events;

  List<IslamicEvent> getEventsForHijriDate(int month, int day) {
    final list = _events
        .where((e) => e.hijriMonth == month && e.hijriDay == day)
        .toList();

    // Ayyam al-Beed (13, 14, 15 of every month), except in Ramadan and on
    // 13 Dhul Hijjah (a day of Tashreeq, when fasting is not allowed).
    if (day >= 13 && day <= 15 && month != 9 && !(month == 12 && day == 13)) {
      list.add(
        IslamicEvent(
          hijriMonth: month,
          hijriDay: day,
          titleBn:
              'আইয়ামে বিজ-এর রোজা (${BanglaUtils.toBanglaDigits(day)} তারিখ)',
          titleEn: 'Ayyam al-Beed Fasting ($day)',
          descriptionBn:
              'প্রতি হিজরি মাসের ১৩, ১৪ ও ১৫ তারিখ রোজা রাখা সুন্নাত। রাসূলুল্লাহ (সা.) সর্বদা এ রোজা রাখতেন।',
          isFastingRecommended: true,
          isAyyamBeed: true,
        ),
      );
    }

    return list;
  }

  /// All events falling on the Gregorian [date], including events whose Hijri
  /// day varies by year (Akhiri Chahar Shomba = last Wednesday of Safar).
  List<IslamicEvent> getEventsForDate(DateTime date, int offsetDays) {
    final hijri = hijriForDate(date, offsetDays);
    final list = getEventsForHijriDate(hijri.hMonth, hijri.hDay);
    if (isAkhiriChaharShomba(date, offsetDays)) {
      list.add(
        IslamicEvent(
          hijriMonth: 2,
          hijriDay: hijri.hDay,
          titleBn: akhiriChaharShombaTitleBn,
          titleEn: 'Akhiri Chahar Shomba',
          descriptionBn:
              'সফর মাসের শেষ বুধবার। রাসূলুল্লাহ (সা.)-এর সাময়িক রোগমুক্তির স্মরণে শোকরানা আমল।',
        ),
      );
    }
    return list;
  }
}
