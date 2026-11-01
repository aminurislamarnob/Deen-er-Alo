class BanglaUtils {
  BanglaUtils._();

  static const List<String> _banglaDigits = [
    '০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'
  ];

  static String toBanglaDigits(dynamic number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final codeUnit = str.codeUnitAt(i);
      // Check if it's '0' - '9' (ASCII 48 - 57)
      if (codeUnit >= 48 && codeUnit <= 57) {
        buffer.write(_banglaDigits[codeUnit - 48]);
      } else {
        buffer.write(str[i]);
      }
    }
    return buffer.toString();
  }

  static const Map<int, String> hijriMonthBengali = {
    1: 'মুহররম',
    2: 'সফর',
    3: 'রবিউল আউয়াল',
    4: 'রবিউস সানি',
    5: 'জুমাদাল উলা',
    6: 'জুমাদাস সানি',
    7: 'রজব',
    8: 'শাবান',
    9: 'রমজান',
    10: 'শাওয়াল',
    11: 'জিলকদ',
    12: 'জিলহজ',
  };
}

