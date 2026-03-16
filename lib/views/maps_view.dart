import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/maps_viewmodel.dart';

class MapsView extends StatelessWidget {
  const MapsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MapsViewModel>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: const Text(
          'Maps',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: context.read<MapsViewModel>().onMapCreated,
            initialCameraPosition: vm.initialCameraPosition,
            mapType: MapType.normal,
            markers: vm.markers,
            polylines: vm.polylines,
            polygons: vm.polygons,
            circles: vm.circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: true,
            onTap: (point) {
              context.read<MapsViewModel>().addTapMarker(point);
            },
          ),
          if (vm.isLoadingLocation)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('Finding your location…'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (vm.locationError != null)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Card(
                color: colors.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    vm.locationError!,
                    style: TextStyle(
                      color: colors.onErrorContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 16,
            right: 16,
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _SpeedDialItem(
                    label: 'Add Marker',
                    icon: Icons.location_pin,
                    color: Colors.red,
                    onTap: () =>
                        context.read<MapsViewModel>().addDefaultMarker(),
                  ),
                  _SpeedDialItem(
                    label: 'Custom Marker',
                    icon: Icons.push_pin_outlined,
                    color: const Color(0xFF6750A4),
                    onTap: () =>
                        context.read<MapsViewModel>().addCustomMarker(),
                  ),
                  _SpeedDialItem(
                    label: 'Remove Selected',
                    icon: Icons.location_off_outlined,
                    color: Colors.deepOrange,
                    onTap: () =>
                        context.read<MapsViewModel>().removeSelectedMarker(),
                  ),
                  _SpeedDialItem(
                    label: 'Static Polyline',
                    icon: Icons.timeline_outlined,
                    color: Colors.blue,
                    onTap: () =>
                        context.read<MapsViewModel>().addStaticPolyline(),
                  ),
                  _SpeedDialItem(
                    label: 'Add Polygon',
                    icon: Icons.pentagon_outlined,
                    color: Colors.green,
                    onTap: () => context.read<MapsViewModel>().addPolygon(),
                  ),
                  _SpeedDialItem(
                    label: 'Add Circle',
                    icon: Icons.circle_outlined,
                    color: Colors.purple,
                    onTap: () => context.read<MapsViewModel>().addCircle(),
                  ),
                  _SpeedDialItem(
                    label: 'Clear All',
                    icon: Icons.layers_clear_outlined,
                    color: Colors.grey,
                    onTap: () => context.read<MapsViewModel>().clearAll(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedDialItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SpeedDialItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            height: 42,
            child: FloatingActionButton.small(
              heroTag: label,
              onPressed: onTap,
              backgroundColor: color,
              foregroundColor: Colors.white,
              child: Icon(icon, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
