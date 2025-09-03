class PaymentModel {
  final String id;
  final String description;
  final double amount;
  final String type; // INCOME or EXPENSE
  final String date;
  final String? category;
  final String? categoryType;
  final String? financeAccount;
  final String? notes;
  final String? createdBy;

  PaymentModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    this.category,
    this.categoryType,
    this.financeAccount,
    this.notes,
    this.createdBy,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    try {
      return PaymentModel(
        id: _safeStringParse(json['id']) ?? '',
        description: _safeStringParse(json['description']) ?? 'Transaksi',
        amount: _parseAmount(json['amount']),
        type:
            _safeStringParse(json['cashflow_category']?['type']) ??
            _safeStringParse(json['type']) ??
            'EXPENSE',
        date:
            _safeStringParse(json['created_at']) ??
            _safeStringParse(json['date']) ??
            DateTime.now().toIso8601String(),
        category: _safeStringParse(json['cashflow_category']?['name']),
        categoryType: _safeStringParse(json['cashflow_category']?['type']),
        financeAccount: _safeStringParse(json['finance_account']?['name']),
        notes: _safeStringParse(json['notes']),
        createdBy: _safeStringParse(json['created_by']?['name']),
      );
    } catch (e) {
      print('📍 Error parsing PaymentModel: $e');
      print('📍 JSON data: $json');
      // Return default model if parsing fails
      return PaymentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: 'Transaksi Error',
        amount: 0.0,
        type: 'EXPENSE',
        date: DateTime.now().toIso8601String(),
      );
    }
  }

  static String? _safeStringParse(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static double _parseAmount(dynamic amount) {
    try {
      if (amount == null) return 0.0;
      if (amount is double) return amount;
      if (amount is int) return amount.toDouble();
      if (amount is String) {
        // Remove common formatting characters
        String cleanAmount = amount.replaceAll(RegExp(r'[^\d.-]'), '');
        return double.tryParse(cleanAmount) ?? 0.0;
      }
      // Try to convert other types to string first
      String stringAmount = amount.toString().replaceAll(
        RegExp(r'[^\d.-]'),
        '',
      );
      return double.tryParse(stringAmount) ?? 0.0;
    } catch (e) {
      print('📍 Error parsing amount: $e for value: $amount');
      return 0.0;
    }
  }

  // Helper methods for display
  String get typeDisplay {
    switch (type.toUpperCase()) {
      case 'INCOME':
        return 'Pemasukan';
      case 'EXPENSE':
        return 'Pengeluaran';
      default:
        return type;
    }
  }

  String get typeEmoji {
    switch (type.toUpperCase()) {
      case 'INCOME':
        return '💰';
      case 'EXPENSE':
        return '💸';
      default:
        return '💱';
    }
  }

  DateTime? get dateTime {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return null;
    }
  }

  String get formattedAmount {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  bool get isIncome => type.toUpperCase() == 'INCOME';
  bool get isExpense => type.toUpperCase() == 'EXPENSE';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type,
      'date': date,
      'category': category,
      'categoryType': categoryType,
      'financeAccount': financeAccount,
      'notes': notes,
      'createdBy': createdBy,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? description,
    double? amount,
    String? type,
    String? date,
    String? category,
    String? categoryType,
    String? financeAccount,
    String? notes,
    String? createdBy,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      category: category ?? this.category,
      categoryType: categoryType ?? this.categoryType,
      financeAccount: financeAccount ?? this.financeAccount,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  String toString() {
    return 'PaymentModel(id: $id, description: $description, amount: $amount, type: $type, date: $date, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaymentModel &&
        other.id == id &&
        other.description == description &&
        other.amount == amount &&
        other.type == type &&
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        description.hashCode ^
        amount.hashCode ^
        type.hashCode ^
        date.hashCode;
  }
}
