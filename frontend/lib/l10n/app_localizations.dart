import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'ThronSport DZ'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get welcome;

  /// No description provided for @welcomeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre réseau de transport'**
  String get welcomeMessage;

  /// No description provided for @enDirect.
  ///
  /// In fr, this message translates to:
  /// **'En direct'**
  String get enDirect;

  /// No description provided for @rechercherStation.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une station...'**
  String get rechercherStation;

  /// No description provided for @stationsProches.
  ///
  /// In fr, this message translates to:
  /// **'Stations proches'**
  String get stationsProches;

  /// No description provided for @stationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Stations'**
  String get stationsTitle;

  /// No description provided for @voirTout.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get voirTout;

  /// No description provided for @lignes.
  ///
  /// In fr, this message translates to:
  /// **'Lignes'**
  String get lignes;

  /// No description provided for @annonces.
  ///
  /// In fr, this message translates to:
  /// **'Annonces'**
  String get annonces;

  /// No description provided for @seConnecter.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get seConnecter;

  /// No description provided for @sinscrire.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get sinscrire;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @arabic.
  ///
  /// In fr, this message translates to:
  /// **'Arabe'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get english;

  /// No description provided for @carte.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get carte;

  /// No description provided for @horaires.
  ///
  /// In fr, this message translates to:
  /// **'Horaires'**
  String get horaires;

  /// No description provided for @retardsPannes.
  ///
  /// In fr, this message translates to:
  /// **'Retards & Pannes'**
  String get retardsPannes;

  /// No description provided for @informations.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get informations;

  /// No description provided for @reseauTransport.
  ///
  /// In fr, this message translates to:
  /// **'Réseau de transport'**
  String get reseauTransport;

  /// No description provided for @navAccueil.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navAccueil;

  /// No description provided for @navLignes.
  ///
  /// In fr, this message translates to:
  /// **'Lignes'**
  String get navLignes;

  /// No description provided for @navStations.
  ///
  /// In fr, this message translates to:
  /// **'Stations'**
  String get navStations;

  /// No description provided for @navAnnonces.
  ///
  /// In fr, this message translates to:
  /// **'Annonces'**
  String get navAnnonces;

  /// No description provided for @navConnexion.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get navConnexion;

  /// No description provided for @emailOuTelephone.
  ///
  /// In fr, this message translates to:
  /// **'Email ou téléphone'**
  String get emailOuTelephone;

  /// No description provided for @motDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get motDePasse;

  /// No description provided for @nouveauMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get nouveauMotDePasse;

  /// No description provided for @confirmerMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmerMotDePasse;

  /// No description provided for @champObligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire'**
  String get champObligatoire;

  /// No description provided for @min6Caracteres.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 6 caractères'**
  String get min6Caracteres;

  /// No description provided for @motsDePasseDifferents.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get motsDePasseDifferents;

  /// No description provided for @bienvenue.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue !'**
  String get bienvenue;

  /// No description provided for @parmiNous.
  ///
  /// In fr, this message translates to:
  /// **'parmi nous !'**
  String get parmiNous;

  /// No description provided for @connexionAccesEspace.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour accéder à votre espace'**
  String get connexionAccesEspace;

  /// No description provided for @selectionnezProfil.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez votre profil pour continuer'**
  String get selectionnezProfil;

  /// No description provided for @securiteMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Pour votre sécurité, veuillez définir un nouveau mot de passe'**
  String get securiteMotDePasse;

  /// No description provided for @confirmer.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirmer;

  /// No description provided for @erreurReessayez.
  ///
  /// In fr, this message translates to:
  /// **'Erreur, veuillez réessayer'**
  String get erreurReessayez;

  /// No description provided for @pasDeCompte.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas de compte ? Inscrivez-vous'**
  String get pasDeCompte;

  /// No description provided for @connexion.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get connexion;

  /// No description provided for @erreur.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get erreur;

  /// No description provided for @choisirTypeCompte.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre type de compte'**
  String get choisirTypeCompte;

  /// No description provided for @fonctionnalitesDifferentes.
  ///
  /// In fr, this message translates to:
  /// **'Chaque compte offre des fonctionnalités différentes'**
  String get fonctionnalitesDifferentes;

  /// No description provided for @visiteurPassager.
  ///
  /// In fr, this message translates to:
  /// **'Visiteur / Passager'**
  String get visiteurPassager;

  /// No description provided for @reservezPlaces.
  ///
  /// In fr, this message translates to:
  /// **'Réservez des places et évaluez les lignes'**
  String get reservezPlaces;

  /// No description provided for @proprietaire.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get proprietaire;

  /// No description provided for @gerezVehicules.
  ///
  /// In fr, this message translates to:
  /// **'Gérez vos véhicules et vos conducteurs'**
  String get gerezVehicules;

  /// No description provided for @dejaCompte.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà un compte ? Connectez-vous'**
  String get dejaCompte;

  /// No description provided for @seSouvenirDeMoi.
  ///
  /// In fr, this message translates to:
  /// **'Se souvenir de moi'**
  String get seSouvenirDeMoi;

  /// No description provided for @motDePasseOublie.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get motDePasseOublie;

  /// No description provided for @ou.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get ou;

  /// No description provided for @affectations.
  ///
  /// In fr, this message translates to:
  /// **'Affectations'**
  String get affectations;

  /// No description provided for @emailInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get emailInvalide;

  /// No description provided for @entrerEmailPourCode.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre email pour recevoir un code'**
  String get entrerEmailPourCode;

  /// No description provided for @entrerCodeRecu.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code reçu par email'**
  String get entrerCodeRecu;

  /// No description provided for @motDePasseReinitialise.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe réinitialisé avec succès'**
  String get motDePasseReinitialise;

  /// No description provided for @envoyerCode.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le code'**
  String get envoyerCode;

  /// No description provided for @annuler.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get annuler;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
