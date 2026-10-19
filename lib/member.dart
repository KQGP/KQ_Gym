class Member {
  int? id;
  String name;
  String phone;
  DateTime startDate;
  DateTime endDate;
  bool isActive;
  String? notes;

  Member({
    this.id,
    required this.name,
    required this.phone,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.notes,
  });

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      isActive: map['isActive'] == 1,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'notes': notes,
    };
  }
} 