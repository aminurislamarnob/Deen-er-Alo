// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  final projectRoot = Directory.current.path;
  final dhakaCsvFile = File('$projectRoot/data/ifb/ifb_dhaka.csv');
  final correctionsFile = File('$projectRoot/data/ifb/corrections.csv');
  final offsetsFile = File('$projectRoot/data/ifb/ifb_district_offsets.csv');
  final citiesFile = File('$projectRoot/assets/data/countries+cities.json');
  final outputFile = File('$projectRoot/assets/data/ifb_times.json');

  if (!dhakaCsvFile.existsSync()) {
    throw Exception('File not found: ${dhakaCsvFile.path}');
  }
  if (!correctionsFile.existsSync()) {
    throw Exception('File not found: ${correctionsFile.path}');
  }
  if (!offsetsFile.existsSync()) {
    throw Exception('File not found: ${offsetsFile.path}');
  }
  if (!citiesFile.existsSync()) {
    throw Exception('File not found: ${citiesFile.path}');
  }

  // 1. Read corrections
  final correctionsLines = correctionsFile.readAsLinesSync();
  final corrections = <String, String>{};
  for (var i = 1; i < correctionsLines.length; i++) {
    final line = correctionsLines[i].trim();
    if (line.isEmpty) continue;
    final parts = line.split(',');
    final m = parts[0];
    final d = parts[1];
    final col = parts[2];
    final corrected = parts[4];
    corrections['$m,$d,$col'] = corrected;
  }

  // 2. Read Dhaka published rows
  final dhakaLines = dhakaCsvFile.readAsLinesSync();
  final rawRows = <Map<String, String>>[];
  // Handle optional UTF-8 BOM on first line
  var headerIndex = 0;
  for (var i = 0; i < dhakaLines.length; i++) {
    if (dhakaLines[i].contains('month') && dhakaLines[i].contains('day')) {
      headerIndex = i;
      break;
    }
  }

  final header = dhakaLines[headerIndex].replaceAll('\uFEFF', '').split(',');
  for (var i = headerIndex + 1; i < dhakaLines.length; i++) {
    final line = dhakaLines[i].trim();
    if (line.isEmpty) continue;
    final parts = line.split(',');
    final row = <String, String>{};
    for (var h = 0; h < header.length; h++) {
      row[header[h]] = parts[h];
    }

    // Apply corrections if applicable
    final m = row['month']!;
    final d = row['day']!;
    for (final col in ['sehri', 'fajr', 'dhuhr', 'asr', 'maghrib_iftar', 'isha', 'sunrise']) {
      final key = '$m,$d,$col';
      if (corrections.containsKey(key)) {
        row[col] = corrections[key]!;
      }
    }
    rawRows.add(row);
  }

  // 3. Build anchor points mapped to day-of-year in leap year 2028
  int parseMinutes(String s, {bool isPm = false}) {
    final parts = s.split(':');
    var h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    if (isPm && h < 12) h += 12;
    return h * 60 + m;
  }

  final anchorPoints = <_Anchor>[];
  for (final row in rawRows) {
    final m = int.parse(row['month']!);
    var d = int.parse(row['day']!);
    if (m == 2 && d == 30) {
      d = 28; // Feb "30" mapped to Feb 28
    }
    final dt = DateTime(2028, m, d);
    final doy = dt.difference(DateTime(2028, 1, 1)).inDays;

    anchorPoints.add(_Anchor(
      doy: doy,
      month: m,
      day: d,
      sehri: parseMinutes(row['sehri']!, isPm: false),
      fajr: parseMinutes(row['fajr']!, isPm: false),
      dhuhr: parseMinutes(row['dhuhr']!, isPm: false),
      asr: parseMinutes(row['asr']!, isPm: true),
      maghrib: parseMinutes(row['maghrib_iftar']!, isPm: true),
      isha: parseMinutes(row['isha']!, isPm: true),
      sunrise: parseMinutes(row['sunrise']!, isPm: false),
    ));
  }

  // Add wrapping anchor for next year Jan 1 (doy 366)
  final jan1 = anchorPoints.first;
  anchorPoints.add(_Anchor(
    doy: 366,
    month: 1,
    day: 1,
    sehri: jan1.sehri,
    fajr: jan1.fajr,
    dhuhr: jan1.dhuhr,
    asr: jan1.asr,
    maghrib: jan1.maghrib,
    isha: jan1.isha,
    sunrise: jan1.sunrise,
  ));

  // 4. Interpolate all 366 days for Dhaka
  final dhakaDaily = <_DailySchedule>[];
  for (var doy = 0; doy < 366; doy++) {
    for (var i = 0; i < anchorPoints.length - 1; i++) {
      final a0 = anchorPoints[i];
      final a1 = anchorPoints[i + 1];
      if (a0.doy <= doy && doy <= a1.doy) {
        final span = a1.doy - a0.doy;
        final frac = span == 0 ? 0.0 : (doy - a0.doy) / span;

        // Sehri: round down (floor)
        final sehriVal = a0.sehri + frac * (a1.sehri - a0.sehri);
        final sehriMin = (sehriVal + 1e-9).floor();

        // Fajr: keep Fajr = Sehri + 6
        final fajrMin = sehriMin + 6;

        // Maghrib: round up (ceil)
        final maghribVal = a0.maghrib + frac * (a1.maghrib - a0.maghrib);
        final maghribMin = (maghribVal - 1e-9).ceil();

        int roundNearest(double v) => (v + 0.5).floor();

        final dhuhrMin = roundNearest(a0.dhuhr + frac * (a1.dhuhr - a0.dhuhr));
        final asrMin = roundNearest(a0.asr + frac * (a1.asr - a0.asr));
        final ishaMin = roundNearest(a0.isha + frac * (a1.isha - a0.isha));
        final sunriseMin = roundNearest(a0.sunrise + frac * (a1.sunrise - a0.sunrise));

        dhakaDaily.add(_DailySchedule(
          doy: doy,
          sehri: sehriMin,
          fajr: fajrMin,
          dhuhr: dhuhrMin,
          asr: asrMin,
          maghrib: maghribMin,
          isha: ishaMin,
          sunrise: sunriseMin,
        ));
        break;
      }
    }
  }

  if (dhakaDaily.length != 366) {
    throw Exception('Expected 366 interpolated days, got ${dhakaDaily.length}');
  }

  // 5. Read city metadata and offsets
  final citiesJson = json.decode(citiesFile.readAsStringSync()) as List<dynamic>;
  final bd = citiesJson.firstWhere((c) => c['nm'] == 'Bangladesh');
  final bdCities = bd['cities'] as List<dynamic>;

  String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  final cityByNorm = <String, Map<String, dynamic>>{};
  for (final c in bdCities) {
    cityByNorm[norm(c['nm'] as String)] = c as Map<String, dynamic>;
  }

  final aliasMap = {
    'bogura': 'bogra',
    'jashore': 'jessore',
    'barishal': 'barisal',
    'netrokona': 'netrakona',
    'jhalokathi': 'jhalokati',
    'chapainawabganj': 'chapainababganj',
  };

  final offsetLines = offsetsFile.readAsLinesSync();
  final districtOffsets = <int, _DistrictOffset>{};

  for (var i = 1; i < offsetLines.length; i++) {
    final line = offsetLines[i].trim();
    if (line.isEmpty) continue;
    final parts = line.split(',');
    final bn = parts[0];
    final en = parts[1];
    final dir = parts[2];
    final sMin = int.parse(parts[3]);
    final iMin = int.parse(parts[4]);

    var k = norm(en);
    k = aliasMap[k] ?? k;
    final c = cityByNorm[k];
    if (c == null) {
      throw Exception('Could not find city for $en (normalized: $k)');
    }
    final cityId = c['id'] as int;
    districtOffsets[cityId] = _DistrictOffset(
      id: cityId,
      nameEn: en,
      nameBn: bn,
      direction: dir,
      sehriMin: sMin,
      iftarMin: iMin,
      isDerived: false,
    );
  }

  // Add Dhaka (8486)
  districtOffsets[8486] = _DistrictOffset(
    id: 8486,
    nameEn: 'Dhaka',
    nameBn: 'ঢাকা',
    direction: '+',
    sehriMin: 0,
    iftarMin: 0,
    isDerived: false,
  );

  // Add Joypurhat (8509) as derived (+7/+7)
  districtOffsets[8509] = _DistrictOffset(
    id: 8509,
    nameEn: 'Joypurhat',
    nameBn: 'জয়পুরহাট',
    direction: '+',
    sehriMin: 7,
    iftarMin: 7,
    isDerived: true,
  );

  if (districtOffsets.length != 64) {
    throw Exception('Expected 64 districts, got ${districtOffsets.length}');
  }

  // 6. Generate output structure
  String formatMinutes(int totalMin, {bool isPm = false}) {
    var h = (totalMin ~/ 60) % 24;
    final m = totalMin % 60;
    if (isPm && h > 12) h -= 12;
    final mStr = m < 10 ? '0$m' : '$m';
    return '$h:$mStr';
  }

  final districtsMap = <String, dynamic>{};
  for (final entry in districtOffsets.entries) {
    final dist = entry.value;
    final mult = dist.direction == '-' ? -1 : 1;
    final sehriList = <String>[];
    final fajrList = <String>[];
    final iftarList = <String>[];

    for (final day in dhakaDaily) {
      final s = day.sehri + mult * dist.sehriMin;
      final f = day.fajr + mult * dist.sehriMin;
      final i = day.maghrib + mult * dist.iftarMin;

      sehriList.add(formatMinutes(s, isPm: false));
      fajrList.add(formatMinutes(f, isPm: false));
      iftarList.add(formatMinutes(i, isPm: true));
    }

    districtsMap[dist.id.toString()] = {
      'sehri': sehriList,
      'fajr': fajrList,
      'iftar': iftarList,
    };
  }

  final dhakaFull = {
    'sunrise': dhakaDaily.map((d) => formatMinutes(d.sunrise, isPm: false)).toList(),
    'dhuhr': dhakaDaily.map((d) => formatMinutes(d.dhuhr, isPm: false)).toList(),
    'asr': dhakaDaily.map((d) => formatMinutes(d.asr, isPm: true)).toList(),
    'isha': dhakaDaily.map((d) => formatMinutes(d.isha, isPm: true)).toList(),
  };

  final outputJson = {
    'version': 2,
    'source': 'Islamic Foundation Bangladesh permanent timetable',
    'districts': districtsMap,
    'dhaka_full': dhakaFull,
    'derived': ['8509'],
  };

  outputFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(outputJson));
  print('Successfully wrote: ${outputFile.path}');
  print('Total districts: ${districtsMap.length}');
  print('Total days per district: 366');
}

class _Anchor {
  final int doy;
  final int month;
  final int day;
  final int sehri;
  final int fajr;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;
  final int sunrise;

  const _Anchor({
    required this.doy,
    required this.month,
    required this.day,
    required this.sehri,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.sunrise,
  });
}

class _DailySchedule {
  final int doy;
  final int sehri;
  final int fajr;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;
  final int sunrise;

  const _DailySchedule({
    required this.doy,
    required this.sehri,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.sunrise,
  });
}

class _DistrictOffset {
  final int id;
  final String nameEn;
  final String nameBn;
  final String direction;
  final int sehriMin;
  final int iftarMin;
  final bool isDerived;

  const _DistrictOffset({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.direction,
    required this.sehriMin,
    required this.iftarMin,
    required this.isDerived,
  });
}
