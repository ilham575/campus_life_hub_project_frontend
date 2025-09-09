import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class CampusMapPage extends StatefulWidget {
  const CampusMapPage({super.key});

  @override
  State<CampusMapPage> createState() => _CampusMapPageState();
}

class _CampusMapPageState extends State<CampusMapPage> {
  final LatLng campusCenter = const LatLng(7.007122696337987, 100.50075696301798);

  final List<Map<String, dynamic>> places = const [
    {
      'name': 'อาคารเรียนหลัก',
      'latlng': LatLng(7.007341788783633, 100.5021173170882),
      'desc': 'อาคารเรียนและสำนักงาน',
    },
    {
      'name': 'โรงอาหาร',
      'latlng': LatLng(7.0115954288847515, 100.49968179163068),
      'desc': 'โรงอาหารกลาง',
    },
  ];

  LatLng? myLocation;
  final mapController = MapController();

  void _navigateTo(LatLng latlng) async {
    final url = 'https://www.openstreetmap.org/?mlat=${latlng.latitude}&mlon=${latlng.longitude}#map=18/${latlng.latitude}/${latlng.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _findMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      myLocation = LatLng(position.latitude, position.longitude);
    });
    mapController.move(myLocation!, 18);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แผนที่มหาวิทยาลัย'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'ตำแหน่งของฉัน',
            onPressed: _findMyLocation,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          center: campusCenter,
          zoom: 17,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              ...places.map((place) => Marker(
                point: place['latlng'],
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _navigateTo(place['latlng']),
                  child: const Icon(Icons.location_on, color: Colors.deepPurple, size: 36),
                ),
              )),
              if (myLocation != null)
                Marker(
                  point: myLocation!,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
