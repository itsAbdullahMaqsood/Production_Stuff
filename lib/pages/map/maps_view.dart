import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:notif_analytics/widgets/floating_button.dart';
import 'package:provider/provider.dart';
import 'maps_viewmodel.dart';

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
                        const Text('Fetching location…'),
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
                  FloatingButtonItem(
                    label: 'Add Marker',
                    icon: Icons.location_pin,
                    color: Colors.red,
                    onTap: () =>
                        context.read<MapsViewModel>().addDefaultMarker(),
                  ),
                  FloatingButtonItem(
                    label: 'Custom Marker',
                    icon: Icons.push_pin_outlined,
                    color: const Color(0xFF6750A4),
                    onTap: () =>
                        context.read<MapsViewModel>().addCustomMarker(),
                  ),
                  FloatingButtonItem(
                    label: 'Remove Selected',
                    icon: Icons.location_off_outlined,
                    color: Colors.deepOrange,
                    onTap: () =>
                        context.read<MapsViewModel>().removeSelectedMarker(),
                  ),
                  FloatingButtonItem(
                    label: 'Static Polyline',
                    icon: Icons.timeline_outlined,
                    color: Colors.blue,
                    onTap: () =>
                        context.read<MapsViewModel>().addStaticPolyline(),
                  ),
                  FloatingButtonItem(
                    label: 'Add Circle',
                    icon: Icons.circle_outlined,
                    color: Colors.purple,
                    onTap: () => context.read<MapsViewModel>().addCircle(),
                  ),
                  FloatingButtonItem(
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
