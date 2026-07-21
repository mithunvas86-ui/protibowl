import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/supabase_service.dart';
import 'services/local_storage_service.dart';
import 'services/shared_orders_service.dart';
import 'services/guest_customer_tracking_service.dart';
import 'services/service_hours_service.dart';
import 'providers/menu_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/customer_info_provider.dart';
import 'providers/subscription_provider.dart';
import 'theme/bauhaus_theme.dart';
import 'router.dart';

/// User/Customer app entry point
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env file not found on web - expected, using fallback credentials
  }
  await SupabaseService.initialize();
  await LocalStorageService().init();
  await SharedOrdersService().init();
  await GuestCustomerTrackingService().init();
  await ServiceHoursService().load();

  runApp(const MPROTIDiningUserApp());
}

class MPROTIDiningUserApp extends StatelessWidget {
  const MPROTIDiningUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomerInfoProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: MaterialApp.router(
        title: 'Proti Bowls',
        debugShowCheckedModeBanner: false,
        theme: BauhausTheme.theme,
        routerConfig: router,
      ),
    );
  }
}
