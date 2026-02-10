import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';

// Services
import 'data/services/firebase_service.dart';
import 'data/services/callkit_service.dart';
import 'data/services/storage_service.dart';

// Providers
import 'providers/call_provider.dart';
import 'providers/auth_provider.dart';

// Screens
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/call/call_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);

  final logger = Logger();

  try {
    // 1. Carregar variaveis de ambiente
    logger.i('Loading environment variables...');
    await dotenv.load(fileName: ".env");

    // 2. Inicializar Storage Local
    logger.i('Initializing local storage...');
    await StorageService.init();

    // 3. Inicializar Firebase
    logger.i('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 4. Inicializar Firebase Messaging
    logger.i('Initializing Firebase Messaging...');
    await FirebaseService.initialize();

    // Criar canal de notificacao Android
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel highChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificacoes Importantes',
      description: 'Canal para alertas urgentes da EVA.',
      importance: Importance.max,
    );

    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(highChannel);
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        logger.i('Notification clicked: ${response.payload}');
      },
    );

    // Solicitar permissao de notificacao (Android 13+)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    StorageService.debugPrintData();

    // 5. Criar CallProvider
    logger.i('Creating CallProvider...');
    final callProvider = await CallProvider.create();

    // 6. Configurar callback de chamada recebida
    FirebaseService.onVoiceCallReceived = (sessionId, idosoData) {
      logger.i('BACKEND triggered call! Session: $sessionId');
      callProvider.receiveCall(sessionId, idosoData: idosoData);
    };

    // 7. Iniciar listeners
    logger.i('Starting Firebase Listeners...');
    FirebaseService.startListening();

    logger.i('Starting CallKit Listeners...');
    CallKitService.listenEvents();

    runApp(MyApp(callProvider: callProvider));
  } catch (e, stackTrace) {
    logger.e('Error during initialization: $e');
    logger.e('Stack trace: $stackTrace');
    final fallbackProvider = CallProvider.fallback();
    runApp(MyApp(callProvider: fallbackProvider));
  }
}

class MyApp extends StatefulWidget {
  final CallProvider callProvider;

  const MyApp({super.key, required this.callProvider});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    String initialRoute = StorageService.isLoggedIn() ? '/home' : '/login';
    _router = _createRouter(initialRoute);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: widget.callProvider),
      ],
      child: PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) async {
          if (!didPop) {
            SystemNavigator.pop();
          }
        },
        child: MaterialApp.router(
          title: 'EVA Clean',
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF9F70D8),
            useMaterial3: true,
          ),
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
          ],
        ),
      ),
    );
  }

  GoRouter _createRouter(String initialRoute) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: initialRoute,
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/call',
          name: 'call',
          builder: (context, state) => const CallScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text('Rota nao encontrada: ${state.matchedLocation}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
