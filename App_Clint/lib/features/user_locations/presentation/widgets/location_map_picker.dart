import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/device_location_helper.dart';
import '../pages/full_screen_location_map_page.dart';

/// Default center: Tripoli, Libya.
const LatLng kDefaultMapCenter = LatLng(32.8872, 13.1913);

class LocationMapPicker extends StatefulWidget {
  const LocationMapPicker({
    super.key,
    required this.center,
    required this.onPositionChanged,
    this.height = 220,
    this.enableFullscreen = true,
  });

  final LatLng center;
  final ValueChanged<LatLng> onPositionChanged;
  final double height;
  final bool enableFullscreen;

  @override
  State<LocationMapPicker> createState() => _LocationMapPickerState();
}

class _LocationMapPickerState extends State<LocationMapPicker> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  bool _locating = false;

  @override
  void didUpdateWidget(covariant LocationMapPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.center != widget.center) {
      _mapController.move(widget.center, _mapController.camera.zoom);
    }
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
      final key = result.errorKey ?? 'locationUnavailable';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.translate(key) ?? key)),
      );
      return;
    }

    setState(() => _userLocation = result.position);
    _mapController.move(result.position!, 15);
  }

  Future<void> _openFullscreen() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (_) => FullScreenLocationMapPage(
              initialPin: widget.center,
              initialUserLocation: _userLocation,
            ),
      ),
    );
    if (result != null && mounted) {
      widget.onPositionChanged(result);
      _mapController.move(result, _mapController.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.center,
                initialZoom: 13,
                onTap: (_, point) => widget.onPositionChanged(point),
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
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.blue,
                          size: 44,
                        ),
                      ),
                    Marker(
                      point: widget.center,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (widget.enableFullscreen)
              PositionedDirectional(
                top: 8,
                end: 8,
                child: _MapOverlayButton(
                  tooltip:
                      l10n?.translate('openMapFullscreen') ??
                      'Open map fullscreen',
                  icon: Icons.fullscreen,
                  onTap: _openFullscreen,
                ),
              ),
            PositionedDirectional(
              bottom: 8,
              end: 8,
              child: _MapOverlayButton(
                tooltip:
                    l10n?.translate('getMyLocation') ?? 'Get my location',
                icon: Icons.my_location,
                onTap: _goToMyLocation,
                isLoading: _locating,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapOverlayButton extends StatelessWidget {
  const _MapOverlayButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 40,
            height: 40,
            child:
                isLoading
                    ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Icon(icon, color: AppColors.textPrimary, size: 22),
          ),
        ),
      ),
    );
  }
}
