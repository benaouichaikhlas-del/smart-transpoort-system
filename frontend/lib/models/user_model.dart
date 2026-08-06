class UserModel {
  final int id;
  final String email;
  final String role;
  final String token;
  final String? nom;        // ← nullable
  final String? prenom;     // ← nullable
  final int? age;
  final String? tel;
  final String? numPermis;
  final String? adresse;
  final bool premierConnexion;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.token,
    this.nom,               // ← بدون required
    this.prenom,            // ← بدون required
    this.age,
    this.tel,
    this.numPermis,
    this.adresse,
    this.premierConnexion = false,
  });

  // ✅ copyWith
  UserModel copyWith({
    int? id,
    String? email,
    String? role,
    String? token,
    String? nom,
    String? prenom,
    int? age,
    String? tel,
    String? numPermis,
    String? adresse,
    bool? premierConnexion,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      age: age ?? this.age,
      tel: tel ?? this.tel,
      numPermis: numPermis ?? this.numPermis,
      adresse: adresse ?? this.adresse,
      premierConnexion: premierConnexion ?? this.premierConnexion,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    return UserModel(
      id: user['id'],
      email: user['email'] ?? '',
      role: user['role'] ?? '',
      token: json['token'] ?? '',
      nom: user['nom'],           // ← nullable
      prenom: user['prenom'],     // ← nullable
      age: user['age'],
      tel: user['tel'],
      numPermis: user['num_permis'],
      adresse: user['adresse'],
      premierConnexion: json['premier_connexion'] ?? false,
    );
  }

  String get fullName {
    if (prenom != null && nom != null && prenom!.isNotEmpty && nom!.isNotEmpty) {
      return '$prenom $nom';
    }
    return email; // fallback
  }

  String? get formattedTel {
    if (tel == null || tel!.isEmpty) return null;
    final clean = tel!.replaceAll(RegExp(r'\s'), '');
    if (RegExp(r'^0[5-7]\d{8}$').hasMatch(clean)) {
      return '${clean.substring(0, 2)} ${clean.substring(2, 4)} ${clean.substring(4, 6)} ${clean.substring(6, 8)} ${clean.substring(8)}';
    }
    return tel;
  }
}