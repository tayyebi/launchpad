import 'persian_utils.dart';

export 'persian_utils.dart';

class Strings {
  /// Keep in sync with `version:` in pubspec.yaml and `versionName` in
  /// android/app/build.gradle. Sent along with feedback so a report can be
  /// tied to the build it came from.
  static const String appVersion = '1.6.2';

  static const String summary = 'خلاصه';
  static const String settings = 'تنظیمات';
  static const String noTasksYet = 'هنوز کاری اضافه نشده';
  static const String error = 'خطا';

  static const String configureTask = 'تنظیمات وظیفه';
  static const String taskName = 'نام وظیفه';
  static const String delete = 'حذف';
  static const String cancel = 'انصراف';
  static const String save = 'ذخیره';
  static const String deleteTask = 'حذف وظیفه';
  static String deleteTaskConfirm(String name) => 'آیا «$name» حذف شود؟';
  static const String cannotDeleteRunningTask = 'نمی‌توان وظیفهٔ در حال اجرا را حذف کرد. ابتدا آن را متوقف کنید.';

  static const String gridSize = 'اندازه شبکه';
  static String slotsCount(int n) => 'تعداد ${PersianUtils.toPersianDigits(n)} خانه';
  static const String tasks = 'وظایف';
  static const String add = 'افزودن';
  static const String noTasks = 'وظیفه‌ای وجود ندارد';
  static const String active = 'فعال';
  static const String viewLogs = 'بارگیری گزارش‌ها';
  static const String multitasking = 'چندوظیفگی';
  static String multitaskingDesc(int n) =>
      'اجازهٔ ${PersianUtils.toPersianDigits(n)} وظیفه همزمان';
  static const String newTask = 'وظیفه جدید';

  static const String logs = 'گزارش‌ها';
  static const String exportCsv = 'خروجی CSV';
  static const String noEntriesYet = 'هنوز موردی ثبت نشده';
  static const String today = 'امروز';
  static const String running = 'در حال اجرا';
  static const String noEntriesToExport = 'موردی برای خروجی وجود ندارد';
  static const String exportTitle = 'خروجی گزارش‌ها';
  static const String saveToDevice = 'ذخیره در دستگاه';
  static const String shareFile = 'اشتراک‌گذاری';
  static const String fileSaved = 'فایل ذخیره شد';
  static const String exportSubject = 'گزارش‌های Launchpad';

  static const String weekOf = 'هفتهٔ';
  static const String noDataForPeriod = 'داده‌ای برای این دوره وجود ندارد';
  static const String timePerTask = 'زمان هر وظیفه';
  static const String logsTitle = 'گزارش‌ها';
  static const String noEntriesForPeriod = 'موردی برای این دوره وجود ندارد';
  static const String deleteEntry = 'حذف مورد';
  static String deleteEntryConfirm(String name) => 'آیا این مورد برای «$name» حذف شود؟';
  static const String unknown = 'ناشناخته';

  static const String feedback = 'ارسال بازخورد';
  static const String feedbackSubtitle = 'پیامک به توسعه‌دهنده';
  static const String feedbackNumber = '+989388063351';
  static const String feedbackBody =
      'سلام،\nبازخورد من دربارهٔ لانچ‌پد (نسخهٔ $appVersion):\n\n';
  static const String feedbackFailed =
      'برنامهٔ پیامک باز نشد. شماره: $feedbackNumber';

  static const String timerChannelName = 'زمان‌سنج';
  static const String timerRunning = 'در حال اجرا';
  static String timerAlsoRunning(String names) => 'همچنین: $names';

  static String syncedEntries(int n) => '${PersianUtils.toPersianDigits(n)} مورد همگام‌سازی شد';
  static String syncFailed(String e) => 'همگام‌سازی ناموفق: $e';

  static const List<String> defaultTasks = [
    'کار',
    'استراحت',
    'مطالعه',
    'ورزش',
    'کتابخوانی',
    'موسیقی',
    'بازی',
    'اجتماعی',
    'آشپزی',
    'خانه‌داری',
  ];
}
