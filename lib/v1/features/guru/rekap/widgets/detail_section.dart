import 'package:flutter/material.dart';
import '../../rekap_presensi/screens/rekap_presensi_screen.dart';

class DetailSection extends StatelessWidget {
  final String selectedDetailType;
  final String selectedMataPelajaran;

  const DetailSection({
    super.key,
    required this.selectedDetailType,
    required this.selectedMataPelajaran,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedDetailType) {
      case 'tugas':
        return _buildTugasDetail();
      case 'presensi':
        return _buildPresensiDetail(context);
      case 'ujian':
        return Container();
      default:
        return Container();
    }
  }

  Widget _buildTugasDetail() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildSearchBar('Cari Tugas...'),
        const SizedBox(height: 16),
        _buildTugasItem('Pertemuan 1', 'Aritmatika Dasar', '24/32 siswa'),
        _buildTugasItem('Pertemuan 1', 'Geometri Dasar', '24/32 siswa'),
        _buildTugasItem('Pertemuan 2', 'Variabel Berpangkat', '24/32 siswa'),
      ],
    );
  }

  Widget _buildPresensiDetail(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildSearchBar('Cari Presensi...'),
        const SizedBox(height: 16),
        _buildPresensiItem(context, 'Pertemuan 1', 'Matematika', '24/32 siswa'),
        _buildPresensiItem(context, 'Pertemuan 2', 'Bahasa Indonesia', '22/32 siswa'),
        _buildPresensiItem(context, 'Pertemuan 3', 'Pendidikan Agama', '30/32 siswa'),
      ],
    );
  }

  Widget _buildSearchBar(String hintText) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0F7836), width: 1),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: const Color(0xFF0F7836)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTugasItem(String pertemuan, String materi, String progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0F7836)),
      ),
      child: ListTile(
        title: Text(
          pertemuan,
          style: TextStyle(
            color: const Color(0xFF0F7836),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          materi,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F7836),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Selengkapnya',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresensiItem(BuildContext context, String pertemuan, String mapel, String progress) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => const RekapPresensiPage()
          )
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0F7836)),
        ),
        child: ListTile(
          title: Text(
            pertemuan,
            style: TextStyle(
              color: const Color(0xFF0F7836),
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            mapel,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F7836),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Selengkapnya',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 