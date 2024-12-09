class UserModel {
  final String id;
  final String email;
  final String nickname;
  final String? gender;
  final DateTime? birthDate;

  UserModel({
    required this.id,
    required this.email,
    required this.nickname,
    this.gender,
    this.birthDate,
  });

  // Convierte un objeto UserModel a un mapa para Firebase
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nickname': nickname,
      'gender': gender,
      'date_birth': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
    };
  }

  // Crea un objeto UserModel a partir de un snapshot de Firebase
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      nickname: map['nickname'] ?? '',
      gender: map['gender'],
      birthDate: map['date_birth'] != null
          ? (map['date_birth'] as Timestamp).toDate()
          : null,
    );
  }
}
