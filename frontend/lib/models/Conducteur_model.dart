class ConducteurModel {
  final int id;
  final String nom;
  final String prenom;
  final String telephone;
  final String numPermis;
  final String? adresse;
  final String statut;
  final String? email;

  ConducteurModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.numPermis,
    this.adresse,
    required this.statut,
    this.email,
  });

  factory ConducteurModel.fromJson(Map<String, dynamic> json) {
    return ConducteurModel(
      id: json['id'],
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      telephone: json['telephone'] ?? '',
      numPermis: json['num_permis'] ?? '',
      adresse: json['adresse'],
      statut: json['statut'] ?? 'actif',
      email: json['email'],
    );
  }

  String get fullName => '$nom $prenom';
}
