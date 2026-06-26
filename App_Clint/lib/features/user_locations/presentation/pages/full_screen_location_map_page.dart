import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/device_location_helper.dart';
import '../../../../core/widgets/common/app_back_button.dart';

class FullScreenLocationMapPage extends StatefulWidget {
  const FullScreenLocationMapPage({
    super.key,
    required this.initialPin,
    this.initialUserLocation,
  });

  final LatLng initialPin;
  final LatLng? initialUserLocation;

  @override
  State<FullScreenLocationMapPage> createState() =>
      _FullScreenLocationMapPageState();
}

class _FullScreenLocationMapPageState extends State<FullScreenLocationMapPage> {
  late LatLng _pin;
  LatLng? _userLocation;
  final MapController _mapController = MapController();
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _pin = widget.initialPin;
    _userLocation = widget.initialUserLocation;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    final l10n = L10n.of(context);
    final result = await DeviceLocationHelper.getCurrentLatLng();
    if (!mounted) return;
    setState(() => _locating = false);

    if (result.position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.translate(result.errorKey ?? 'locationUnavailable') ??
                'Location unavailable',
          ),
        ),
      );
      return;
    }

    setState(() => _userLocation = result.position);
    _mapController.move(result.position!, 15);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: AppBackButton.appBarLeading(
          context,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n?.translate('pickLocationOnMap') ?? 'Pick location on map',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_pin),
            child: Text(l10n?.translate('done') ?? 'Done'),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pin,
              initialZoom: 14,
              onTap: (_, point) => setState(() => _pin = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bareq.sitt_app',
              ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 48,
                      ),
                    ),
                  Marker(
                    point: _pin,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.location_pin,
                      color: AppColors.primary,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ],
          ),
          PositionedDirectional(
            bottom: 96,
            end: 16,
            child: FloatingActionButton(
              heroTag: 'fullscreen_my_location',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              onPressed: _locating ? null : _goToMyLocation,
              child:
                  _locating
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.my_location),
            ),
          ),
          PositionedDirectional(
            start: 16,
            end: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    l10n?.translate('tapMapToSetPin') ??
                        'Tap the map to set the pin location',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
