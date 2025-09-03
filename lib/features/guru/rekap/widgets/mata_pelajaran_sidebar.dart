import 'package:flutter/material.dart';
import '../controllers/rekap_controller.dart';

class MataPelajaranSidebar extends StatelessWidget {
  final Function(String) onMataPelajaranSelected;
  final RekapController controller;

  const MataPelajaranSidebar({
    super.key,
    required this.onMataPelajaranSelected,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8FFF2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 100, bottom: 16),
            child: Text(
              'Pilih Mata Pelajaran',
              style: TextStyle(
                color: const Color(0xFF0F7836),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          if (controller.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF0F7836)),
              ),
            )
          else if (controller.errorMessage != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    controller.errorMessage!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _buildMataPelajaranList(context),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildMataPelajaranList(BuildContext context) {
    final mataPelajaranList = controller.subjectDisplayNames;

    if (mataPelajaranList.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Tidak ada mata pelajaran tersedia',
            style: TextStyle(
              color: const Color(0xFF0F7836),
              fontSize: 16,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }

    return mataPelajaranList.map((mapel) {
      final isSelected = mapel == controller.selectedMataPelajaran;

      return Column(
        children: [
          Material(
            color:
                isSelected
                    ? const Color(0xFF0F7836).withOpacity(0.1)
                    : Colors.transparent,
            child: InkWell(
              onTap: () {
                onMataPelajaranSelected(mapel);
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Text(
                  mapel,
                  style: TextStyle(
                    color:
                        isSelected
                            ? const Color(0xFF0F7836)
                            : const Color(0xFF0F7836).withOpacity(0.8),
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const Divider(
            color: Color(0xFF0F7836),
            thickness: 0.5,
            indent: 16,
            endIndent: 16,
          ),
        ],
      );
    }).toList();
  }
}
