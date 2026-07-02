import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class UserModelSql {
  final int? id;
  final String? nama;
  final String email;
  final String password;
  UserModelSql({
    this.id,
    this.nama,
    required this.email,
    required this.password,
  });

  UserModelSql copyWith({
    int? id,
    String? nama,
    String? email,
    String? password,
  }) {
    return UserModelSql(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nama': nama,
      'email': email,
      'password': password,
    };
  }

  factory UserModelSql.fromMap(Map<String, dynamic> map) {
    return UserModelSql(
      id: map['id'] != null ? map['id'] as int : null,
      nama: map['nama'] != null ? map['nama'] as String : null,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModelSql.fromJson(String source) =>
      UserModelSql.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserModelSql(id: $id, nama: $nama, email: $email, password: $password)';
  }

  @override
  bool operator ==(covariant UserModelSql other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.nama == nama &&
        other.email == email &&
        other.password == password;
  }

  @override
  int get hashCode {
    return id.hashCode ^ nama.hashCode ^ email.hashCode ^ password.hashCode;
  }
}
