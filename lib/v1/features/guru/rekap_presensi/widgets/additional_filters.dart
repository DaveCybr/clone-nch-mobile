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
