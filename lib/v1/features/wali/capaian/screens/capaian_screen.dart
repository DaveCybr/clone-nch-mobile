import 'package:flutter/material.dart';

class CapaianSiswaScreen extends StatefulWidget {
  const CapaianSiswaScreen({super.key});

  @override
  _CapaianSiswaScreenState createState() => _CapaianSiswaScreenState();
}

class _CapaianSiswaScreenState extends State<CapaianSiswaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF5),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Profil Siswa
                      _buildStudentProfile(),
                      
                      const SizedBox(height: 24),
                      
                      // Grid Capaian
                      _buildCapaianGrid(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      color: const Color(0xFFF0FFF5),
      padding: const EdgeInsets.only(right: 16, left: 16, top: 16, bottom: 30),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFA1EEC3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: const Color(0xFFF0FFF5),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              'Capaian Siswa',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: const Color(0xFF0F7836),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentProfile() {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: AssetImage('assets/profile.jpg'),
        ),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFA1EEC3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fuad Adhim Al Hasan',
                style: TextStyle(
                  color: const Color(0xFF0F7836),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.open_in_new,
                  color: const Color(0xFF0F7836),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'A1231233 • Kelas A-1',
          style: TextStyle(
            color: const Color(0xFF0F7836).withOpacity(0.7),
          ),
        ),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone,
                color: Colors.white,
                size: 8,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Walimurid Ibunda Andriana',
              style: TextStyle(
                color: const Color(0xFF0F7836).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCapaianGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = (constraints.maxWidth - 16) / 2;
        double cardHeight = cardWidth; // Persegi

        return Column(
          children: [
            Row(
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight * 1.5,
                      child: CapaianCard(
                        icon: Icons.fact_check,
                        valueText: '23/32',
                        subLabel: 'Kehadiran',
                        title: 'Presensi',
                        width: cardWidth,
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: CapaianCard(
                        icon: Icons.payment,
                        valueText: 'Lunas',
                        subLabel: 'Status',
                        title: 'Tagihan',
                        width: cardWidth,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    SizedBox(
                      width: cardWidth,
                      height: cardWidth,
                      child: CapaianCard(
                        icon: Icons.assignment,
                        valueText: '95',
                        subLabel: 'Nilai Rata-rata',
                        title: 'Tugas',
                        width: cardWidth,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: cardWidth,
                      height: cardWidth,
                      child: CapaianCard(
                        icon: Icons.school,
                        valueText: '85',
                        subLabel: 'Nilai Rata-rata',
                        title: 'Ujian',
                        width: cardWidth,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight * 0.5,
                      child: CapaianCard(
                        icon: Icons.person,
                        valueText: 'Profil Selengkapnya',
                        subLabel: '',
                        title: '',
                        width: cardWidth,
                        isProfileMore: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class CapaianCard extends StatelessWidget {
  final IconData icon;
  final String valueText;
  final String subLabel;
  final String title;
  final double? width;
  final bool isProfileMore;

  const CapaianCard({
    super.key,
    required this.icon,
    required this.valueText,
    required this.subLabel,
    required this.title,
    this.width,
    this.isProfileMore = false,
  });

  void _showCapaianDetailBottomSheet(BuildContext context) {
    if (isProfileMore) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: const Color(0xFF0F7836),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              if (title == 'Presensi')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Berikut merupakan rekapan seluruh presensi',
                    style: TextStyle(
                      color: const Color(0xFF0F7836).withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (title == 'Presensi')
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPresensiItem('14', 'Hadir'),
                      _buildPresensiItem('3', 'Izin'),
                      _buildPresensiItem('5', 'Sakit'),
                      _buildPresensiItem('1', 'Alfa'),
                      _buildPresensiItem('32', 'Total'),
                    ],
                  ),
                ),

              if (title == 'Presensi')
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildPresensiDetailCard(
                          matkul: index == 0 
                            ? 'Matematika Dasar' 
                            : index == 1 
                              ? 'Bahasa Indonesia' 
                              : 'Pendidikan Agama',
                          pertemuan: 'Pertemuan ${index + 1}',
                          guru: 'Ibu Guru Rita',
                          tanggal: '12 Januari, 09:30',
                          status: 'Hadir',
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresensiDetailCard({
    required String matkul,
    required String pertemuan,
    required String guru,
    required String tanggal,
    required String status,
  }) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0F7836)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F7836),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  matkul,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  pertemuan,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guru),
                    Text(
                      tanggal,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F7836),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresensiItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF0F7836),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isProfileMore) {
      return Container(
        width: width ?? 150,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
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
        child: Center(
          child: Text(
            valueText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF0F7836),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showCapaianDetailBottomSheet(context),
      child: Container(
        width: width ?? 150,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
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
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Icon(
                icon,
                color: const Color(0xFF0F7836),
                size: 24,
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F7836),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                valueText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subLabel,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F7836),
                  fontSize: 18,
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