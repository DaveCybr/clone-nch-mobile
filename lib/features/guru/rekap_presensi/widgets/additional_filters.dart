import 'package:flutter/material.dart';

class AdditionalFilters extends StatefulWidget {
  final Function(bool) onSemuaTerabsensiChanged;
  final Function(String) onSearchChanged;

  const AdditionalFilters({
    super.key,
    required this.onSemuaTerabsensiChanged,
    required this.onSearchChanged,
  });

  @override
  _AdditionalFiltersState createState() => _AdditionalFiltersState();
}

class _AdditionalFiltersState extends State<AdditionalFilters> {
  bool _semuaTerabsensi = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          // ElevatedButton(
          //   onPressed: () {
          //   },
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: Colors.white,
          //     side: const BorderSide(color: Color(0xFFF6C945), width: 2),
          //     shape: const StadiumBorder(),
          //     padding: const EdgeInsets.symmetric(vertical: 12),
          //   ),
          //   child: const Center(
          //     child: Text(
          //       'Semua Status',
          //       style: TextStyle(
          //         color: Color(0xFFF6C945),
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 16),

          // // Row(
          // //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // //   children: [
          // //     const Text(
          // //       'Semua Terabsensi',
          // //       style: TextStyle(
          // //         color: Color(0xFF0F7836),
          // //         fontWeight: FontWeight.bold,
          // //       ),
          // //     ),
          // //     Switch(
          // //       value: _semuaTerabsensi,
          // //       onChanged: (bool value) {
          // //         setState(() {
          // //           _semuaTerabsensi = value;
          // //         });
          // //         widget.onSemuaTerabsensiChanged(value);
          // //       },
          // //       activeColor: const Color(0xFF0F7836),
          // //     ),
          // //   ],
          // // ),
          // const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari Siswa...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF0F7836)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFA1EEC3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFA1EEC3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF0F7836),
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              widget.onSearchChanged(value);
            },
          ),
        ],
      ),
    );
  }
}
