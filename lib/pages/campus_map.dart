import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CampusMapPage extends StatefulWidget {
  const CampusMapPage({super.key});

  @override
  State<CampusMapPage> createState() => _CampusMapPageState();
}

class _CampusMapPageState extends State<CampusMapPage>
    with TickerProviderStateMixin {
  final LatLng campusCenter =
      const LatLng(7.007122696337987, 100.50075696301798);

  GoogleMapController? mapController;
  Set<Marker> markers = {};
  bool isLoadingLocation = false;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    fetchSavedLocations(); // โหลดสถานที่ที่บันทึกไว้จาก server
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

  void _onMarkerTap(Map<String, dynamic> place) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('บันทึกสถานที่'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อสถานที่',
                hintText: 'กรอกชื่อสถานที่',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'คำอธิบาย',
                hintText: 'กรอกคำอธิบายสถานที่',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final desc = descController.text.trim();

              if (name.isEmpty) {
                _showSnackBar('กรุณากรอกชื่อสถานที่', Icons.error, Colors.red);
                return;
              }

              Navigator.pop(context);

              // อัปเดตข้อมูลสถานที่ด้วยค่าที่ผู้ใช้กรอก
              place['name'] = name;
              place['desc'] = desc;

              await savePlaceToDatabase(place); // บันทึกไปยัง backend
              await fetchSavedLocations(); // รีเฟรช marker ใหม่จาก server
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
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

  // ✅ ฟังก์ชันบันทึกสถานที่ลง FastAPI
  Future<void> savePlaceToDatabase(Map<String, dynamic> place) async {
    final url = Uri.parse('http://10.0.2.2:8000/locations/');
    final body = {
      'name': place['name'],
      'latitude': (place['latlng'] as LatLng).latitude,
      'longitude': (place['latlng'] as LatLng).longitude,
      'description': place['desc'],
    };
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackBar('บันทึกสถานที่สำเร็จ', Icons.check_circle, Colors.green);
      } else {
        _showSnackBar('บันทึกสถานที่ล้มเหลว: ${response.body}', Icons.error, Colors.red);
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e', Icons.error, Colors.red);
    }
  }

  // ✅ ฟังก์ชันดึงสถานที่ที่บันทึกจาก server
  Future<void> fetchSavedLocations() async {
    final url = Uri.parse('http://10.0.2.2:8000/locations/all');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          markers = data.map((location) {
            final id = location['id']; // ✅ ใช้ id จาก backend
            return Marker(
              markerId: MarkerId(id.toString()),
              position: LatLng(location['latitude'], location['longitude']),
              infoWindow: InfoWindow(
                title: location['name'],
                snippet: location['description'],
                onTap: () => _onDeleteMarker(id), // ✅ ใช้ id
              ),
            );
          }).toSet();
        });
      } else {
        _showSnackBar('ไม่สามารถดึงข้อมูลสถานที่ได้: ${response.body}', Icons.error, Colors.red);
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e', Icons.error, Colors.red);
    }
  }

  Future<void> _onDeleteMarker(int markerId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบสถานที่'),
        content: const Text('คุณต้องการลบสถานที่นี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await deletePlaceFromDatabase(markerId);
              setState(() {
                markers.removeWhere((marker) => marker.markerId.value == markerId.toString());
              });
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  Future<void> deletePlaceFromDatabase(int markerId) async {
    final url = Uri.parse('http://10.0.2.2:8000/locations/$markerId');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        _showSnackBar('ลบสถานที่สำเร็จ', Icons.check_circle, Colors.green);
      } else {
        _showSnackBar('ลบสถานที่ล้มเหลว: ${response.body}', Icons.error, Colors.red);
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e', Icons.error, Colors.red);
    }
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
            onTap: (latlng) {
              final place = {
                'name': "สถานที่ที่เลือก",
                'latlng': latlng,
                'desc': 'เลือกจากแผนที่',
              };

              _onMarkerTap(place);
            },
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

  Widget _buildControlButton(
      {required IconData icon, required VoidCallback onPressed}) {
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
