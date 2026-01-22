import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';
import '../features/auth/presentation/widgets/lock_screen.dart';

class POSMeApp extends ConsumerWidget {
  const POSMeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'POS ME',
      debugShowCheckedModeBanner: false,
      theme: POSTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        return LockScreenWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
