import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? mapController;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  void _createMarkers() {
    markers = places.map((place) {
      return Marker(
        markerId: MarkerId(place['name']),
        position: place['latlng'],
        infoWindow: InfoWindow(
          title: place['name'],
          snippet: place['desc'],
        ),
        onTap: () => _navigateTo(place['latlng']),
      );
    }).toSet();
  }

  void _navigateTo(LatLng latlng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${latlng.latitude},${latlng.longitude}';
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

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final newLocation = LatLng(position.latitude, position.longitude);
    
    setState(() {
      myLocation = newLocation;
      // Remove existing user location marker if exists
      markers.removeWhere((marker) => marker.markerId.value == 'my_location');
      // Add new user location marker
      markers.add(
        Marker(
          markerId: const MarkerId('my_location'),
          position: newLocation,
          infoWindow: const InfoWindow(title: 'ตำแหน่งของฉัน'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
    
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(newLocation, 18),
    );
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
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: campusCenter,
          zoom: 17,
        ),
        markers: markers,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
      ),
    );
  }
}
