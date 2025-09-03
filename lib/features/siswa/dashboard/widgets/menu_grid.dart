import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../rekap_kehadiran/screens/rekap_kehadiran_screen.dart';
import '../../histori_pembayaran/screens/histori_pembayaran_screen.dart';

class MenuGridSiswa extends StatelessWidget {
  const MenuGridSiswa({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _buildMenuButton(
            context: context,
            icon: CupertinoIcons.person_3_fill,
            label: 'Rekap Kehadiran',
          ),
          const SizedBox(width: 16),
          _buildMenuButton(
            context: context,
            icon: CupertinoIcons.mail,
            label: 'Pengumuman',
          ),
          const SizedBox(width: 16),
          _buildMenuButton(
            context: context,
            icon: CupertinoIcons.money_dollar_circle,
            label: 'Histori Pembayaran',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          switch (label) {
            case 'Rekap Kehadiran':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RekapKehadiranScreen(),
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
            case 'Histori Pembayaran':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoriPembayaranScreen(),
                ),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF0F7836), size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0F7836),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
