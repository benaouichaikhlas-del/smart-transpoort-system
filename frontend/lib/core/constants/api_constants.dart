// core/constants/api_constants.dart
class ApiConstants {
  static const String socketUrl = 'http://192.168.1.9:3000';
  static const String baseUrl = 'http://192.168.1.9:3000/api';
  static String get chatbot => '$passager/chatbot';
  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String inscrireVisiteur = '$baseUrl/visiteur/inscrire';
  static const String demandeProprietaire = '$baseUrl/proprietaire/demande';

  // Admin
  static const String adminDemandes = '$baseUrl/admin/demandes';
  static const String admin = '$baseUrl/admin';

  // Conducteur
  static const String conducteurs = '$baseUrl/conducteurs';
  static const String conducteurActions = '$baseUrl/conducteur-actions';

  // Véhicule & Ligne
  static const String vehicules = '$baseUrl/vehicule';
  static const String lignes = '$baseUrl/ligne';
  static const String affectations = '$baseUrl/affectation';

  // Annonce & Compte
  static const String annonces = '$baseUrl/annonce';
  static const String compte = '$baseUrl/compte';

  // GPS
  static const String gps = '$baseUrl/gps';

  // Propriétaire
  static const String proprietaire = '$baseUrl/proprietaire';

  // ═══════════════════════════════════════════
  // PASSAGER (القديم + الجديد)
  // ═══════════════════════════════════════════
  static const String passager = '$baseUrl/passager';

  // Public (بدون token)
  static String get trajets => '$passager/trajets';
  static String get retardsPannes => '$passager/retards-pannes';
  static String get moyennes => '$passager/moyennes';
  // Protected (avec token)
  static String get evaluations => '$passager/evaluations';
  static String get feedback => '$passager/feedback';
  static String get reserver => '$passager/reserver';
  static String get mesReservations => '$passager/mes-reservations';
  static String modifierReservation(int id) =>
      '$passager/reservation/$id/modifier';
  static String annulerReservation(int id) =>
      '$passager/reservation/$id/annuler';
  static String get evaluer => '$passager/evaluer';
  static String get signalerProbleme => '$passager/signaler-probleme';
  static String get mesEvaluations => '$passager/mes-evaluations';

  // Notifications
  static const String notifications = '$baseUrl/notifications';
  static String marquerTousLus() => '$notifications/all/lu';
  static String marquerLu(int id) => '$notifications/$id';
}
