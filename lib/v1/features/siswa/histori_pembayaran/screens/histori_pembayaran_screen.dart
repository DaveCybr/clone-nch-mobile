import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class HistoriPembayaranScreen extends StatefulWidget {
  const HistoriPembayaranScreen({super.key});

  @override
  State<HistoriPembayaranScreen> createState() =>
      _HistoriPembayaranScreenState();
}

class _HistoriPembayaranScreenState extends State<HistoriPembayaranScreen> {
  final PaymentService _paymentService = PaymentService();
  List<PaymentModel> _paymentList = [];
  Map<String, dynamic> _paymentSummary = {};
  bool _isLoading = true;
  String? _studentId;
  String? _errorMessage;
  String _filterType = 'ALL'; // ALL, INCOME, EXPENSE

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _studentId = prefs.getString('student_id_uuid');

      print('📊 Loading payment history for student: $_studentId');

      await _fetchPaymentData();
    } catch (e) {
      print('❌ Error loading student data: $e');
      setState(() {
        _errorMessage = 'Gagal memuat data siswa: $e';
        _paymentList = [];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchPaymentData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final paymentList = await _paymentService.getStudentPaymentHistory();
      final summary = await _paymentService.getPaymentSummary();

      setState(() {
        _paymentList = paymentList;
        _paymentSummary = summary;
      });
    } catch (e) {
      print('❌ Error fetching payment data: $e');
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _paymentList = [];
        _paymentSummary = {};
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<PaymentModel> get _filteredPayments {
    if (_filterType == 'ALL') return _paymentList;
    if (_filterType == 'INCOME')
      return _paymentList.where((p) => p.isIncome).toList();
    if (_filterType == 'EXPENSE')
      return _paymentList.where((p) => p.isExpense).toList();
    return _paymentList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF5),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar - mengikuti style teacher
            _buildCustomAppBar(),

            // Content
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0F7836),
                        ),
                      )
                      : _errorMessage != null
                      ? _buildErrorState()
                      : _paymentList.isEmpty
                      ? _buildEmptyState()
                      : _buildContentState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F7836).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F7836),
                size: 24,
              ),
            ),
          ),
          const Text(
            'Histori Pembayaran',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F7836),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F7836),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Siswa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return RefreshIndicator(
      onRefresh: _loadStudentData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.orange[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Informasi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _loadStudentData,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Coba Lagi',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F7836),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadStudentData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F7836).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.payment_outlined,
                      size: 64,
                      color: Color(0xFF0F7836),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum Ada Data Pembayaran',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Data histori pembayaran belum tersedia.\nTransaksi keuangan akan muncul di sini setelah ada aktivitas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _loadStudentData,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Periksa Ulang',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F7836),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentState() {
    return RefreshIndicator(
      onRefresh: _loadStudentData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info Card
            _buildStudentInfoCard(),
            const SizedBox(height: 16),

            // Summary Card
            _buildSummaryCard(),
            const SizedBox(height: 16),

            // Statistics Grid
            _buildStatisticsGrid(),
            const SizedBox(height: 16),

            // Filter Tabs
            _buildFilterTabs(),
            const SizedBox(height: 16),

            // Payment List
            _buildPaymentList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F7836).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF0F7836),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Histori Pembayaran Siswa',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _studentId != null
                          ? 'ID: ${_studentId!.substring(0, 8)}...'
                          : 'Tidak tersedia',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F7836),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F7836).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFF0F7836),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Menampilkan semua transaksi keuangan terkait dengan akun siswa',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF0F7836),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalIncome = _paymentSummary['totalIncome'] ?? 0.0;
    final totalExpense = _paymentSummary['totalExpense'] ?? 0.0;
    final netAmount = _paymentSummary['netAmount'] ?? 0.0;
    final totalTransactions = _paymentSummary['totalTransactions'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F7836), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Saldo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalTransactions transaksi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Rp ${netAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(
                netAmount >= 0 ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Pemasukan',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${totalIncome.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Pengeluaran',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${totalExpense.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    final incomeCount = _paymentSummary['incomeCount'] ?? 0;
    final expenseCount = _paymentSummary['expenseCount'] ?? 0;
    final totalTransactions = _paymentSummary['totalTransactions'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Transaksi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F7836),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                'Total',
                totalTransactions,
                const Color(0xFF0F7836),
                Icons.receipt_long,
              ),
              _buildStatItem(
                'Masuk',
                incomeCount,
                Colors.green,
                Icons.add_circle,
              ),
              _buildStatItem(
                'Keluar',
                expenseCount,
                Colors.red,
                Icons.remove_circle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 40,
      child: Row(
        children: [
          _buildFilterTab('ALL', 'Semua'),
          const SizedBox(width: 8),
          _buildFilterTab('INCOME', 'Pemasukan'),
          const SizedBox(width: 8),
          _buildFilterTab('EXPENSE', 'Pengeluaran'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String value, String label) {
    final isSelected = _filterType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterType = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F7836) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF0F7836), width: 1),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF0F7836),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentList() {
    final filteredPayments = _filteredPayments;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Transaksi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F7836),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F7836).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredPayments.length} records',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0F7836),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (filteredPayments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.payment_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak ada transaksi ${_filterType == 'ALL'
                          ? ''
                          : _filterType == 'INCOME'
                          ? 'pemasukan'
                          : 'pengeluaran'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredPayments.length,
              separatorBuilder:
                  (context, index) => Divider(
                    color: Colors.grey[200],
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
              itemBuilder: (context, index) {
                return _buildPaymentItem(filteredPayments[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(PaymentModel payment) {
    final dateTime = payment.dateTime;
    final dayName = dateTime != null ? _getDayName(dateTime.weekday) : '';
    final formattedDate =
        dateTime != null
            ? '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}'
            : payment.date;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Amount Circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getTypeColor(payment.type).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getTypeColor(payment.type).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                payment.typeEmoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Payment Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$dayName, $formattedDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (payment.category != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      payment.category!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payment.isIncome ? '+' : '-'} ${payment.formattedAmount}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getTypeColor(payment.type),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(payment.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  payment.typeDisplay,
                  style: TextStyle(
                    color: _getTypeColor(payment.type),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return weekday <= days.length ? days[weekday - 1] : '';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'INCOME':
        return const Color(0xFF0F7836);
      case 'EXPENSE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
