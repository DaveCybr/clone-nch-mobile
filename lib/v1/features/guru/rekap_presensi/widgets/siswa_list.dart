import 'package:flutter/material.dart';

class SiswaList extends StatelessWidget {
  final List<Map<String, dynamic>> siswaList;
  final bool semuaTerabsensi;
  final String searchQuery;

  const SiswaList({
    super.key,
    required this.siswaList,
    this.semuaTerabsensi = false,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final filteredSiswaList = siswaList.where((siswa) {
      final matchesSearch = siswa['nama'].toLowerCase().contains(searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: filteredSiswaList.map((siswa) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      siswa['nama'],
                      style: const TextStyle(
                        color: Color(0xFF0F7836),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIS: ${siswa['nis']}',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelas: ${siswa['kelas']}',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(siswa['status']),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    siswa['status'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hadir':
        return Colors.green;
      case 'Izin':
        return Colors.yellow[700]!;
      case 'Alfa':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 