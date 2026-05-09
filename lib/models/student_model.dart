// class Student {
//   final String id;
//   final String name;

//   Student({
//     required this.id,
//     required this.name,
//   });

//   // Create Student object from JSON
//   factory Student.fromJson(Map<String, dynamic> json) {
//     return Student(
//       id: json['id']?.toString() ?? '',
//       name: json['name']?.toString() ?? '',
//     );
//   }

//   // Convert Student object to JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//     };
//   }

//   @override
//   String toString() {
//     return 'Student(id: $id, name: $name)';
//   }
// }


class Student {
  final String id;
  final String name;
  bool present;

  Student({
    required this.id,
    required this.name,
    this.present = true,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
    );
  }
}
