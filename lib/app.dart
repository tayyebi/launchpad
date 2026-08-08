import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'core/theme/app_theme.dart';
import 'ui/launchpad/launchpad_screen.dart';

class LaunchpadApp extends StatefulWidget {
  const LaunchpadApp({super.key});

  @override
  State<LaunchpadApp> createState() => _LaunchpadAppState();
}

class _LaunchpadAppState extends State<LaunchpadApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The keep-awake flag lives on the activity window, so it is lost whenever
  // Android recreates the activity. Enabling it once at startup is not enough;
  // re-apply it every time we come back to the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _setWakelock(true);
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _setWakelock(false);
      // `inactive` and `hidden` fire transiently (pulling down the notification
      // shade, app switcher previews) and must not drop the flag.
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _setWakelock(bool enabled) async {
    try {
      await (enabled ? WakelockPlus.enable() : WakelockPlus.disable());
    } catch (_) {
      // A wakelock failure must never take the app down with it.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Launchpad',
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: const LaunchpadScreen(),
      ),
    );
  }
}
