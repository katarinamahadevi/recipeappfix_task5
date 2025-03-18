class CategoryModel {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id, 
    required this.name, 
    required this.createdAt, 
    required this.updatedAt
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is String 
          ? int.parse(json['id']) 
          : json['id'],
      name: json['name'] ?? 'Unnamed Category',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }
}