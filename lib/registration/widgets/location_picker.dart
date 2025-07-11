import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPicker extends StatefulWidget {
  final String? initialLocation;
  final ValueChanged<String> onLocationPicked;
  const LocationPicker({
    super.key,
    this.initialLocation,
    required this.onLocationPicked,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late TextEditingController _controller;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLocation ?? '');
  }

  Future<void> _detectLocation() async {
    setState(() => _loading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
      final pos = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      final city = placemarks.first.locality ?? '';
      if (city.isNotEmpty) {
        _controller.text = city;
        widget.onLocationPicked(city);
      } else {
        throw Exception('City not found');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not detect location: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'City',
              border: OutlineInputBorder(),
            ),
            onChanged: widget.onLocationPicked,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _loading ? null : _detectLocation,
          icon: const Icon(Icons.my_location),
          label:
              _loading
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Detect'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(80, 48)),
        ),
      ],
    );
  }
}
