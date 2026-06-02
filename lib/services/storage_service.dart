// lib/services/storage_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Subir foto de tarjeta
  Future<String> subirFotoTarjeta({
    required File foto,
    required String tarjetaId,
  }) async {
    final ref = _storage.ref().child('tarjetas/$tarjetaId/foto.jpg');
    final uploadTask = await ref.putFile(
      foto,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  // Subir foto de cobro (comprobante de pago)
  Future<String> subirFotoCobro({
    required File foto,
    required String tarjetaId,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('cobros/$tarjetaId/$ts.jpg');
    final uploadTask = await ref.putFile(
      foto,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  // Eliminar foto
  Future<void> eliminarFoto(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}

// ─── GPS ──────────────────────────────────────────────────────────────────────
class GpsService {
  // Solicitar permisos de ubicación (llamar al iniciar la app)
  Future<bool> solicitarPermisos() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Ubicación deshabilitada, retornar false
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Solicitar permiso
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    // Retornar true si se tiene el permiso
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> abrirConfiguracionApp() async {
    await Geolocator.openAppSettings();
  }

  // Verificar si la ubicación está habilitada
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Obtener ubicación (usado al crear venta)
  Future<Position?> obtenerUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  // Abrir configuración de ubicación del dispositivo
  Future<void> abrirConfiguracionUbicacion() async {
    await Geolocator.openLocationSettings();
  }

  // Stream que emite true/false cuando el servicio de ubicación cambia
  Stream<bool> streamServicioHabilitado() {
    return Geolocator.getServiceStatusStream()
        .map((s) => s == ServiceStatus.enabled);
  }
}
