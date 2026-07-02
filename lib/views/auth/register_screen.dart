import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/dio_client.dart';
import '../../auth/auth_manager.dart';
import '../dashboard/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _gender; // Null by default for placeholder hint
  int? _selectedTrainingId;
  int? _selectedBatchId;
  
  bool _isLoading = false;
  bool _isFetchingData = true;
  bool _obscurePassword = true;
  
  List<Map<String, dynamic>> _trainings = [];
  List<Map<String, dynamic>> _batches = [];
  
  String? _errorMessage;
  final ApiService _apiService = ApiService(createDioClient());

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final trainingsResponse = await _apiService.getTrainings();
      // For batches, wait, let's see if we can get batches. The Postman has /api/batches
      // Let's call getBatches
      final batchesResponse = await _apiService.getBatches();

      if (mounted) {
        setState(() {
          if (trainingsResponse.response.statusCode == 200) {
            final dynamic data = trainingsResponse.data['data'];
            if (data is List) {
              _trainings = List<Map<String, dynamic>>.from(data);
            }
          }
          if (batchesResponse.response.statusCode == 200) {
            final dynamic data = batchesResponse.data['data'];
            if (data is List) {
              _batches = List<Map<String, dynamic>>.from(data);
            }
          } else {
            // Fallback default mock batches if empty
            _batches = [
              {'id': 1, 'name': 'Angkatan 1'},
              {'id': 2, 'name': 'Angkatan 2'},
              {'id': 3, 'name': 'Angkatan 3'},
            ];
          }
          
          _isFetchingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingData = false;
          // Fallback mocks
          _trainings = [
            {'id': 1, 'title': 'Operator Komputer'},
            {'id': 16, 'title': 'Mobile Programming'},
          ];
          _batches = [
            {'id': 1, 'name': 'Angkatan 1 - 2026'},
            {'id': 2, 'name': 'Angkatan 2 - 2026'},
          ];
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedTrainingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih program pelatihan")),
      );
      return;
    }
    
    if (_selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih batch/angkatan")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await AuthManager().register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      gender: _gender!,
      batchId: _selectedBatchId!,
      trainingId: _selectedTrainingId!,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      setState(() {
        _errorMessage = error;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF2F1F7), Color(0xFFE8E7F0), Color(0xFFF6F5FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isFetchingData
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8B7EFE),
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        // Title Section
                        const Text(
                          "Pendaftaran Baru",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF201A38),
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Lengkapi formulir untuk membuat akun peserta",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 32),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.black87),
                          decoration: _buildInputDecoration("Nama Lengkap", Icons.person_outline),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Nama wajib diisi";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.black87),
                          decoration: _buildInputDecoration("Alamat Email", Icons.email_outlined),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Email wajib diisi";
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                              return "Format email tidak valid";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: "Password",
                            hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
                            prefixIcon: Icon(Icons.lock_outlined, color: Colors.black.withOpacity(0.5)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.black.withOpacity(0.5),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF8B7EFE), width: 1.5),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Password tidak boleh kosong";
                            }
                            if (val.length < 6) {
                              return "Password minimal 6 karakter";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Gender Field (Dropdown)
                        DropdownButtonFormField<String>(
                          value: _gender,
                          hint: const Text(
                            "Jenis Kelamin",
                            style: TextStyle(color: Colors.black38, fontSize: 13),
                          ),
                          style: const TextStyle(color: Colors.black87),
                          dropdownColor: Colors.white,
                          decoration: _buildInputDecoration("Jenis Kelamin", Icons.wc_outlined),
                          items: const [
                            DropdownMenuItem(
                              value: 'L',
                              child: Text(
                                "Laki-laki",
                                style: TextStyle(color: Colors.black87, fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'P',
                              child: Text(
                                "Perempuan",
                                style: TextStyle(color: Colors.black87, fontSize: 13),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _gender = val!;
                            });
                          },
                          validator: (val) => val == null ? "Jenis kelamin harus dipilih" : null,
                        ),
                        const SizedBox(height: 16),

                        // Training Program Selection
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: _selectedTrainingId,
                          hint: const Text(
                            "Program Pelatihan",
                            style: TextStyle(color: Colors.black38, fontSize: 13),
                          ),
                          style: const TextStyle(color: Colors.black87),
                          dropdownColor: Colors.white,
                          decoration: _buildInputDecoration("Program Pelatihan", Icons.school_outlined),
                          items: _trainings.map((t) {
                            return DropdownMenuItem<int>(
                              value: t['id'] as int,
                              child: Text(
                                t['title'] as String,
                                style: const TextStyle(color: Colors.black87, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedTrainingId = val;
                            });
                          },
                          validator: (val) => val == null ? "Pelatihan harus dipilih" : null,
                        ),
                        const SizedBox(height: 16),

                        // Batch Selection
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: _selectedBatchId,
                          hint: const Text(
                            "Batch / Angkatan",
                            style: TextStyle(color: Colors.black38, fontSize: 13),
                          ),
                          style: const TextStyle(color: Colors.black87),
                          dropdownColor: Colors.white,
                          decoration: _buildInputDecoration("Batch / Angkatan", Icons.group_outlined),
                          items: _batches.map((b) {
                            return DropdownMenuItem<int>(
                              value: b['id'] as int,
                              child: Text(
                                (b['name'] ?? b['title'] ?? 'Batch ${b['id']}') as String,
                                style: const TextStyle(color: Colors.black87, fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedBatchId = val;
                            });
                          },
                          validator: (val) => val == null ? "Batch harus dipilih" : null,
                        ),
                        const SizedBox(height: 32),

                        // Register Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: const Color(0xFF6C63FF).withOpacity(0.2),
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
                                  "Daftar",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Back to Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Sudah punya akun? ",
                              style: TextStyle(color: Colors.black.withOpacity(0.6)),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                "Masuk Di Sini",
                                style: TextStyle(
                                  color: Color(0xFF8B7EFE),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
      prefixIcon: Icon(icon, color: Colors.black.withOpacity(0.5)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF8B7EFE), width: 1.5),
      ),
    );
  }
}
