import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

import '../../auth/auth_manager.dart';
import '../peserta/home_screen.dart';
import '../peserta/history_screen.dart';
import '../peserta/permission_screen.dart';
import '../admin/admin_home_screen.dart';
import '../admin/users_list_screen.dart';
import '../auth/login_screen.dart';
import '../../services/api_service.dart';
import '../../services/dio_client.dart';
import 'package:dio/dio.dart';
import '../../main.dart';
import '../../database/preferences_handler.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isAdmin = false;
  bool _isLoading = true;
  
  List<BottomNavigationBarItem> _navItems = [];

  final ApiService _apiService = ApiService(createDioClient());
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    if (AuthManager().currentUser == null) {
      final success = await AuthManager().checkSession();
      if (!success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isAdmin = AuthManager().currentUser?.isAdmin ?? false;
        
        if (_isAdmin) {
          _navItems = const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Peserta',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ];
        } else {
          _navItems = const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mail_outline),
              activeIcon: Icon(Icons.mail),
              label: 'Izin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ];
        }
        
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadPhoto(XFile image) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = await File(image.path).readAsBytes();
      
      // Determine actual mime type from file extension
      final extension = image.path.split('.').last.toLowerCase();
      String mimeType = 'image/png';
      if (extension == 'jpg' || extension == 'jpeg') {
        mimeType = 'image/jpeg';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      }
      
      final base64Image = "data:$mimeType;base64,${base64Encode(bytes)}";

      final response = await _apiService.updateProfilePhoto({
        'profile_photo': base64Image,
      });

      if (response.response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData.containsKey('data')) {
          final dataMap = responseData['data'];
          if (dataMap is Map && dataMap.containsKey('profile_photo')) {
            final photoUrl = dataMap['profile_photo'].toString();
            await AuthManager().updateProfilePhotoUrl(photoUrl);
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Foto profil berhasil diperbarui!"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = "Gagal memperbarui foto profil: $e";
        if (e is DioException && e.response != null) {
          final data = e.response!.data;
          if (data is Map && data.containsKey('message')) {
            errorMessage = data['message'].toString();
            if (data.containsKey('errors') && data['errors'] is Map) {
              final errors = data['errors'] as Map;
              final errorMsgs = errors.values.expand((v) => v is List ? v : [v]).join(", ");
              errorMessage = "$errorMessage: $errorMsgs";
            }
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _initDashboard();
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 40, // Slightly compress to reduce payload size
      );

      if (image == null) return;
      await _uploadPhoto(image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengambil gambar: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _handlePickAndUploadPhoto() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF15102A) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                "Ubah Foto Profil",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceButton(
                    icon: Icons.camera_alt_outlined,
                    label: "Kamera",
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.camera);
                    },
                    isDark: isDark,
                  ),
                  _buildSourceButton(
                    icon: Icons.photo_library_outlined,
                    label: "Galeri",
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.gallery);
                    },
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: const Color(0xFF8B7EFE),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedProfilePhotoUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty || rawUrl.toLowerCase() == 'null') {
      return "";
    }
    String formattedUrl = rawUrl;
    if (!formattedUrl.startsWith("http://") && !formattedUrl.startsWith("https://")) {
      const baseUrl = 'https://appabsensi.mobileprojp.com';
      if (formattedUrl.startsWith("/")) {
        formattedUrl = "$baseUrl$formattedUrl";
      } else {
        formattedUrl = "$baseUrl/$formattedUrl";
      }
    }
    return formattedUrl.replaceAll("127.0.0.1", "10.0.2.2").replaceAll("localhost", "10.0.2.2");
  }

  Future<void> _showEditNameDialog() async {
    final user = AuthManager().currentUser;
    if (user == null) return;
    
    final controller = TextEditingController(text: user.name);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF201A38) : Colors.white,
        title: Text("Ubah Nama", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: "Nama Baru",
            hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B7EFE))),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Batal", style: TextStyle(color: Color(0xFF8B7EFE))),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              
              Navigator.of(ctx).pop();
              setState(() {
                _isLoading = true;
              });

              try {
                final response = await _apiService.updateProfile({
                  'name': newName,
                });
                
                if (response.response.statusCode == 200) {
                  await AuthManager().checkSession();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Nama berhasil diperbarui!"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Gagal memperbarui nama: $e"), backgroundColor: Colors.redAccent),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
                _initDashboard();
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF201A38) : Colors.white,
        title: Text("Logout", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Text("Apakah Anda yakin ingin keluar?", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
            child: const Text("Batal", style: TextStyle(color: Color(0xFF8B7EFE))),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthManager().logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildProfileScreen() {
    final user = AuthManager().currentUser;
    if (user == null) return const SizedBox();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              Center(
                child: GestureDetector(
                  onTap: _handlePickAndUploadPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 64,
                        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                        backgroundImage: _getFormattedProfilePhotoUrl(user.profilePhoto).isNotEmpty
                            ? NetworkImage(_getFormattedProfilePhotoUrl(user.profilePhoto))
                            : null,
                        child: _getFormattedProfilePhotoUrl(user.profilePhoto).isEmpty
                            ? const Icon(Icons.person, size: 64, color: Colors.white70)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6C63FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 36), // Balances the GestureDetector on the right to keep name centered
                  Flexible(
                    child: Text(
                      user.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showEditNameDialog,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: Icon(Icons.edit_outlined, color: Color(0xFF8B7EFE), size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                user.email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, 
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isAdmin ? Colors.redAccent.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isAdmin ? Colors.redAccent : Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _isAdmin ? "ADMINISTRATOR" : "PESERTA PELATIHAN",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _isAdmin ? Colors.redAccent : Colors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              _buildThemeToggleTile(),
              _buildDetailTile("ID Pengguna", user.id.toString(), Icons.badge_outlined),
              _buildDetailTile("Jenis Kelamin", user.jenisKelamin == 'L' ? 'Laki-laki' : (user.jenisKelamin == 'P' ? 'Perempuan' : 'Tidak Diketahui'), Icons.transgender_outlined),
              if (!_isAdmin) ...[
                _buildDetailTile("Batch ID", user.batchId?.toString() ?? "-", Icons.group_work_outlined),
                _buildDetailTile("Training ID", user.trainingId?.toString() ?? "-", Icons.school_outlined),
              ],
              const SizedBox(height: 30),
              
              OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text("Keluar dari Akun", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggleTile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201A38) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: const Color(0xFF8B7EFE),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mode Tampilan",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDark ? "Mode Gelap Aktif" : "Mode Terang Aktif",
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: isDark,
            activeColor: const Color(0xFF6C63FF),
            onChanged: (val) {
              final newMode = val ? ThemeMode.dark : ThemeMode.light;
              themeNotifier.value = newMode;
              PreferencesHandler.setThemeMode(val ? "dark" : "light");
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201A38) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B7EFE)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label, 
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45, 
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value, 
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0C20) : const Color(0xFFF6F5FA),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B7EFE)),
        ),
      );
    }

    final screens = _isAdmin
        ? [
            const AdminHomeScreen(),
            const UsersListScreen(),
            _buildProfileScreen(),
          ]
        : [
            const HomeScreen(),
            const HistoryScreen(),
            const PermissionScreen(),
            _buildProfileScreen(),
          ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: isDark ? const Color(0xFF15102A) : Colors.white,
        selectedItemColor: const Color(0xFF8B7EFE),
        unselectedItemColor: isDark ? Colors.white.withOpacity(0.4) : Colors.black38,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: _navItems,
      ),
    );
  }
}
