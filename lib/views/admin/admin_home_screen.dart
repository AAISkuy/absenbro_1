import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/dio_client.dart';
import 'package:dio/dio.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final ApiService _apiService = ApiService(createDioClient());

  bool _isLoading = true;
  String? _errorMessage;

  int _totalUsers = 0;
  List<Map<String, dynamic>> _trainings = [];
  List<Map<String, dynamic>> _batches = [];

  @override
  void initState() {
    super.initState();
    _loadAdminDashboardData();
  }

  Future<void> _loadAdminDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usersResponse = await _apiService.getUsersList();
      final trainingsResponse = await _apiService.getTrainings();
      final batchesResponse = await _apiService.getBatches();

      if (mounted) {
        setState(() {
          if (usersResponse.response.statusCode == 200) {
            final dynamic list = usersResponse.data['data'];
            if (list is List) {
              _totalUsers = list.length;
            }
          }
          if (trainingsResponse.response.statusCode == 200) {
            final dynamic list = trainingsResponse.data['data'];
            if (list is List) {
              _trainings = List<Map<String, dynamic>>.from(list);
            }
          }
          if (batchesResponse.response.statusCode == 200) {
            final dynamic list = batchesResponse.data['data'];
            if (list is List) {
              _batches = List<Map<String, dynamic>>.from(list);
            }
          }

          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage =
            e.response?.data['message'] ?? 'Gagal memuat data dasbor admin.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C20),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0C20), Color(0xFF15102A), Color(0xFF050211)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B7EFE)),
                )
              : RefreshIndicator(
                  onRefresh: _loadAdminDashboardData,
                  color: const Color(0xFF8B7EFE),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          "Dasbor Admin PPKD",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Pusat Pemantauan Kehadiran Pelatihan",
                          style: TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                        const SizedBox(height: 28),

                        if (_errorMessage != null) ...[
                          _buildErrorCard(),
                          const SizedBox(height: 20),
                        ],

                        // Main Summary Cards Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                "Total Peserta",
                                _totalUsers.toString(),
                                Icons.people,
                                const Color(0xFF6C63FF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                "Kelas Aktif",
                                _trainings.length.toString(),
                                Icons.school,
                                const Color(0xFF00C9A7),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Trainings List
                        _buildSectionHeader(
                          "Program Pelatihan Aktif (${_trainings.length})",
                        ),
                        const SizedBox(height: 12),
                        _buildTrainingsList(),

                        const SizedBox(height: 28),

                        // Batches List
                        _buildSectionHeader(
                          "Batch / Angkatan (${_batches.length})",
                        ),
                        const SizedBox(height: 12),
                        _buildBatchesList(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF201A38),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTrainingsList() {
    if (_trainings.isEmpty) {
      return const Card(
        color: Color(0xFF201A38),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              "Tidak ada program pelatihan.",
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _trainings.length,
      itemBuilder: (context, index) {
        final training = _trainings[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF201A38),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.class_outlined, color: Color(0xFF8B7EFE)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  training['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBatchesList() {
    if (_batches.isEmpty) {
      return const Card(
        color: Color(0xFF201A38),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              "Tidak ada batch aktif.",
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _batches.length,
      itemBuilder: (context, index) {
        final batch = _batches[index];
        final title =
            (batch['name'] ?? batch['title'] ?? "Batch ${batch['id']}")
                as String;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF201A38),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF00C9A7),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
