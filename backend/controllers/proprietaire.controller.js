const bcrypt = require('bcryptjs');
const ProprietaireModel = require('../models/proprietaire.model');

// ═══ INSCRIPTION ═══
const demanderInscription = async (req, res) => {
  try {
    const { nom, prenom, age, email, tel, adresse, mot_de_passe, numero_proprietaire } = req.body;

    // ✅ تحقق 1: الرقم موجود؟
    const numero = await ProprietaireModel.findNumero(numero_proprietaire);
    if (!numero) {
      return res.status(400).json({ message: 'Numéro immatriculation non reconnu' });
    }

    // ✅ تحقق 2: مستعمل بعد قبول الأدمين؟
    if (numero.est_utilise) {
      return res.status(400).json({ message: 'Numéro immatriculation déjà utilisé' });
    }

    // ✅ تحقق 3: في دمندة en_attente أو accepte بنفس الرقم؟
    const demandeNumero = await ProprietaireModel.findDemandeByNumero(numero_proprietaire);
    if (demandeNumero) {
      return res.status(400).json({ message: 'Numéro immatriculation déjà utilisé' });
    }

    // ✅ تحقق 4: رقم الهاتف مستعمل؟
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

// ═══ EXPORT ═══
module.exports = {
  demanderInscription,
  getEvaluationsProp,
  getFeedbacksProp,
  getSignalementsProp,
};