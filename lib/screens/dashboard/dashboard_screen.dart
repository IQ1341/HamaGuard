import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../widgets/thermal_heatmap.dart';
import '../../widgets/costum_header.dart';
import '../notification/notification_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DatabaseReference _sensorRef;
  late DatabaseReference _thermalRef;

  Map<String, dynamic> sensorData = {
    'PIR': '0',
    'Ultrasonik': '0',
    'Jenis Deteksi': 'Tidak terdeteksi',
  };

  List<double> thermalData = List.filled(64, 0.0);


  @override
  void initState() {
    super.initState();

    _sensorRef = FirebaseDatabase.instance.ref('sensor');
    _thermalRef = FirebaseDatabase.instance.ref('thermal_data');

    // Listen sensor data from Realtime Database
    _sensorRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final sensorMap = Map<String, dynamic>.from(data);
        setState(() {
          sensorData = {
            'PIR': (sensorMap['pir'] == true) ? 'Terdeteksi' : 'Tidak',
            'Ultrasonik': sensorMap['ultrasonik'] != null
                ? '${(sensorMap['ultrasonik'] is num ? (sensorMap['ultrasonik'] as num).round() : sensorMap['ultrasonik'])} cm'
                : '-',
            'Jenis Deteksi': sensorMap['jenis_deteksi'] != null
                ? sensorMap['jenis_deteksi'].toString()
                : 'Tidak terdeteksi',
          };
        });
      }
    });


    // Listen thermal data from Realtime Database
    _thermalRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final tempsData = data['temperatures'];
        if (tempsData != null && tempsData is List) {
          List<double> temps = tempsData.map<double>((e) {
            if (e is num) return e.toDouble();
            return 0.0;
          }).toList();

          if (temps.length == 64) {
            setState(() {
              thermalData = temps;
            });
          }
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomHeader(
        deviceName: "HamaGuard",
        isDashboard: true,
        onNotificationTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationScreen()),
          );

        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Thermal Sensor Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 2,
              shadowColor: Colors.green.withOpacity(0.2),
              color: Colors.white,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.thermostat_outlined,
                            color: Color.fromRGBO(56, 142, 60, 1), size: 30),
                        SizedBox(width: 12),
                        Text(
                          'Thermal Sensor',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Color.fromRGBO(56, 142, 60, 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ThermalHeatmap(temperatures: thermalData),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sensor Cards row (PIR & Ultrasonik)
            Row(
              children: [
                Expanded(
                  child: SensorCard(
                    title: 'PIR',
                    value: sensorData['PIR'] ?? '-',
                    icon: Icons.motion_photos_on_outlined,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: SensorCard(
                    title: 'Jarak',
                    value: sensorData['Ultrasonik'] ?? '-',
                    icon: Icons.straighten,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SensorCard(
              title: 'Jenis Deteksi',
              value: sensorData['Jenis Deteksi'] ?? '-',
              icon: Icons.info_outline,
              color: Colors.green.shade700,
              isWide: true,
            ),
          ],
        ),
      ),
    );
  }
}

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isWide;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: color.withOpacity(0.1),
      color: Colors.white,
      child: Container(
        width: isWide ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
