import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/event_service.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadEvents();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _loadEvents() async {
    if (_currentPosition == null) return;

    try {
      final events = await context.read<EventService>().getEvents(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );

      setState(() {
        _markers = events.map((event) {
          return Marker(
            point: LatLng(event.latitude, event.longitude),
            width: 80,
            height: 80,
            builder: (context) => GestureDetector(
              onTap: () => _showEventDetails(event),
              child: Column(
                children: [
                  Icon(
                    _getCategoryIcon(event.category),
                    color: Colors.red,
                    size: 30,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.category,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading events: $e')),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'HAZARD':
        return Icons.warning;
      case 'ROAD_CLOSURE':
        return Icons.road;
      case 'DOG_BITE':
        return Icons.pets;
      default:
        return Icons.info;
    }
  }

  void _showEventDetails(Event event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.category,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(event.description),
            if (event.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: event.mediaUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Image.network(
                        'http://localhost:3000/api/events/media/${event.mediaUrls[index]}',
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Be Aware'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(
            _currentPosition?.latitude ?? 0,
            _currentPosition?.longitude ?? 0,
          ),
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.be_aware',
          ),
          MarkerLayer(markers: _markers),
          if (_currentPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  width: 80,
                  height: 80,
                  builder: (context) => const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportScreen()),
          );
          if (result == true) {
            _loadEvents();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 