import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../constants.dart';
import '../services/api_service.dart';

class AbsenScreen extends StatefulWidget {
  final String email;
  final String action;

  const AbsenScreen({
    super.key,
    required this.email,
    required this.action,
  });

  @override
  State<AbsenScreen> createState() => _AbsenScreenState();
}

class _AbsenScreenState extends State<AbsenScreen> {
  final MapController _mapController = MapController();
  double? _lat;
  double? _lng;
  bool _gpsReady = false;
  bool _loading = true;
  bool _submitting = false;
  String _statusText = 'Mendeteksi lokasi...';
  bool _dalamRadius = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() {
      _loading = true;
      _statusText = 'Memeriksa layanan lokasi...';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusText = kIsWeb
              ? 'Aktifkan lokasi di browser / sistem Anda.'
              : 'Aktifkan GPS terlebih dahulu.';
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        setState(() => _statusText = 'Meminta izin lokasi...');
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _statusText = kIsWeb
              ? 'Izin lokasi ditolak. Klik ikon gembok di address bar browser lalu izinkan lokasi.'
              : 'Izin lokasi ditolak.';
          _loading = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _statusText = kIsWeb
              ? 'Izin lokasi diblokir. Buka pengaturan situs di browser dan izinkan lokasi.'
              : 'Izin lokasi ditolak permanen. Buka pengaturan aplikasi.';
          _loading = false;
        });
        return;
      }

      setState(() => _statusText = 'Mengambil lokasi GPS...');

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      final jarak = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        AppConstants.latKantor,
        AppConstants.lngKantor,
      );

      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _gpsReady = true;
        _dalamRadius = jarak <= AppConstants.radiusMaksimal;
        _statusText = _dalamRadius
            ? 'Jarak dari kantor: ${jarak.round()} meter'
            : 'Jarak: ${jarak.round()} meter (Terlalu jauh!)';
        _loading = false;
      });

      _mapController.move(
        LatLng(
          (_lat! + AppConstants.latKantor) / 2,
          (_lng! + AppConstants.lngKantor) / 2,
        ),
        16,
      );
    } catch (e) {
      setState(() {
        _statusText = kIsWeb
            ? 'Gagal mengambil lokasi. Pastikan:\n• Situs diakses via HTTPS\n• Izin lokasi diizinkan di browser'
            : 'Gagal mengambil lokasi: $e';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_gpsReady || _lat == null || _lng == null || !_dalamRadius) return;

    setState(() => _submitting = true);
    try {
      final res = await ApiService.simpanAbsenNormal(
        email: widget.email,
        status: widget.action,
        lat: _lat!,
        lng: _lng!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Selesai')),
      );

      if (res['success'] == true) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClockOut = widget.action == 'Clock Out';

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    widget.action,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(
                      AppConstants.latKantor,
                      AppConstants.lngKantor,
                    ),
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.sistem_absensi',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: const LatLng(
                            AppConstants.latKantor,
                            AppConstants.lngKantor,
                          ),
                          radius: AppConstants.radiusMaksimal,
                          useRadiusInMeter: true,
                          color: const Color(0xFF3B82F6).withOpacity(0.18),
                          borderColor: const Color(0xFF2563EB),
                          borderStrokeWidth: 3,
                        ),
                      ],
                    ),
                    const MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            AppConstants.latKantor,
                            AppConstants.lngKantor,
                          ),
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_on,
                            color: Color(0xFF2563EB),
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                    if (_lat != null && _lng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_lat!, _lng!),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Color(0xFFDC2626),
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_loading)
                  Container(
                    color: Colors.white.withOpacity(0.9),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _statusText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: !_gpsReady
                        ? const Color(0xFF64748B)
                        : _dalamRadius
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_gpsReady && _dalamRadius && !_submitting)
                        ? _submit
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isClockOut
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF2563EB),
                      disabledBackgroundColor: const Color(0xFF94A3B8),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text('SUBMIT ${widget.action.toUpperCase()}'),
                  ),
                ),
                if (kIsWeb && !_gpsReady && !_loading) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _initLocation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Ambil Lokasi Lagi'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
