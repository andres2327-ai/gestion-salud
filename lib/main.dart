import 'package:firebase_auth/firebase_auth.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientacion preferida
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Cerrar sesión al iniciar la app para que no permanezca iniciada de forma permanente
  await FirebaseAuth.instance.signOut();

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

class _RootRouteState extends ConsumerState<RootRoute> {
  // Splash mínimo de 2 segundos al arrancar la app
  bool _splashListo = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _splashListo = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Mostrar splash:
    // 1) Durante los primeros 2 s de arranque
    // 2) Mientras se procesa cualquier autenticación (login/verificación de perfil)
    if (!_splashListo || authState.cargando) {
      return const _SplashScreen();
    }

    if (authState.autenticado) {
      return const LocationPermissionWrapper(child: MainScreen());
    }

    return const Scaffold(body: Login());
  }
}

// ─── Splash screen ────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A5C6B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 140,
            ),
            const SizedBox(height: 20),
            const Text(
              'QUIERO SALUD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'TU APP DE BIENESTAR',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget para solicitar permisos de ubicación ──────────────────────────────
class LocationPermissionWrapper extends StatefulWidget {
  final Widget child;

  const LocationPermissionWrapper({super.key, required this.child});

  @override
  State<LocationPermissionWrapper> createState() =>
      _LocationPermissionWrapperState();
}

class _LocationPermissionWrapperState extends State<LocationPermissionWrapper>
    with WidgetsBindingObserver {
  // null = still checking, false = denied, true = granted
  bool? _permissionGranted;
  bool _verificando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _solicitarPermisos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check automatically when the app returns from background (e.g., after
  // the user enables GPS or grants permission in system settings).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _permissionGranted != true) {
      _solicitarPermisos();
    }
  }

  Future<void> _solicitarPermisos() async {
    if (_verificando) return;
    setState(() => _verificando = true);

    final gpsService = GpsService();

    final serviceEnabled = await gpsService.isLocationServiceEnabled();
    if (!mounted) return;

    if (!serviceEnabled) {
      setState(() {
        _permissionGranted = false;
        _verificando = false;
      });
      _mostrarDialogoGpsApagado();
      return;
    }

    final granted = await gpsService.solicitarPermisos();
    if (!mounted) return;

    setState(() {
      _permissionGranted = granted;
      _verificando = false;
    });

    if (!granted) {
      _mostrarDialogoPermisoRequerido();
    }
  }

  void _mostrarDialogoGpsApagado() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('GPS apagado'),
        content: const Text(
          'Para usar la función de rutas necesitamos acceso a tu ubicación. '
          'Activa el GPS en la configuración de tu dispositivo y regresa a la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ahora No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await GpsService().abrirConfiguracionUbicacion();
              // didChangeAppLifecycleState will re-check when the user returns
            },
            child: const Text('Activar GPS'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoPermisoRequerido() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Permiso de ubicación'),
        content: const Text(
          'La aplicación necesita permiso de ubicación para registrar ventas '
          'y calcular rutas. Otorga el permiso en ajustes y regresa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await GpsService().abrirConfiguracionApp();
            },
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Still checking
    if (_permissionGranted == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Granted → show the real app
    if (_permissionGranted == true) {
      return widget.child;
    }

    // Denied → show fallback screen with retry
    return Scaffold(
      appBar: AppBar(title: const Text('Permisos de ubicación')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.location_off_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'La aplicación necesita acceso a tu ubicación para funcionar correctamente.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Si acabas de activar el GPS o dar el permiso, toca "Verificar de nuevo".',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _verificando ? null : _solicitarPermisos,
              icon: _verificando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Verificar de nuevo'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await GpsService().abrirConfiguracionUbicacion();
              },
              icon: const Icon(Icons.gps_fixed),
              label: const Text('Activar GPS'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await GpsService().abrirConfiguracionApp();
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Abrir ajustes de la app'),
            ),
          ],
        ),
      ),
    );
  }
}
