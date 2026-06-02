import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gestion_salud/firebase_options.dart';
import 'package:gestion_salud/ui/login.dart';
import 'package:gestion_salud/ui/main_screen.dart';
import 'package:gestion_salud/services/storage_service.dart';
import 'package:gestion_salud/core/theme/app_theme.dart';
import 'providers.dart';
import 'controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientacion preferida
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Inicializar datos de locale para que DateFormat('es_ES') funcione
  await initializeDateFormatting('es_ES', null);

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiero Salud',
      theme: AppColors.lightTheme,
      darkTheme: AppColors.darkTheme,
      themeMode: ThemeMode.system,
      home: const RootRoute(),
    );
  }
}

class RootRoute extends ConsumerStatefulWidget {
  const RootRoute({super.key});

  @override
  ConsumerState<RootRoute> createState() => _RootRouteState();
}

class _RootRouteState extends ConsumerState<RootRoute>
    with WidgetsBindingObserver {
  bool _splashListo = false;
  // null = verificando, true = concedido, false = denegado
  bool? _gpsGranted;
  StreamSubscription<bool>? _serviceStatusSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _splashListo = true);
    });
    _verificarGps();
    _serviceStatusSub = GpsService().streamServicioHabilitado().listen((habilitado) {
      if (!habilitado && _gpsGranted == true) {
        if (mounted) setState(() => _gpsGranted = false);
      } else if (habilitado && _gpsGranted == false) {
        _reintentarGps();
      }
    });
  }

  @override
  void dispose() {
    _serviceStatusSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reintentarGps();
    }
  }

  Future<void> _verificarGps() async {
    final granted = await GpsService().solicitarPermisos();
    if (mounted) setState(() => _gpsGranted = granted);
  }

  void _reintentarGps() {
    setState(() => _gpsGranted = null);
    _verificarGps();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if ((prev?.autenticado ?? false) && !next.autenticado && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    if (!_splashListo || authState.cargando || _gpsGranted == null) {
      return const _SplashScreen();
    }

    if (_gpsGranted == false) {
      return _GpsRequiredScreen(onRetry: _reintentarGps);
    }

    if (authState.autenticado) {
      return const MainScreen();
    }

    return const Scaffold(body: Login());
  }
}

class _GpsRequiredScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const _GpsRequiredScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.coral.withAlpha(25),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.location_off_outlined,
                  size: 36,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ubicación requerida',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.01,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Esta aplicación necesita acceso a tu ubicación para registrar ventas y gestionar cobros. Activa el GPS y otorga el permiso para continuar.',
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Verificar de nuevo'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => GpsService().abrirConfiguracionUbicacion(),
                  child: const Text('Activar GPS'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => GpsService().abrirConfiguracionApp(),
                  child: const Text('Abrir ajustes de la app'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Splash screen ────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.brandGradStart, AppColors.brandGradEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative concentric rings
            for (int i = 1; i <= 4; i++)
              Center(
                child: Container(
                  width: 220.0 * i,
                  height: 220.0 * i,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(30),
                      width: 1,
                    ),
                  ),
                ),
              ),

            Positioned.fill(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  const Spacer(),

                  // Logo card
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2E000000),
                          blurRadius: 60,
                          offset: Offset(0, 28),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.brandGradStart,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Wordmark
                  const Text(
                    'quiero',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      height: 1,
                      letterSpacing: -0.02,
                    ),
                  ),
                  const Text(
                    'SALUD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.24,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'TU APP DE BIENESTAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.12,
                    ),
                  ),

                  const SizedBox(height: 56),

                  // Loader bar
                  const _AnimatedLoader(),
                  const SizedBox(height: 14),
                  Text(
                    'cargando datos…',
                    style: TextStyle(
                      color: Colors.white.withAlpha(179),
                      fontSize: 11,
                      letterSpacing: 0.06,
                    ),
                  ),

                  const Spacer(),

                  // Footer
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Text(
                      'v1.2.0 · gestión farmacéutica',
                      style: TextStyle(
                        color: Colors.white.withAlpha(166),
                        fontSize: 11,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedLoader extends StatefulWidget {
  const _AnimatedLoader();

  @override
  State<_AnimatedLoader> createState() => _AnimatedLoaderState();
}

class _AnimatedLoaderState extends State<_AnimatedLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _anim = Tween<double>(begin: -0.5, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 3,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, _) => CustomPaint(
          painter: _LoaderPainter(_anim.value),
        ),
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double progress;
  _LoaderPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = Colors.white.withAlpha(51)
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(99),
    );
    canvas.drawRRect(rrect, trackPaint);

    final thumbW = size.width * 0.4;
    final left = (progress * size.width).clamp(-thumbW, size.width);
    final thumbPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final thumbRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, 0, thumbW, size.height),
      const Radius.circular(99),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRRect(thumbRect, thumbPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LoaderPainter old) => old.progress != progress;
}
