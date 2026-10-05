import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:trabajoya_app/app/app.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  const env = String.fromEnvironment('ENV', defaultValue: 'development');
  await dotenv.load(fileName: '.env.$env');

  await apiClient.init();

  final authProvider = AuthProvider();
  await authProvider.checkAuth();

  final sentryDsn = dotenv.env['SENTRY_DSN'];

  if (sentryDsn != null && sentryDsn.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.tracesSampleRate = 1.0;
      options.environment = env;
    }, appRunner: () => runApp(TrabajoYaApp(authProvider: authProvider)));
  } else {
    runApp(TrabajoYaApp(authProvider: authProvider));
  }
}
