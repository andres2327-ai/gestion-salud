// lib/services/storage_service.dart

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> subirFotoTarjeta({
    required XFile foto,
    required String tarjetaId,
  }) async {
    final ref = _storage.ref().child('tarjetas/$tarjetaId/foto.jpg');
    final bytes = await foto.readAsBytes();
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> subirFotoCobro({
    required XFile foto,
    required String tarjetaId,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('cobros/$tarjetaId/$ts.jpg');
    final bytes = await foto.readAsBytes();
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> eliminarFoto(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}

// ─── GPS ──────────────────────────────────────────────────────────────────────
class GpsService {
  Future<bool> solicitarPermisos() async {
    if (kIsWeb) return true;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> abrirConfiguracionApp() async {
    if (kIsWeb) return;
    await Geolocator.openAppSettings();
  }

  Future<bool> isLocationServiceEnabled() async {
    if (kIsWeb) return true;
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<Position?> obtenerUbicacion() async {
    if (kIsWeb) {
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        ).timeout(const Duration(seconds: 6));
      } catch (_) {
        return null;
      }
    }
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 6));
    } catch (_) {
      return null;
    }
  }

  Future<void> abrirConfiguracionUbicacion() async {
    if (kIsWeb) return;
    await Geolocator.openLocationSettings();
  }

  Stream<bool> streamServicioHabilitado() {
    if (kIsWeb) return const Stream.empty();
    return Geolocator.getServiceStatusStream()
        .map((s) => s == ServiceStatus.enabled);
  }
}
