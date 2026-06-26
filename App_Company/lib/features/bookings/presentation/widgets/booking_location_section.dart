import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/maps_launcher.dart';
import '../../domain/entities/booking_entity.dart';

/// Customer location on a booking (read-only; company cannot manage UserLocations).
class BookingLocationSection extends StatelessWidget {
  const BookingLocationSection({super.key, required this.booking});

  final BookingEntity booking;

  @override
  Widget build(BuildContext context) {
    final address = booking.displayAddress;
    final savedLabel = booking.locationName?.trim();
    final hasCoords = booking.hasMapCoordinates;

    if ((address == null || address.isEmpty) && !hasCoords) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasCoords) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(booking.lat!, booking.lng!),
                  initialZoom: 14,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'ly.albareq.companies',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(booking.lat!, booking.lng!),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppTheme.primaryTeal,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (savedLabel != null && savedLabel.isNotEmpty) ...[
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.bookmark_outline_rounded, size: 18, color: AppTheme.gray500),
              const SizedBox(width: 6),
              Text(
                savedLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.gray700,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (booking.isSavedCustomerLocation) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'موقع محفوظ',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (address != null && address.isNotEmpty)
          Text(
            address,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray800,
                  height: 1.4,
                ),
          ),
        if (hasCoords) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () async {
                final ok = await openBookingInMaps(
                  lat: booking.lat!,
                  lng: booking.lng!,
                  label: savedLabel ?? address,
                );
                if (!context.mounted) return;
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تعذر فتح الخرائط')),
                  );
                }
              },
              icon: const Icon(Icons.map_outlined, size: 20),
              label: const Text('فتح في الخرائط'),
            ),
          ),
        ],
      ],
    );
  }
}
