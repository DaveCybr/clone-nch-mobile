import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key, 
    required this.currentIndex, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none, // Memungkinkan overflow
      children: [
        // Lapisan Gradasi Baru
        Positioned(
          left: 0,
          right: 0,
          bottom: -50, // Geser ke bawah untuk melebihi kontainer
          child: Container(
            height: 230, // Tinggi lebih besar
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF0F7836).withOpacity(1), // Hijau tua
                  const Color(0xFF0F7836).withOpacity(0.5), // Hijau muda
                  Colors.white.withOpacity(0), // Putih transparan
                ],
                stops: [0.0, 0.6, 1.0], 
              ),
            ),
          ),
        ),
        
        // BottomAppBar Asli
        BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 10.0,
          color: Colors.white,
          elevation: 10,
          shadowColor: Colors.black26,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 45.0), // Tambahkan padding horizontal
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol Beranda
                _buildNavItem(
                  icon: Icons.home,
                  label: 'Beranda',
                  index: 0,
                  context: context,
                ),

                // Tombol Keluar
                _buildNavItem(
                  icon: Icons.logout,
                  label: 'Keluar',
                  index: 1,
                  context: context,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required BuildContext context,
  }) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected 
              ? const Color(0xFF0F7836) 
              : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected 
                ? const Color(0xFF0F7836) 
                : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected 
                ? FontWeight.bold 
                : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomFloatingActionButton({
    super.key, 
    required this.onPressed
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F7836),
      elevation: 6,
      highlightElevation: 12,
      shape: const CircleBorder(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      child: const Icon(
        Icons.send_rounded,
        size: 28, // Sedikit lebih besar dari ukuran standar
      ),
    );
  }
} 