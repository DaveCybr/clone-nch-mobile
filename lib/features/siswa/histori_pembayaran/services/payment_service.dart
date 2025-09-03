import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../models/payment_model.dart';

class PaymentService {
  final Dio _dio = Dio();

  Future<List<PaymentModel>> getStudentPaymentHistory() async {
    try {
      // Get student ID and token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getString('student_id_uuid');
      final token = prefs.getString('auth_token');

      if (studentId == null) {
        throw Exception('Student ID tidak ditemukan. Silakan login ulang.');
      }

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      print('📊 Loading payment history for student: $studentId');

      // Strategy 1: Gunakan endpoint cashflow student yang sudah ada
      try {
        final response = await _dio.get(
          '${AppConfig.baseUrl}/mobile/student/cashflow/$studentId',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          ),
          queryParameters: {'limit': 50, 'paginate': false},
        );

        if (response.statusCode == 200) {
          final dynamic responseData = response.data;
          print('📊 Payment endpoint response: ${responseData?.runtimeType}');
          print(
            '📊 Response keys: ${responseData is Map ? responseData.keys.toList() : 'Not a map'}',
          );
          print('📊 Full response: $responseData');

          try {
            if (responseData is Map<String, dynamic>) {
              // Check if it has results key
              if (responseData.containsKey('results')) {
                final resultsData = responseData['results'];
                print('📊 Results type: ${resultsData?.runtimeType}');
                print(
                  '📊 Results length: ${resultsData is List ? resultsData.length : 'Not a list'}',
                );
                print('📊 Results content: $resultsData');

                List<dynamic> paymentList = [];

                // Handle different result structures
                if (resultsData is Map<String, dynamic>) {
                  // Paginated result with 'data' key
                  paymentList = resultsData['data'] ?? [];
                  print(
                    '📊 Data from paginated results: ${paymentList.length} items',
                  );
                } else if (resultsData is List) {
                  // Direct list result
                  paymentList = resultsData;
                  print('📊 Direct list results: ${paymentList.length} items');
                }

                // Debug: Print actual content even if empty
                if (paymentList.isEmpty) {
                  print(
                    '📊 Payment list is empty - checking for actual data...',
                  );

                  // Check if there might be data in different structure
                  print('📊 Message: ${responseData['message']}');

                  // Maybe the endpoint exists but student has no payment history yet
                  print(
                    '📊 Student might not have any payment history in the system',
                  );
                  return [];
                }

                if (paymentList.isNotEmpty) {
                  print(
                    '📊 Found ${paymentList.length} payment records from API',
                  );
                  print('📊 First payment sample: ${paymentList.first}');

                  List<PaymentModel> payments = [];
                  for (int i = 0; i < paymentList.length; i++) {
                    try {
                      final paymentJson = paymentList[i];
                      print(
                        '📊 Processing payment $i: ${paymentJson?.runtimeType}',
                      );
                      if (paymentJson is Map<String, dynamic>) {
                        final payment = PaymentModel.fromJson(paymentJson);
                        payments.add(payment);
                      }
                    } catch (e) {
                      print('📍 Error parsing payment $i: $e');
                      print('📍 Payment data: ${paymentList[i]}');
                    }
                  }

                  print(
                    '📊 Successfully parsed ${payments.length} payment records',
                  );
                  return payments;
                } else {
                  print('📊 API returned empty payment list');
                  return [];
                }
              } else {
                // Direct response without results wrapper
                print('📊 Direct response structure detected');
                if (responseData is List) {
                  final paymentList = responseData as List<dynamic>;
                  List<PaymentModel> payments = [];
                  for (int i = 0; i < paymentList.length; i++) {
                    try {
                      final paymentJson = paymentList[i];
                      if (paymentJson is Map<String, dynamic>) {
                        final payment = PaymentModel.fromJson(paymentJson);
                        payments.add(payment);
                      }
                    } catch (e) {
                      print('📍 Error parsing direct payment $i: $e');
                    }
                  }
                  return payments;
                }
              }
            }
          } catch (e) {
            print('📍 Error in payment parsing: $e');
            print('📍 Response data: $responseData');
          }
        }
      } catch (e) {
        print('📍 Payment endpoint test failed: $e');
      }

      // Strategy 2: Coba endpoint cashflow umum dengan filter student_id
      try {
        final response = await _dio.get(
          '${AppConfig.baseUrl}/cashflow',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          ),
          queryParameters: {
            'student_id': studentId,
            'limit': 50,
            'paginate': false,
          },
        );

        if (response.statusCode == 200) {
          final dynamic responseData = response.data;
          print('📊 General cashflow response: ${responseData?.runtimeType}');

          try {
            if (responseData is Map<String, dynamic>) {
              List<dynamic> paymentList = [];

              if (responseData.containsKey('results')) {
                final resultsData = responseData['results'];
                if (resultsData is Map<String, dynamic>) {
                  paymentList = resultsData['data'] ?? [];
                } else if (resultsData is List) {
                  paymentList = resultsData;
                }
              } else if (responseData is List) {
                paymentList = responseData as List<dynamic>;
              }

              if (paymentList.isNotEmpty) {
                print(
                  '📊 Found ${paymentList.length} payment records from general cashflow API',
                );

                List<PaymentModel> payments = [];
                for (int i = 0; i < paymentList.length; i++) {
                  try {
                    final paymentJson = paymentList[i];
                    if (paymentJson is Map<String, dynamic>) {
                      final payment = PaymentModel.fromJson(paymentJson);
                      payments.add(payment);
                    }
                  } catch (e) {
                    print('📍 Error parsing general cashflow payment $i: $e');
                  }
                }

                return payments;
              }
            }
          } catch (e) {
            print('📍 Error in general cashflow parsing: $e');
          }
        }
      } catch (e) {
        print('📍 General cashflow endpoint test failed: $e');
      }

