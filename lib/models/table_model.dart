class TableModel {
  final int id;
  final String name;
  final String status;

  TableModel({required this.id, required this.name, required this.status});

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}
