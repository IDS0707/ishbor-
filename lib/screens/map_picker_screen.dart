import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/app_locale.dart';
import '../core/app_theme.dart';
import '../core/l10n.dart';

/// Center coordinates for each Uzbekistan region / city.
const Map<String, LatLng> kRegionCenters = {
  'reg_tashkent_city': LatLng(41.2995, 69.2401),
  'reg_tashkent': LatLng(41.1173, 69.9857),
  'reg_samarkand': LatLng(39.6542, 66.9597),
  'reg_fergana': LatLng(40.3834, 71.7872),
  'reg_andijan': LatLng(40.7821, 72.3442),
  'reg_namangan': LatLng(41.0011, 71.6672),
  'reg_bukhara': LatLng(39.7684, 64.4556),
  'reg_khorezm': LatLng(41.5529, 60.6322),
  'reg_kashkadarya': LatLng(38.8588, 65.7900),
  'reg_surkhandarya': LatLng(37.9299, 67.5666),
  'reg_syrdarya': LatLng(40.8446, 68.6657),
  'reg_jizzakh': LatLng(40.1219, 67.8421),
  'reg_navoi': LatLng(40.0842, 65.3791),
  'reg_karakalpakstan': LatLng(43.7671, 59.3995),
};

/// Full-screen map picker using OpenStreetMap tiles.
///
/// - [regionCode]  when set and no pre-existing lat/lng, the map opens
///                 centred on that region automatically.
/// - Includes a "My Location" button that moves the map to the device's
///   current GPS position.
/// Returns a [LatLng] when the user confirms, or null if cancelled.
/// The user drags the map; a fixed center pin shows the selected location.
class MapPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String? regionCode;

  const MapPickerScreen({
    this.initialLat = 0.0,
    this.initialLng = 0.0,
    this.regionCode,
    super.key,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late final MapController _mapCtrl;
  late LatLng _center;
  bool _locating = false;

  String _t(String k) => L10n.t(k, appLocale.value);

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
    // Priority: explicit lat/lng > selected region center > Tashkent
    if (widget.initialLat != 0.0 || widget.initialLng != 0.0) {
      _center = LatLng(widget.initialLat, widget.initialLng);
    } else if (widget.regionCode != null &&
        kRegionCenters.containsKey(widget.regionCode)) {
      _center = kRegionCenters[widget.regionCode]!;
    } else {
      _center = const LatLng(41.2995, 69.2401);
    }
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  // ── Go to current GPS position ─────────────────────────────────────────
  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack(_t('location_disabled'));
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _snack(_t('location_denied'));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _snack(_t('location_denied_forever'));
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final loc = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() => _center = loc);
        _mapCtrl.move(loc, 16);
      }
    } catch (e) {
      _snack('${_t("error")}: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appThemeMode.value == ThemeMode.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final surfaceBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfaceBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('pick_on_map'),
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) setState(() => _center = camera.center);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'job_finder_app',
              ),
            ],
          ),

          // ── Fixed centre pin ──────────────────────────────────────────
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFEF4444).withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Colors.white, size: 28),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 46),
                ],
              ),
            ),
          ),

          // ── Hint banner ───────────────────────────────────────────────
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  _t('map_hint'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // ── My-location FAB ───────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 112,
            child: FloatingActionButton(
              heroTag: 'myLocation',
              backgroundColor: surfaceBg,
              elevation: 4,
              onPressed: _locating ? null : _goToMyLocation,
              tooltip: _t('my_location'),
              child: _locating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF2563EB),
                      ),
                    )
                  : const Icon(Icons.my_location_rounded,
                      color: Color(0xFF2563EB), size: 26),
            ),
          ),

          // ── Confirm button ────────────────────────────────────────────
          Positioned(
            bottom: 28,
            left: 24,
            right: 24,
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, _center),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 22),
                label: Text(
                  _t('confirm_location'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
