class OrderModel {
  final int? id;
  final String studentName;
  final String studentClass;
  final int serviceId;
  final String? serviceName; // For display helper
  final String? serviceCategory; // For display helper
  final int targetYear;
  final String targetMonth; // e.g., 'Januari', 'Februari'
  final int targetDay;
  final double nominal;
  final double? cashReceived;
  final String paymentMethod; // 'Tunai' or 'Transfer'
  final String transferChannel; // 'QRIS' or 'None'
  final DateTime orderDate;
  final String status; // 'Aktif', 'Selesai', 'Dibatalkan'
  final String notes;
  final int isRevised; // 0 or 1
  final int? parentOrderId;

  OrderModel({
    this.id,
    required this.studentName,
    required this.studentClass,
    required this.serviceId,
    this.serviceName,
    this.serviceCategory,
    required this.targetYear,
    required this.targetMonth,
    required this.targetDay,
    required this.nominal,
    this.cashReceived,
    required this.paymentMethod,
    required this.transferChannel,
    required this.orderDate,
    required this.status,
    required this.notes,
    required this.isRevised,
    this.parentOrderId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'student_name': studentName,
      'student_class': studentClass,
      'service_id': serviceId,
      'target_year': targetYear,
      'target_month': targetMonth,
      'target_day': targetDay,
      'nominal': nominal,
      'cash_received': cashReceived,
      'payment_method': paymentMethod,
      'transfer_channel': transferChannel,
      'order_date': orderDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'is_revised': isRevised,
      'parent_order_id': parentOrderId,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as int?,
      studentName: map['student_name'] as String,
      studentClass: map['student_class'] as String,
      serviceId: map['service_id'] as int,
      serviceName: map['service_name'] as String?,
      serviceCategory: map['service_category'] as String?,
      targetYear: map['target_year'] as int,
      targetMonth: map['target_month'] as String,
      targetDay: map['target_day'] as int,
      nominal: (map['nominal'] as num).toDouble(),
      cashReceived: (map['cash_received'] as num?)?.toDouble(),
      paymentMethod: map['payment_method'] as String,
      transferChannel: map['transfer_channel'] as String? ?? 'None',
      orderDate: DateTime.parse(map['order_date'] as String),
      status: map['status'] as String,
      notes: map['notes'] as String? ?? '',
      isRevised: map['is_revised'] as int? ?? 0,
      parentOrderId: map['parent_order_id'] as int?,
    );
  }

  OrderModel copyWith({
    int? id,
    String? studentName,
    String? studentClass,
    int? serviceId,
    String? serviceName,
    String? serviceCategory,
    int? targetYear,
    String? targetMonth,
    int? targetDay,
    double? nominal,
    double? cashReceived,
    String? paymentMethod,
    String? transferChannel,
    DateTime? orderDate,
    String? status,
    String? notes,
    int? isRevised,
    int? parentOrderId,
  }) {
    return OrderModel(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      studentClass: studentClass ?? this.studentClass,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      targetYear: targetYear ?? this.targetYear,
      targetMonth: targetMonth ?? this.targetMonth,
      targetDay: targetDay ?? this.targetDay,
      nominal: nominal ?? this.nominal,
      cashReceived: cashReceived ?? this.cashReceived,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transferChannel: transferChannel ?? this.transferChannel,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isRevised: isRevised ?? this.isRevised,
      parentOrderId: parentOrderId ?? this.parentOrderId,
    );
  }
}
