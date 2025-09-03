import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/daftar_siswa_controller.dart';
import '../models/daftar_siswa_model.dart';

class DaftarSiswaScreen extends StatefulWidget {
  final DaftarSiswaController? controller;

  const DaftarSiswaScreen({super.key, this.controller});

  @override
  State<DaftarSiswaScreen> createState() => _DaftarSiswaScreenState();
}

class _DaftarSiswaScreenState extends State<DaftarSiswaScreen> {
  late DaftarSiswaController _controller;

  @override
  void initState() {
    super.initState();

    // Inisialisasi controller sekali saja di initState
    _controller = widget.controller ?? DaftarSiswaController();

    // Initialize data setelah widget di-build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.isInitialized && !_controller.isLoading) {
        _controller.initialize();
      }
    });
  }

  @override
  void dispose() {
    // Hanya dispose jika controller dibuat di sini (bukan dari parent)
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DaftarSiswaController>.value(
      value: _controller,
      child: Consumer<DaftarSiswaController>(
        builder: (context, studentController, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF0FFF5),
            body: SafeArea(child: _buildBody(studentController)),
          );
        },
      ),
    );
  }

  Widget _buildBody(DaftarSiswaController studentController) {
    // Loading state
    if (studentController.isLoading && !studentController.isInitialized) {
      return _buildLoadingScreen();
    }

    // Error state
    if (studentController.errorMessage != null &&
        !studentController.isInitialized) {
      return _buildErrorScreen(studentController);
    }

    // Main content
    return RefreshIndicator(
      onRefresh: () => studentController.refresh(),
      color: const Color(0xFF0F7836),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCustomAppBar(context),
              const SizedBox(height: 24),
              _buildFilterCard(studentController),
              const SizedBox(height: 24),
              _buildStudentListHeader(studentController),
              const SizedBox(height: 16),
              _buildStudentList(studentController),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF0F7836)),
          const SizedBox(height: 16),
          const Text(
            'Memuat data siswa...',
            style: TextStyle(color: Color(0xFF0F7836), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(DaftarSiswaController studentController) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Terjadi kesalahan:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              studentController.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.red[700]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => studentController.refresh(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F7836),
            ),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFA1EEC3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFF0FFF5),
                size: 24,
              ),
            ),
          ),
          const Text(
            'Daftar Siswa',
            style: TextStyle(
              color: Color(0xFF0F7836),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40), // Spacer untuk keseimbangan
        ],
      ),
    );
  }

  Widget _buildFilterCard(DaftarSiswaController studentController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Kelas',
                style: TextStyle(
                  color: Color(0xFF0F7836),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F7836).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total: ${studentController.totalStudentsCount}',
                  style: const TextStyle(
                    color: Color(0xFF0F7836),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildKelasFilterTab(studentController),
        ],
      ),
    );
  }

  Widget _buildKelasFilterTab(DaftarSiswaController studentController) {
    if (studentController.kelasList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'Tidak ada kelas yang diajar',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            studentController.kelasList.map((kelas) {
              bool isSelected = studentController.selectedKelas == kelas;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: () {
                    studentController.selectKelas(kelas);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSelected ? const Color(0xFF0F7836) : Colors.white,
                    side: const BorderSide(color: Color(0xFF0F7836), width: 2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        kelas,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Colors.white
                                  : const Color(0xFF0F7836),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : const Color(0xFF0F7836).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${studentController.getStudentsCountForKelas(kelas)}',
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : const Color(0xFF0F7836),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildStudentListHeader(DaftarSiswaController studentController) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Daftar Siswa',
          style: TextStyle(
            color: Color(0xFF0F7836),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (studentController.selectedKelas != null)
          Text(
            '${studentController.students.length} siswa',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
      ],
    );
  }

  Widget _buildStudentList(DaftarSiswaController studentController) {
    // Show loading indicator for refresh
    if (studentController.isLoading && studentController.isInitialized) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: Color(0xFF0F7836)),
        ),
      );
    }

    if (studentController.students.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada siswa di kelas ini',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan kelas sudah memiliki siswa yang terdaftar',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: studentController.students.length,
      itemBuilder: (context, index) {
        final student = studentController.students[index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(DaftarSiswaModel student) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF0F7836).withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar dengan inisial nama
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF0F7836),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info siswa
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F7836),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIM: ${student.nim}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelas: ${student.kelasName}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  if (student.generation > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Angkatan: ${student.generation}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F7836).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Aktif',
                style: TextStyle(
                  color: Color(0xFF0F7836),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
