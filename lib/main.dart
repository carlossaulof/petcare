import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/app_data.dart';
import 'data/data_source.dart';
import 'services/integrations.dart';
import 'state/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Troque as implementações abaixo ao conectar serviços reais (ver README).
  final data = AppData(
    dataSource: SharedPrefsDataSource(),
    paymentGateway: const UnconfiguredPaymentGateway(),
    pushGateway: const InAppOnlyPushGateway(),
    emailGateway: const UnconfiguredEmailGateway(),
  );
  await data.load();

  final auth = AuthController(data);
  await auth.restore();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: data),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: const PetCareApp(),
    ),
  );
}
