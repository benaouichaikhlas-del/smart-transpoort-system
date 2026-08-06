class DemandeModel {
  final String nom;
  final String prenom;
  final int age;
  final String email;
  final String tel;
  final String adresse;
  final String motDePasse;
  final String numeroProprietaire;

  DemandeModel({
    required this.nom,
    required this.prenom,
    required this.age,
    required this.email,
    required this.tel,
    required this.adresse,
    required this.motDePasse,
    required this.numeroProprietaire,
  });

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'prenom': prenom,
        'age': age,
        'email': email,
        'tel': tel,
        'adresse': adresse,
        'mot_de_passe': motDePasse,
        'numero_proprietaire': numeroProprietaire,
      };
}
