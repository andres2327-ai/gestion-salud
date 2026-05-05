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

class _LocationPermissionWrapperState extends State<LocationPermissionWrapper> {
  bool _hasCheckedPermissions = false;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _solicitarPermisos();
  }

  Future<void> _solicitarPermisos() async {
    if (_hasCheckedPermissions) return;

    final gpsService = GpsService();
    final serviceEnabled = await gpsService.isLocationServiceEnabled();

    if (!mounted) return;

    if (!serviceEnabled) {
      _mostrarDialogoUbicacion();
      setState(() {
        _hasCheckedPermissions = true;
        _permissionGranted = false;
      });
      return;
    }

    final granted = await gpsService.solicitarPermisos();

    if (!mounted) return;

    if (!granted) {
      _mostrarDialogoPermisoRequerido();
    }

    setState(() {
      _hasCheckedPermissions = true;
      _permissionGranted = granted;
    });
  }

  void _mostrarDialogoUbicacion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ubicación Requerida'),
        content: const Text(
          'Para usar la función de rutas, necesitamos acceso a tu ubicación. '
          'Por favor, habilita la ubicación en la configuración de tu dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ahora No'),
          ),
          ElevatedButton(
            onPressed: () async {
              final gpsService = GpsService();
              await gpsService.abrirConfiguracionUbicacion();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoPermisoRequerido() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permiso de ubicación necesario'),
        content: const Text(
          'La aplicación necesita permiso de ubicación para funcionar correctamente. '
          'Por favor concede el permiso y reinicia la aplicación si es necesario.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final gpsService = GpsService();
              await gpsService.abrirConfiguracionApp();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedPermissions) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_permissionGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Permisos de ubicación')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'La aplicación necesita permiso de ubicación para continuar.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _solicitarPermisos,
                child: const Text('Solicitar permisos nuevamente'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final gpsService = GpsService();
                  await gpsService.abrirConfiguracionApp();
                },
                child: const Text('Abrir ajustes de la aplicación'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
