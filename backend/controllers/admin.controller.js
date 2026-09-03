const pool = require('../db/pool');
const AdminModel = require('../models/admin.model');
const NotificationModel = require('../models/notification.model');

const getDemandes = async (req, res) => {
  try {
    const rows = await AdminModel.getDemandes();
    res.status(200).json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ✅ معدلة ومصححة بالكامل
const accepterDemande = async (req, res) => {
  const { id } = req.params;
  try {
    const demande = await AdminModel.getDemandeById(id);
    if (!demande)
      return res.status(404).json({ message: 'Demande introuvable' });

    // 🔍 شوف واش الحساب موجود (case-insensitive)
    const compteExistant = await AdminModel.getCompteByEmail(demande.email);

    let compteId;

    if (compteExistant) {
      // 🔁 الحساب موجود → فعلو + حدث الباسورد + role
      compteId = compteExistant.id;
      await AdminModel.updateComptePassword(compteId, demande.mot_de_passe);
      
      // ✅ هادي لازمة باش يتفعل الحساب!
      const updated = await AdminModel.activerCompteProprietaire(compteId);
      console.log('🔁 Compte existant réactivé:', updated);
    } else {
      // ✅ الحساب ماشي موجود → خلق جديد
      compteId = await AdminModel.creerCompteProprietaire(
        demande.email,
        demande.mot_de_passe
      );
      console.log('✅ Nouveau compte créé, id:', compteId);
    }

    // 🔍 شوف واش proprietaire موجود
    const proprietaireExistant = await AdminModel.getProprietaireByEmail(demande.email);

    if (!proprietaireExistant) {
      // خلق proprietaire فقط إذا ماشي موجود
      await AdminModel.creerProprietaire({
        nom: demande.nom,
        prenom: demande.prenom,
        email: demande.email,
        tel: demande.tel,
        adresse: demande.adresse,
        compteId,
        age: demande.age,
      });
      console.log('✅ Proprietaire créé');
    }

    // ✅ فعل الرقم PRO
    if (demande.numero_proprietaire) {
      await pool.query(
        "UPDATE numeros_proprietaire SET est_utilise = true WHERE numero = $1",
        [demande.numero_proprietaire]
      );
    }

    // ✅ قبل الطلب
    await AdminModel.accepterDemande(id);

    res.status(200).json({
      success: true,
      message: 'Compte activé avec succès',
      compte_id: compteId,
    });
  } catch (err) {
    console.error('❌ ERREUR accepterDemande:', err);
    res.status(500).json({ message: err.message || 'Erreur serveur' });
  }
};

const refuserDemande = async (req, res) => {
  const { id } = req.params;
  try {
    const row = await AdminModel.refuserDemande(id);
    if (!row)
      return res.status(404).json({ message: 'Demande introuvable' });
    res.status(200).json({ message: 'Demande refusée' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const changerStatutDemande = async (req, res) => {
  const { id } = req.params;
  const { statut } = req.body;
  try {
    if (!['accepte', 'refuse'].includes(statut))
      return res.status(400).json({ message: 'Statut invalide' });

    const demande = await AdminModel.getDemandeById(id);
    if (!demande)
      return res.status(404).json({ message: 'Demande introuvable' });

    await AdminModel.changerStatutDemande(id, statut);

    if (statut === 'refuse') {
      await AdminModel.desactiverCompte(demande.email);
      res.json({ message: 'Compte désactivé avec succès' });
    } else {
      await AdminModel.reactiverCompte(demande.email);
      res.json({ message: 'Compte réactivé avec succès' });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const supprimerDemande = async (req, res) => {
  const { id } = req.params;
  try {
    const demande = await AdminModel.getDemandeById(id);
    if (!demande)
      return res.status(404).json({ message: 'Demande introuvable' });

    if (demande.statut === 'accepte') {
      await pool.query('DELETE FROM proprietaire WHERE LOWER(email) = LOWER($1)', [demande.email]);
      await pool.query('DELETE FROM compte WHERE LOWER(email) = LOWER($1)', [demande.email]);
    }

    await AdminModel.supprimerDemande(id);
    res.status(200).json({ message: 'Demande supprimée avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const getFeedbacks = async (req, res) => {
  try {
    const rows = await AdminModel.getFeedbacks();
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const getSignalements = async (req, res) => {
  try {
    const rows = await AdminModel.getSignalements();
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const getEvaluationsAdmin = async (req, res) => {
  try {
    const rows = await AdminModel.getEvaluationsAvecMoyenne();
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const updateStatutSignalement = async (req, res) => {
  const { id } = req.params;
  const { statut } = req.body;
  try {
    if (!['nouveau', 'en_cours', 'resolu'].includes(statut))
      return res.status(400).json({ message: 'Statut invalide' });

    const sig = await AdminModel.getSignalementById(id);
    if (!sig)
      return res.status(404).json({ message: 'Signalement introuvable' });

    await AdminModel.updateStatutSignalement(id, statut);

    const passagerId = sig.passager_id;
    if (passagerId) {
      const titres = {
        en_cours: '🔄 Signalement en cours de traitement',
        resolu:   '✅ Signalement résolu',
      };
      const messages = {
        en_cours: 'Votre signalement est pris en charge par l\'équipe.',
        resolu:   'Votre problème a été résolu. Merci pour votre retour !',
      };

      if (titres[statut]) {
        await NotificationModel.create(
          passagerId,
          titres[statut],
          messages[statut],
          'signalement'
        );
      }
    }

    res.json({ message: 'Statut mis à jour' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = {
  getDemandes,
  accepterDemande,
  refuserDemande,
  changerStatutDemande,
  supprimerDemande,
  getFeedbacks,
  getSignalements,
  getEvaluationsAdmin,
  updateStatutSignalement,
};