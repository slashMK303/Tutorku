class ServiceModel {
  final int? id;
  final String name;
  final String category; // 'SMP' or 'SMA/SMK'
  final double defaultPrice;
  final String description;
  final DateTime createdAt;

  ServiceModel({
    this.id,
    required this.name,
    required this.category,
    required this.defaultPrice,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'default_price': defaultPrice,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      defaultPrice: (map['default_price'] as num).toDouble(),
      description: map['description'] as String? ?? '',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  ServiceModel copyWith({
    int? id,
    String? name,
    String? category,
    double? defaultPrice,
    String? description,
    DateTime? createdAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
