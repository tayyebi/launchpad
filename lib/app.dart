import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'ui/launchpad/launchpad_screen.dart';

class LaunchpadApp extends StatelessWidget {
  const LaunchpadApp({super.key});

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