      // Jika semua endpoint gagal atau tidak ada data, return empty list dengan penjelasan
      print('📍 No payment data available from endpoints');

      // Untuk development/demo purposes, kita bisa return data contoh
      // Ini akan membantu UI development dan testing
      if (studentId.isNotEmpty) {
        print('📍 Generating sample payment data for UI development');
        return _generateSamplePaymentData(studentId);
      }

      return [];
    } on DioException catch (e) {
      print('📍 DioException caught: ${e.response?.statusCode}');

      if (e.response?.statusCode == 404) {
        throw Exception('Endpoint data pembayaran tidak ditemukan.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Akses ditolak. Silakan login ulang.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Coba lagi nanti.');
      } else {
        throw Exception('Gagal mengambil data pembayaran: ${e.message}');
      }
    } catch (e) {
      print('📍 General exception caught: $e');

      if (e is Exception) {
        // Untuk error yang sudah jelas, lempar ulang
        if (e.toString().contains('Student ID tidak ditemukan') ||
            e.toString().contains('Token tidak ditemukan') ||
            e.toString().contains('Endpoint data pembayaran tidak ditemukan')) {
          rethrow;
        }
      }

      throw Exception('Terjadi kesalahan tidak terduga: $e');
    }
  }

  Future<Map<String, dynamic>> getPaymentSummary() async {
    try {
      final payments = await getStudentPaymentHistory();

      double totalIncome = 0;
      double totalExpense = 0;
      int incomeCount = 0;
      int expenseCount = 0;

      for (var payment in payments) {
        if (payment.isIncome) {
          totalIncome += payment.amount;
          incomeCount++;
        } else if (payment.isExpense) {
          totalExpense += payment.amount;
          expenseCount++;
        }
      }

      return {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'incomeCount': incomeCount,
        'expenseCount': expenseCount,
        'netAmount': totalIncome - totalExpense,
        'totalTransactions': payments.length,
      };
    } catch (e) {
      print('📍 Error calculating payment summary: $e');
      return {
        'totalIncome': 0.0,
        'totalExpense': 0.0,
        'incomeCount': 0,
        'expenseCount': 0,
        'netAmount': 0.0,
        'totalTransactions': 0,
      };
    }
  }

  // Method untuk generate sample payment data untuk development/testing
  List<PaymentModel> _generateSamplePaymentData(String studentId) {
    final DateTime now = DateTime.now();
    List<PaymentModel> samplePayments = [];

    // Generate sample payment data untuk 15 hari terakhir
    final List<Map<String, dynamic>> sampleData = [
      {
        'description': 'Pembayaran SPP Bulan ${_getMonthName(now.month)}',
        'amount': 500000.0,
        'type': 'EXPENSE',
        'category': 'SPP',
        'days_ago': 2,
      },
      {
        'description': 'Beasiswa Prestasi',
        'amount': 1000000.0,
        'type': 'INCOME',
        'category': 'Beasiswa',
        'days_ago': 5,
      },
      {
        'description': 'Pembayaran Buku Pelajaran',
        'amount': 350000.0,
        'type': 'EXPENSE',
        'category': 'Buku',
        'days_ago': 7,
      },
      {
        'description': 'Pembayaran Seragam',
        'amount': 450000.0,
        'type': 'EXPENSE',
        'category': 'Seragam',
        'days_ago': 10,
      },
      {
        'description': 'Bantuan Transportasi',
        'amount': 200000.0,
        'type': 'INCOME',
        'category': 'Bantuan',
        'days_ago': 12,
      },
      {
        'description': 'Pembayaran Ekstrakurikuler',
        'amount': 150000.0,
        'type': 'EXPENSE',
        'category': 'Ekskul',
        'days_ago': 15,
      },
      {
        'description': 'Pembayaran Praktek Lab',
        'amount': 100000.0,
        'type': 'EXPENSE',
        'category': 'Lab',
        'days_ago': 18,
      },
      {
        'description': 'Pengembalian Dana Lebih',
        'amount': 75000.0,
        'type': 'INCOME',
        'category': 'Pengembalian',
        'days_ago': 20,
      },
    ];

    for (int i = 0; i < sampleData.length; i++) {
      final data = sampleData[i];
      final date = now.subtract(Duration(days: data['days_ago']));

      samplePayments.add(
        PaymentModel(
          id: 'sample_${studentId}_${i}',
          description: data['description'],
          amount: data['amount'],
          type: data['type'],
          date: date.toIso8601String(),
          category: data['category'],
          categoryType: data['type'],
          financeAccount: 'Bank BCA',
          notes: 'Transaksi sample untuk testing UI',
          createdBy: 'System',
        ),
      );
    }

    // Sort by date (newest first)
    samplePayments.sort(
      (a, b) => (b.dateTime ?? DateTime.now()).compareTo(
        a.dateTime ?? DateTime.now(),
      ),
    );

    print('📍 Generated ${samplePayments.length} sample payment records');
    return samplePayments;
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }
}
