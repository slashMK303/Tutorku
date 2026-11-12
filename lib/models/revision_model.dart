class RevisionModel {
  final int? id;
  final int orderId;
  final String revisionReason;
  final DateTime revisionDate;
  final String oldDetails; // JSON snapshot of OrderModel before revision

  RevisionModel({
    this.id,
    required this.orderId,
    required this.revisionReason,
    required this.revisionDate,
    required this.oldDetails,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'order_id': orderId,
      'revision_reason': revisionReason,
      'revision_date': revisionDate.toIso8601String(),
      'old_details': oldDetails,
    };
  }

  factory RevisionModel.fromMap(Map<String, dynamic> map) {
    return RevisionModel(
      id: map['id'] as int?,
      orderId: map['order_id'] as int,
      revisionReason: map['revision_reason'] as String,
      revisionDate: DateTime.parse(map['revision_date'] as String),
      oldDetails: map['old_details'] as String,
    );
  }
}
