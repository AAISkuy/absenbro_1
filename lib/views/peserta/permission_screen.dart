import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../services/dio_client.dart';
import '../../database/databasehelper.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final ApiService _apiService = ApiService(createDioClient());

  Future<void> _selectDate(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark 
              ? const ColorScheme.dark(
                  primary: Color(0xFF6C63FF),
                  onPrimary: Colors.white,
                  surface: Color(0xFF201A38),
                  onSurface: Colors.white,
                )
              : const ColorScheme.light(
                  primary: Color(0xFF6C63FF),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black87,
                ),
            dialogBackgroundColor: isDark ? const Color(0xFF0F0C20) : const Color(0xFFF6F5FA),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmitPermission() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final reason = _reasonController.text.trim();

    try {
      final response = await _apiService.submitPermission({
        'date': dateStr,
        'alasan_izin': reason,
      });

      if (mounted && response.response.statusCode == 200) {
        _reasonController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Izin berhasil diajukan!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      // Offline fallback: store locally
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        final id = await DBHelper().queueOfflineAttendance(
          actionType: 'izin',
          attendanceDate: dateStr,
          checkTime: '',
          alasanIzin: reason,
          status: 'izin',
        );
        if (id > 0) {
          _reasonController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Izin disimpan secara offline. Akan dikirim saat online."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        final msg = e.response?.data['message'] ?? 'Gagal mengajukan izin.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate);
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    "Pengajuan Izin",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Ajukan ketidakhadiran jika Anda berhalangan hadir",
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                  ),
                  const SizedBox(height: 32),

                  // Date Picker Card
                  Container(
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
                        Text("Tanggal Izin", style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                dateFormatted,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today, color: Color(0xFF8B7EFE)),
                              onPressed: () => _selectDate(context),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reason Input Card
                  Container(
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
                        Text("Alasan Izin", style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 12)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _reasonController,
                          maxLines: 5,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Contoh: Sakit demam, keperluan keluarga mendesak, dll.",
                            hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.3) : Colors.black38),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F0C20) : const Color(0xFFF2F1F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF8B7EFE), width: 1.5),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Alasan izin tidak boleh kosong";
                            }
                            if (val.trim().length < 5) {
                              return "Berikan alasan yang lebih detail";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmitPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "Kirim Pengajuan",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
