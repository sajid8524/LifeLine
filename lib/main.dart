import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/providers/app_providers.dart';
import 'core/themes/app_theme.dart';
import 'core/utils/emergency_formatters.dart';
import 'models/emergency_message.dart';
import 'screens/create_sos_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/map_screen.dart';
import 'screens/message_detail_screen.dart';
import 'screens/rescue_node_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sos_preview_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/sync_status_screen.dart';

void main() {
  runApp(const ProviderScope(child: LifeSaverDtnApp()));
}

final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

class LifeSaverDtnApp extends ConsumerWidget {
  const LifeSaverDtnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(
      appControllerProvider.select((controller) => controller.incomingAlertSerial),
      (previous, next) {
        if (next == 0 || next == previous) {
          return;
        }
        final message = ref.read(appControllerProvider).latestIncomingAlert;
        if (message == null) {
          return;
        }
        _messengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: priorityColor(message.priority),
              duration: const Duration(seconds: 8),
              content: Text(
                'New ${message.priority} SOS: ${readableEmergencyType(message.type)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              action: SnackBarAction(
                label: 'OPEN',
                textColor: Colors.white,
                onPressed: () {
                  _navigatorKey.currentState?.pushNamed(
                    MessageDetailScreen.routeName,
                    arguments: message,
                  );
                },
              ),
            ),
          );
      },
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      navigatorKey: _navigatorKey,
      title: AppConstants.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        CreateSosScreen.routeName: (_) => const CreateSosScreen(),
        InboxScreen.routeName: (_) => const InboxScreen(),
        RescueNodeScreen.routeName: (_) => const RescueNodeScreen(),
        SyncStatusScreen.routeName: (_) => const SyncStatusScreen(),
        MapScreen.routeName: (_) => const MapScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == SosPreviewScreen.routeName) {
          final message = settings.arguments! as EmergencyMessage;
          return MaterialPageRoute(builder: (_) => SosPreviewScreen(message: message));
        }
        if (settings.name == MessageDetailScreen.routeName) {
          final message = settings.arguments! as EmergencyMessage;
          return MaterialPageRoute(builder: (_) => MessageDetailScreen(message: message));
        }
        return null;
      },
    );
  }
}
