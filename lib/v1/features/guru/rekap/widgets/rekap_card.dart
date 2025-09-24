import 'package:flutter/material.dart';

class RekapCard extends StatelessWidget {
  final String value;
  final String label;
  final String type;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isDisabled;
  final String? comingSoonLabel;

  const RekapCard({
    super.key,
    required this.value,
    required this.label,
    required this.type,
    this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
    this.comingSoonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey[100] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDisabled ? 0.05 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Tampilkan loading indicator atau nilai
              isLoading
                  ? SizedBox(
                    height: 60,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: const Color(0xFF0F7836),
                        strokeWidth: 3,
                      ),
                    ),
                  )
                  : ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        colors:
                            isDisabled
                                ? [Colors.grey, Colors.grey]
                                : [
                                  const Color(0xFF0F7836),
                                  const Color(0xFFB4CE46),
                                ],
                      ).createShader(bounds);
                    },
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDisabled ? Colors.grey : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              // Tampilkan "Coming Soon" label jika card disabled
              if (isDisabled && comingSoonLabel != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(
                    comingSoonLabel!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
