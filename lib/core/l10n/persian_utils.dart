import 'package:flutter/material.dart';

class PersianUtils {
  static const String _digits = '۰۱۲۳۴۵۶۷۸۹';

  static String toPersianDigits(int n) {
    return n.toString().split('').map((c) => _digits[c.codeUnitAt(0) - 48]).join('');
  }

  static String convertDigits(String s) {
    return String.fromCharCodes(s.runes.map((r) {
      if (r >= 48 && r <= 57) return _digits.codeUnitAt(r - 48);
      return r;
    }));
  }

  static String padLeftWithPersian(int n, int width) {
    final s = toPersianDigits(n);
    if (s.length >= width) return s;
    return '۰' * (width - s.length) + s;
  }

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${padLeftWithPersian(h, 2)}:${padLeftWithPersian(m, 2)}:${padLeftWithPersian(s, 2)}';
    }
    return '${padLeftWithPersian(m, 2)}:${padLeftWithPersian(s, 2)}';
  }

  static String formatDurationSeconds(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${toPersianDigits(h)}:${padLeftWithPersian(m, 2)}:${padLeftWithPersian(s, 2)}';
    return '${padLeftWithPersian(m, 2)}:${padLeftWithPersian(s, 2)}';
  }

  static String formatDurationWords(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${toPersianDigits(h)} ساعت ${toPersianDigits(m)} دقیقه';
    if (m > 0) return '${toPersianDigits(m)} دقیقه ${toPersianDigits(s)} ثانیه';
    return '${toPersianDigits(s)} ثانیه';
  }

  static String formatDurationHHMM(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${padLeftWithPersian(h, 2)}:${padLeftWithPersian(m, 2)}';
  }

  static const List<String> monthNames = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  static const List<String> dayNames = [
    'شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه',
  ];

  static List<int> _toJalali(int gy, int gm, int gd) {
    final gDaysInMonth = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    int jy;
    if (gy > 1600) {
      jy = 979;
      gy -= 1600;
    } else {
      jy = 0;
      gy -= 621;
    }
    int gy2 = (gm > 2) ? (gy + 1) : gy;
    int days = (365 * gy) + ((gy2 + 3) ~/ 4) - ((gy2 + 99) ~/ 100) + ((gy2 + 399) ~/ 400) - 79 + gd + gDaysInMonth[gm - 1];
    jy += 33 * (days ~/ 12053);
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    int jm, jd;
    if (days < 186) {
      jm = 1 + (days ~/ 31);
      jd = 1 + (days % 31);
    } else {
      jm = 7 + ((days - 186) ~/ 30);
      jd = 1 + ((days - 186) % 30);
    }
    return [jy, jm, jd];
  }

  static String formatDate(DateTime date) {
    final j = _toJalali(date.year, date.month, date.day);
    return '${toPersianDigits(j[2])} ${monthNames[j[1] - 1]} ${toPersianDigits(j[0])}';
  }

  static String formatDateWithDay(DateTime date) {
    final weekday = (date.weekday + 1) % 7;
    final j = _toJalali(date.year, date.month, date.day);
    return '${dayNames[weekday]}، ${toPersianDigits(j[2])} ${monthNames[j[1] - 1]} ${toPersianDigits(j[0])}';
  }

  static String formatTime(DateTime date) {
    return '${padLeftWithPersian(date.hour, 2)}:${padLeftWithPersian(date.minute, 2)}';
  }
}
