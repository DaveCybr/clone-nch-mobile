import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../daftar_siswa/screens/daftar_siswa_screen.dart';
import '../../rekap/screens/rekap_screen.dart';

class MenuGrid extends StatelessWidget {
  final BuildContext context;

  const MenuGrid({super.key, required this.context});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _buildMenuButton(
            icon: CupertinoIcons.person_3_fill,
            label: 'Daftar Siswa',
          ),
          const SizedBox(width: 16),
          _buildMenuButton(icon: CupertinoIcons.mail, label: 'Pengumuman'),
          const SizedBox(width: 16),
          _buildMenuButton(icon: CupertinoIcons.doc_text_fill, label: 'Rekap'),
        ],
      ),
    );
  }

  Widget _buildMenuButton({required IconData icon, required String label}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          switch (label) {
            case 'Daftar Siswa':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DaftarSiswaScreen(),
                ),
              );
              break;
            case 'Pengumuman':
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Halaman Pengumuman sedang dikembangkan'),
                  duration: Duration(seconds: 2),
                ),
              );
              break;
            case 'Rekap':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RekapScreen()),
              );
              break;
          }
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF0F7836)),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF0F7836), size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF0F7836),
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width * 0.03,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
