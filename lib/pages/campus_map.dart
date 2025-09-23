import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class CampusMapPage extends StatefulWidget {
  const CampusMapPage({super.key});

  @override
  State<CampusMapPage> createState() => _CampusMapPageState();
}

class _CampusMapPageState extends State<CampusMapPage> with TickerProviderStateMixin {
  final LatLng campusCenter = const LatLng(7.007122696337987, 100.50075696301798);

  final List<Map<String, dynamic>> places = const [
    {
      'name': 'อาคารเรียนหลัก',
      'latlng': LatLng(7.007341788783633, 100.5021173170882),
      'desc': 'อาคารเรียนและสำนักงาน',
      'icon': Icons.school,
    },
    {
      'name': 'โรงอาหาร',
      'latlng': LatLng(7.0115954288847515, 100.49968179163068),
      'desc': 'โรงอาหารกลาง',
      'icon': Icons.restaurant,
    },
  ];

  LatLng? myLocation;
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  bool isLoadingLocation = false;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _createMarkers();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
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
    setState(() {
      isLoadingLocation = true;
    });
    
    _fabController.forward();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('กรุณาเปิดการใช้งาน GPS', Icons.location_off, Colors.orange);
        await Geolocator.openLocationSettings();
        return;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('ไม่ได้รับอนุญาตใช้ตำแหน่ง', Icons.location_disabled, Colors.red);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('การเข้าถึงตำแหน่งถูกปฏิเสธอย่างถาวร', Icons.location_disabled, Colors.red);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final newLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        myLocation = newLocation;
        markers.removeWhere((marker) => marker.markerId.value == 'my_location');
        markers.add(
          Marker(
            markerId: const MarkerId('my_location'),
            position: newLocation,
            infoWindow: const InfoWindow(title: 'ตำแหน่งของฉัน'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });
      
      await mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newLocation, 18),
      );
      
      _showSnackBar('พบตำแหน่งของคุณแล้ว', Icons.location_on, Colors.green);
    } catch (e) {
      _showSnackBar('ไม่สามารถหาตำแหน่งได้', Icons.error, Colors.red);
    } finally {
      setState(() {
        isLoadingLocation = false;
      });
      _fabController.reverse();
    }
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showPlacesList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'สถานที่ในมหาวิทยาลัย',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...places.map((place) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple.shade100,
                child: Icon(place['icon'], color: Colors.deepPurple),
              ),
              title: Text(place['name']),
              subtitle: Text(place['desc']),
              onTap: () {
                Navigator.pop(context);
                mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(place['latlng'], 18),
                );
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('แผนที่มหาวิทยาลัย', 
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: Colors.deepPurple.withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
            tooltip: 'รายการสถานที่',
            onPressed: _showPlacesList,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
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
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 16,
            child: Column(
              children: [
                _buildControlButton(
                  icon: Icons.zoom_in,
                  onPressed: () {
                    mapController?.animateCamera(CameraUpdate.zoomIn());
                  },
                ),
                const SizedBox(height: 8),
                _buildControlButton(
                  icon: Icons.zoom_out,
                  onPressed: () {
                    mapController?.animateCamera(CameraUpdate.zoomOut());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_fabController.value * 0.1),
            child: FloatingActionButton.extended(
              onPressed: isLoadingLocation ? null : _findMyLocation,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 8,
              icon: isLoadingLocation 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.my_location),
              label: Text(
                isLoadingLocation ? 'กำลังค้นหา...' : 'ตำแหน่งของฉัน',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.deepPurple),
          ),
        ),
      ),
    );
  }
}
