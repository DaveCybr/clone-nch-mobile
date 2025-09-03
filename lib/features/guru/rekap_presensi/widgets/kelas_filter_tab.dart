import 'package:flutter/material.dart';

class KelasFilterTab extends StatefulWidget {
  final Function(int) onKelasSelected;

  const KelasFilterTab({
    super.key, 
    required this.onKelasSelected,
  });

  @override
  _KelasFilterTabState createState() => _KelasFilterTabState();
}

class _KelasFilterTabState extends State<KelasFilterTab> {
  int _selectedKelasIndex = 0;

  final List<String> _kelasList = ['Semua', 'Kelas 1', 'Kelas 2', 'Kelas 3'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _kelasList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedKelasIndex = index;
                });
                widget.onKelasSelected(index);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedKelasIndex == index 
                  ? const Color(0xFFF6C945) 
                  : Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: Text(
                _kelasList[index],
                style: TextStyle(
                  color: _selectedKelasIndex == index 
                    ? Colors.white 
                    : const Color(0xFF0F7836),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 