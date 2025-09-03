import 'package:flutter/material.dart';

class AnnouncementBanner extends StatelessWidget {
  final VoidCallback onClose;

  const AnnouncementBanner({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF0F7836),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF0F7836),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Dimohon Bapak/Ibu Guru untuk datang ke rapat koordinasi...',
                  style: TextStyle(
                    color: Color(0xFF0F7836),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Color(0xFF0F7836),
                  size: 20,
                ),
                onPressed: onClose,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 