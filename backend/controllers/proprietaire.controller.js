const bcrypt = require('bcryptjs');
const ProprietaireModel = require('../models/proprietaire.model');

// ═══ INSCRIPTION ═══
const demanderInscription = async (req, res) => {
  try {
    const { nom, prenom, age, email, tel, adresse, mot_de_passe, numero_proprietaire } = req.body;

    const numero = await ProprietaireModel.findNumero(numero_proprietaire);
    if (!numero) {
      return res.status(400).json({ message: 'Numéro immatriculation non reconnu' });
    }

    if (numero.est_utilise) {
      return res.status(400).json({ message: 'Numéro immatriculation déjà utilisé' });
    }

    const demandeNumero = await ProprietaireModel.findDemandeByNumero(numero_proprietaire);
    if (demandeNumero) {
      return res.status(400).json({ message: 'Numéro immatriculation déjà utilisé' });
    }

    const demandeTel = await ProprietaireModel.findDemandeByTel(tel);
    if (demandeTel) {
      return res.status(400).json({ message: 'Numéro de téléphone déjà utilisé' });
    }

    const hash = await bcrypt.hash(mot_de_passe, 10);
    await ProprietaireModel.demanderInscription({
      nom, prenom, age, email, tel, adresse, hash, numero_proprietaire
    });

    res.json({ message: 'Votre demande est envoyée et en attente de validation' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══ MON ID ═══
const getMonId = async (req, res) => {
  try {
    const id = await ProprietaireModel.getId(req.user.id);
    if (!id) {
      return res.status(404).json({ message: 'Propriétaire introuvable' });
    }
    res.json({ id });
  } catch (err) {
    console.error('❌ getMonId:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══ EVALUATIONS ═══
const getEvaluationsProp = async (req, res) => {
  try {
    const propId = await ProprietaireModel.getId(req.user.id);
    if (!propId) return res.status(404).json({ message: 'Propriétaire introuvable' });
    const rows = await ProprietaireModel.getEvaluationsPourMoi(propId);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══ FEEDBACKS ═══
const getFeedbacksProp = async (req, res) => {
  try {
    const propId = await ProprietaireModel.getId(req.user.id);
    if (!propId) return res.status(404).json({ message: 'Propriétaire introuvable' });
    const rows = await ProprietaireModel.getFeedbacksPourMoi(propId);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══ SIGNALEMENTS ═══
const getSignalementsProp = async (req, res) => {
  try {
    const propId = await ProprietaireModel.getId(req.user.id);
    if (!propId) return res.status(404).json({ message: 'Propriétaire introuvable' });
    const rows = await ProprietaireModel.getSignalementsPourMoi(propId);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══════════════════════════════════════════
// ⭐ DASHBOARD STATS — جديد
// ═══════════════════════════════════════════
const getDashboardStats = async (req, res) => {
  try {
    // req.user.id = compte_id (من JWT)
    // نحولوه لـ proprietaire.id
    const propId = await ProprietaireModel.getId(req.user.id);
    if (!propId) {
      return res.status(404).json({ message: 'Propriétaire introuvable' });
    }

    const vehicules = await ProprietaireModel.countVehicules(propId);
    const conducteurs = await ProprietaireModel.countConducteurs(propId);
    const lignes = await ProprietaireModel.countLignes(propId);
    const annonces = await ProprietaireModel.countAnnonces(propId);

    res.json({
      vehicules: parseInt(vehicules),
      conducteurs: parseInt(conducteurs),
      lignes: parseInt(lignes),
      annonces: parseInt(annonces),
    });
  } catch (err) {
    console.error('❌ Dashboard stats error:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══ EXPORT ═══
module.exports = {
  demanderInscription,
  getMonId,
  getEvaluationsProp,
  getFeedbacksProp,
  getSignalementsProp,
  getDashboardStats, // ⭐ جديد
};