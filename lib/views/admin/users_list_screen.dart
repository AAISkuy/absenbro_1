import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/dio_client.dart';
import 'package:dio/dio.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final ApiService _apiService = ApiService(createDioClient());

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsersList();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final name = (user['name'] ?? '').toLowerCase();
        final email = (user['email'] ?? '').toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchUsersList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getUsersList();
      if (mounted && response.response.statusCode == 200) {
        final dynamic list = response.data['data'];
        setState(() {
          if (list is List) {
            _users = List<Map<String, dynamic>>.from(list);
            _filteredUsers = _users;
          }
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data['message'] ?? 'Gagal memuat daftar peserta.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDeleteAttendance(int attendanceId) async {
    // Delete attendance modal check
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF201A38),
        title: const Text("Hapus Absen", style: TextStyle(color: Colors.white)),
        content: const Text("Yakin ingin menghapus catatan absensi ini?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text("Batal", style: TextStyle(color: Color(0xFF8B7EFE))),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final response = await _apiService.deleteAttendance(attendanceId);
                if (mounted && response.response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Absen berhasil dihapus"), backgroundColor: Colors.green),
                  );
                }
              } on DioException catch (e) {
                final msg = e.response?.data['message'] ?? 'Gagal menghapus absensi.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showUserDetail(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15102A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                user['name'] ?? 'Detail Peserta',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(user['email'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 24),
              _buildDetailRow("User ID", user['id']?.toString() ?? '-'),
              _buildDetailRow("Tanggal Dibuat", user['created_at'] != null ? user['created_at'].substring(0, 10) : '-'),
              const SizedBox(height: 24),
              // Option to trigger mock delete attendance for ID 9 (as shown in Postman)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _handleDeleteAttendance(9); // Default test ID from Postman
                },
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: const Text("Koreksi / Hapus Absensi", style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "Daftar Peserta",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Cari nama atau email...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6)),
                    filled: true,
                    fillColor: const Color(0xFF201A38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildErrorCard(),
                ),
                const SizedBox(height: 10),
              ],

              // User List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B7EFE)))
                    : RefreshIndicator(
                        onRefresh: _fetchUsersList,
                        color: const Color(0xFF8B7EFE),
                        child: _filteredUsers.isEmpty
                            ? const Center(child: Text("Peserta tidak ditemukan.", style: TextStyle(color: Colors.white54)))
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                itemCount: _filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = _filteredUsers[index];
                                  final name = user['name'] ?? 'Peserta';
                                  final email = user['email'] ?? '';
                                  final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF201A38),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                                        child: Text(initial, style: const TextStyle(color: Color(0xFF8B7EFE), fontWeight: FontWeight.bold)),
                                      ),
                                      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(email, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                      ),
                                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                                      onTap: () => _showUserDetail(user),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
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
      child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
    );
  }
}
