import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  final VoidCallback onOpenMataPelajaranSidebar;

  const CustomAppBar({
    super.key,
    required this.onOpenMataPelajaranSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 0, right: 0, bottom: 16),
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
          
          const Spacer(),

          Row(
            children: [
              GestureDetector(
                onTap: onOpenMataPelajaranSidebar,
                child: Text(
                  'Pelajaran Lain',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: const Color(0xFF0F7836),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onOpenMataPelajaranSidebar,
                child: Icon(
                  Icons.menu,
                  color: const Color(0xFF0F7836),
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 