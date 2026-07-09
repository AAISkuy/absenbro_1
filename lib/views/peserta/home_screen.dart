import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'dart:developer';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/api_service.dart';
import '../../services/dio_client.dart';
import '../../services/location_service.dart';
import '../../database/databasehelper.dart';
import '../../auth/auth_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService(createDioClient());
  final LocationService _locationService = LocationService();

  GoogleMapController? _mapController;

  bool _isCheckingStatus = true;
  bool _isLocating = false;
  bool _isSubmitting = false;

  Position? _currentPosition;
  String _address = "Mencari lokasi...";
  double _distanceToTarget = 0.0;
  bool _isInRadius = false;

  Map<String, dynamic>? _todayAttendance;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkStatusAndLocate();
  }

  Future<void> _checkStatusAndLocate() async {
    setState(() {
      _isCheckingStatus = true;
    });

    await _fetchTodayAttendance();
    await _updateUserLocation();

    if (mounted) {
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  Future<void> _fetchTodayAttendance() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final response = await _apiService.getTodayAttendance(todayStr);
      if (mounted && response.response.statusCode == 200) {
        setState(() {
          _todayAttendance = response.data['data'];
          _isOffline = false;
        });
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        log("DioException while fetching today's attendance: $e");
      }
      if (mounted) {
        setState(() {
          _isOffline = e.response == null || 
                       e.type == DioExceptionType.connectionError || 
                       e.type == DioExceptionType.connectionTimeout;
          if (!_isOffline && e.response?.statusCode == 404) {
            _todayAttendance = null;
          }
        });
      }
    } catch (e) {
      log("Error fetching today's attendance: $e");
    }
  }

  Future<void> _updateUserLocation() async {
    if (_isLocating) return;
    
    setState(() {
      _isLocating = true;
    });

    final hasPermission = await _locationService.checkPermission();
    if (!hasPermission) {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _address = "Izin lokasi ditolak. Silakan aktifkan di Pengaturan.";
        });
      }
      return;
    }

    try {
      final position = await _locationService.getCurrentLocation();
      final distance = _locationService.calculateDistance(position.latitude, position.longitude);
      final inRadius = _locationService.isWithinRadius(position.latitude, position.longitude);
      final address = await _locationService.getAddressFromCoordinates(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _distanceToTarget = distance;
          _isInRadius = inRadius;
          _address = address;
          _isLocating = false;
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              16.0,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _address = "Gagal mengambil koordinat lokasi.";
        });
      }
    }
  }

  Future<void> _handleCheckIn() async {
    final now = DateTime.now();
    if (now.hour < 4) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF201A38),
          title: const Text("Belum Waktunya", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Absen masuk baru dibuka mulai pukul 04:00 pagi.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK", style: TextStyle(color: Color(0xFF8B7EFE))),
            )
          ],
        ),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Menunggu koordinat GPS stabil...")),
      );
      return;
    }

    if (!_isInRadius) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF201A38),
          title: const Text("Gagal Absen", style: TextStyle(color: Colors.white)),
          content: Text(
            "Anda berada ${_distanceToTarget.toStringAsFixed(1)} meter dari PPKD. Jarak maksimum check-in adalah ${LocationService.allowedRadiusMeters} meter.",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK", style: TextStyle(color: Color(0xFF8B7EFE))),
            )
          ],
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final timeStr = DateFormat('HH:mm').format(DateTime.now());

    final body = {
      'attendance_date': todayStr,
      'check_in': timeStr,
      'check_in_lat': _currentPosition!.latitude,
      'check_in_lng': _currentPosition!.longitude,
      'check_in_address': _address,
      'status': 'masuk',
    };

    if (_isOffline) {
      // Offline support: Cache local check-in
      final id = await DBHelper().queueOfflineAttendance(
        actionType: 'check-in',
        attendanceDate: todayStr,
        checkTime: timeStr,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _address,
        status: 'masuk',
      );
      setState(() {
        _isSubmitting = false;
        _todayAttendance = {
          'attendance_date': todayStr,
          'check_in_time': timeStr,
          'check_in_address': _address,
          'status': 'masuk (offline)',
        };
      });
      if (id > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Absen disimpan secara offline. Akan disinkronkan saat online."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final response = await _apiService.checkIn(body);
      if (response.response.statusCode == 200) {
        setState(() {
          _todayAttendance = response.data['data'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Absen masuk berhasil!"), backgroundColor: Colors.green),
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Gagal absen masuk.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _handleCheckOut() async {
    final now = DateTime.now();
    String? earlyReason;

    if (now.hour < 16) {
      final reason = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final controller = TextEditingController();
          bool showError = false;
          return StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return AlertDialog(
                backgroundColor: const Color(0xFF201A38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text(
                  "Check Out Cepat",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Ingin check out?",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Tambahkan text Alasan check out cepat:",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Tulis alasan di sini...",
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.1),
                          errorText: showError ? "Alasan check out cepat wajib diisi" : null,
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF8B7EFE)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.redAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.redAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(null),
                    child: const Text("Batal", style: TextStyle(color: Colors.white54)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B7EFE),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {
                      final text = controller.text.trim();
                      if (text.isEmpty) {
                        setStateDialog(() {
                          showError = true;
                        });
                        return;
                      }
                      Navigator.of(ctx).pop(text);
                    },
                    child: const Text("Check Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        },
      );

      if (reason == null) {
        return; // User cancelled check-out
      }
      earlyReason = reason;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Menunggu koordinat GPS stabil...")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final timeStr = DateFormat('HH:mm').format(DateTime.now());

    final body = {
      'attendance_date': todayStr,
      'check_out': timeStr,
      'check_out_lat': _currentPosition!.latitude,
      'check_out_lng': _currentPosition!.longitude,
      'check_out_address': _address,
    };
    if (earlyReason != null) {
      body['alasan_check_out_cepat'] = earlyReason;
    }

    if (_isOffline) {
      // Offline check-out caching
      final id = await DBHelper().queueOfflineAttendance(
        actionType: 'check-out',
        attendanceDate: todayStr,
        checkTime: timeStr,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _address,
        alasanIzin: earlyReason,
      );
      setState(() {
        _isSubmitting = false;
        if (_todayAttendance != null) {
          _todayAttendance!['check_out_time'] = timeStr;
          _todayAttendance!['check_out_address'] = _address;
        }
      });
      if (id > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Absen keluar disimpan secara offline."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final response = await _apiService.checkOut(body);
      if (response.response.statusCode == 200) {
        setState(() {
          _todayAttendance = response.data['data'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Absen keluar berhasil!"), backgroundColor: Colors.green),
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Gagal absen keluar.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthManager().currentUser;
    final timeNow = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [const Color(0xFF0F0C20), const Color(0xFF15102A), const Color(0xFF050211)]
                : [const Color(0xFFF2F1F7), const Color(0xFFE8E7F0), const Color(0xFFF6F5FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _checkStatusAndLocate,
            color: const Color(0xFF8B7EFE),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  // User Welcome header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Halo, ${user?.name ?? 'Peserta'}",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeNow,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                          ),
                        ],
                      ),
                      if (_isOffline)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange, width: 0.8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.wifi_off, color: Colors.orange, size: 14),
                              SizedBox(width: 6),
                              Text("Offline Mode", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Today's Status Box
                  _buildTodayStatusCard(),

                  const SizedBox(height: 28),

                  // Geofence & Location Panel
                  _buildLocationCard(),

                  const SizedBox(height: 32),

                  // Action Button (Combined Check In / Check Out)
                  Builder(
                    builder: (context) {
                      final hasCheckedIn = _todayAttendance?['check_in_time'] != null;
                      final hasCheckedOut = _todayAttendance?['check_out_time'] != null;
                      final isIzin = _todayAttendance?['status'] == 'izin';

                      String title;
                      String subtitle;
                      IconData icon;
                      Color color;
                      bool isActive;
                      VoidCallback onTap;

                      if (isIzin) {
                        title = "IZIN HARI INI";
                        subtitle = "Pengajuan izin hari ini telah disetujui";
                        icon = Icons.assignment_turned_in_outlined;
                        color = Colors.orange;
                        isActive = false;
                        onTap = () {};
                      } else if (!hasCheckedIn) {
                        title = "CHECK IN";
                        subtitle = "Tekan untuk Absen Masuk";
                        icon = Icons.login_outlined;
                        color = const Color(0xFF6C63FF);
                        isActive = !_isCheckingStatus && !_isSubmitting;
                        onTap = _handleCheckIn;
                      } else if (!hasCheckedOut) {
                        title = "CHECK OUT";
                        subtitle = "Tekan untuk Absen Pulang";
                        icon = Icons.logout_outlined;
                        color = const Color(0xFF00C9A7);
                        isActive = !_isCheckingStatus && !_isSubmitting;
                        onTap = _handleCheckOut;
                      } else {
                        title = "ABSEN SELESAI";
                        subtitle = "Kehadiran hari ini sudah tercatat";
                        icon = Icons.check_circle_outline;
                        color = Colors.grey;
                        isActive = false;
                        onTap = () {};
                      }

                      return _buildActionButton(
                        title: title,
                        subtitle: subtitle,
                        icon: icon,
                        color: color,
                        isActive: isActive,
                        onTap: onTap,
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard() {
    final checkIn = _todayAttendance?['check_in_time'] ?? "--:--";
    final checkOut = _todayAttendance?['check_out_time'] ?? "--:--";
    final status = _todayAttendance?['status'] ?? "belum absen";
    final isDark = Theme.of(context).brightness == Brightness.dark;

    bool isLate = false;
    if (checkIn != "--:--" && (status == 'masuk' || status.contains('masuk'))) {
      try {
        final parts = checkIn.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (hour > 7 || (hour == 7 && minute > 0)) {
          isLate = true;
        }
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201A38) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark 
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Kehadiran Hari Ini", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLate 
                      ? Colors.redAccent.withOpacity(0.2) 
                      : (status == 'masuk' || status.contains('masuk')
                          ? Colors.green.withOpacity(0.2) 
                          : (status == 'izin' ? Colors.orange.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2))),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isLate ? "TERLAMBAT" : status.toUpperCase(),
                  style: TextStyle(
                    color: isLate 
                        ? Colors.redAccent 
                        : (status == 'masuk' || status.contains('masuk')
                            ? Colors.green 
                            : (status == 'izin' ? Colors.orange : Colors.redAccent)),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Icon(Icons.access_time_outlined, color: Color(0xFF8B7EFE), size: 28),
                  const SizedBox(height: 8),
                  Text("Check-In", style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(checkIn, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(width: 1, height: 50, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
              Column(
                children: [
                  const Icon(Icons.update_outlined, color: Color(0xFF00C9A7), size: 28),
                  const SizedBox(height: 8),
                  Text("Check-Out", style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(checkOut, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201A38) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark 
            ? null 
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Informasi Lokasi", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.refresh, color: _isLocating ? (isDark ? Colors.white24 : Colors.black26) : const Color(0xFF8B7EFE), size: 20),
                onPressed: _isLocating ? null : _updateUserLocation,
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.redAccent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _address,
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Jarak ke PPKD", style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    "${_distanceToTarget.toStringAsFixed(1)} meter",
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isInRadius ? Colors.green.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isInRadius ? Icons.check_circle_outline : Icons.cancel_outlined,
                      color: _isInRadius ? Colors.green : Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isInRadius ? "Dalam Radius" : "Luar Radius",
                      style: TextStyle(
                        color: _isInRadius ? Colors.green : Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            clipBehavior: Clip.antiAlias,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : const LatLng(LocationService.targetLatitude, LocationService.targetLongitude),
                zoom: 15.0,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: {
                if (_currentPosition != null)
                  Marker(
                    markerId: const MarkerId('user_loc'),
                    position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    infoWindow: const InfoWindow(title: 'Lokasi Anda'),
                  ),
                Marker(
                  markerId: const MarkerId('target_loc'),
                  position: LatLng(LocationService.targetLatitude, LocationService.targetLongitude),
                  infoWindow: const InfoWindow(title: 'Kantor PPKD'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                ),
              },
              circles: {
                Circle(
                  circleId: const CircleId('geofence_circle'),
                  center: const LatLng(LocationService.targetLatitude, LocationService.targetLongitude),
                  radius: LocationService.allowedRadiusMeters,
                  fillColor: const Color(0xFF8B7EFE).withOpacity(0.15),
                  strokeColor: const Color(0xFF8B7EFE),
                  strokeWidth: 2,
                ),
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTextColor = isDark ? Colors.white : Colors.black87;
    final inactiveTextColor = isDark ? Colors.white24 : Colors.black26;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.15) : (isDark ? Colors.grey.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive ? color.withOpacity(0.5) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isActive ? color : (isDark ? Colors.white24 : Colors.black26), size: 36),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? activeTextColor : inactiveTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isActive ? (isDark ? Colors.white54 : Colors.black54) : inactiveTextColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
