const pool = require('../db/pool');
const TrajetModel = require('../models/trajet.model');

// ── helper ──
const getConducteurId = async (compteId) => {
  const r = await pool.query(
    'SELECT id FROM conducteur WHERE compte_id = $1', [compteId]
  );
  return r.rows[0]?.id || null;
};

// ══════════════════════════════════════
// 🔴 CONDUCTEUR — GPS Tracking
// ══════════════════════════════════════

exports.demarrer = async (req, res) => {
  try {
    const conducteurId = await getConducteurId(req.user.id);
    if (!conducteurId)
      return res.status(404).json({ message: 'Conducteur introuvable' });

    // ننهيو أي trajet قديم
    const existants = await TrajetModel.getEnCoursByConducteur(conducteurId);
    for (const t of existants) {
      await TrajetModel.terminerTrajet(t.id, conducteurId);
      req.io.emit('trajet_termine', { trajet_id: t.id, conducteur_id: conducteurId });
    }

    // نجيبو الـ affectation
    const affectation = await TrajetModel.getAffectationByConducteur(conducteurId);
    if (!affectation)
      return res.status(404).json({ message: 'Aucune affectation active trouvée' });

    // نبداو trajet جديد
    const trajet = await TrajetModel.createTrajetConducteur({
      affectation_id: affectation.affectation_id,
      conducteur_id:  conducteurId,
      vehicule_id:    affectation.vehicule_id,
      ligne_id:       affectation.ligne_id,
    });

    req.io.emit('trajet_demarre', {
      trajet_id:    trajet.id,
      ligne_id:     trajet.ligne_id,
      conducteur_id: trajet.conducteur_id,
    });

    res.status(201).json({
      message:   'Trajet démarré',
      trajet_id: trajet.id,
      ligne_id:  trajet.ligne_id,
    });

  } catch (err) {
    console.error('❌ demarrer:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══════════════════════════════════════════════════════════
// ✅ الجزء المُصحح ديال updatePosition — بدل بيه القديم
// فـ trajet.controller.js
// ═══════════════════════════════════════════════════════════

exports.updatePosition = async (req, res) => {
  const { trajet_id, latitude, longitude, vitesse } = req.body;

  try {
    if (!trajet_id || !latitude || !longitude)
      return res.status(400).json({ message: 'trajet_id, latitude et longitude requis' });

    const conducteurId = await getConducteurId(req.user.id);
    if (!conducteurId)
      return res.status(404).json({ message: 'Conducteur introuvable' });

    const trajet = await TrajetModel.updatePosition(trajet_id, latitude, longitude, vitesse);
    if (!trajet)
      return res.status(404).json({ message: 'Trajet introuvable ou déjà terminé' });

    // ⭐ جديد: نجيبو معلومات الخط والمركبة والسائق باش الفرونت يقدر يبينهم
    const infoResult = await pool.query(
      `SELECT l.numero AS ligne_numero, l.nom AS ligne_nom,
              v.immatriculation, v.marque,
              c.nom AS conducteur_nom, c.prenom AS conducteur_prenom
       FROM trajet t
       LEFT JOIN ligne l ON l.id = t.ligne_id
       LEFT JOIN vehicule v ON v.id = t.vehicule_id
       LEFT JOIN conducteur c ON c.id = t.conducteur_id
       WHERE t.id = $1`,
      [trajet_id]
    );
    const info = infoResult.rows[0] || {};

    // Broadcast Socket.io — tous les clients connectés reçoivent
    req.io.emit('position_broadcast', {
      trajet_id,
      latitude,
      longitude,
      vitesse:           vitesse || 0,
      ligne_id:          trajet.ligne_id,
      vehicule_id:       trajet.vehicule_id,
      conducteur_id:     conducteurId,
      proprietaire_id:   trajet.proprietaire_id,
      // ⭐ الحقول الجداد لي كانو ناقصين
      ligne_numero:      info.ligne_numero || '',
      ligne_nom:         info.ligne_nom || '',
      immatriculation:   info.immatriculation || '',
      marque:            info.marque || '',
      conducteur_nom:    info.conducteur_nom || '',
      conducteur_prenom: info.conducteur_prenom || '',
      timestamp:         new Date().toISOString(),
    });

    res.json({ message: 'Position mise à jour' });

  } catch (err) {
    console.error('❌ updatePosition:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.terminer = async (req, res) => {
  const trajetId = req.params.id;

  try {
    const conducteurId = await getConducteurId(req.user.id);
    if (!conducteurId)
      return res.status(404).json({ message: 'Conducteur introuvable' });

    const trajet = await TrajetModel.terminerTrajet(trajetId, conducteurId);
    if (!trajet)
      return res.status(404).json({ message: 'Trajet introuvable' });

    req.io.emit('trajet_termine', {
      trajet_id:    trajetId,
      ligne_id:     trajet.ligne_id,
      conducteur_id: conducteurId,
    });

    res.json({ message: 'Trajet terminé' });

  } catch (err) {
    console.error('❌ terminer:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.getTrajetsActifs = async (req, res) => {
  try {
    const { ligne_id, proprietaire_id } = req.query;
    
    let query = `
      SELECT
        t.id           AS trajet_id,
        t.latitude, t.longitude, t.vitesse,
        t.updated_at   AS derniere_maj,
        l.id           AS ligne_id,
        l.numero       AS ligne_numero,
        l.nom          AS ligne_nom,
        l.proprietaire_id,
        v.immatriculation, v.marque,
        c.nom  AS conducteur_nom,
        c.prenom AS conducteur_prenom,
        t.conducteur_id
      FROM trajet t
      JOIN ligne l ON l.id = t.ligne_id
      LEFT JOIN vehicule v ON v.id = t.vehicule_id
      JOIN conducteur c ON c.id = t.conducteur_id
      WHERE t.statut = 'en_cours'
    `;
    const params = [];

    if (proprietaire_id) {
      query += ` AND l.proprietaire_id = $1`;
      params.push(proprietaire_id);
    } else if (ligne_id) {
      query += ` AND t.ligne_id = $1`;
      params.push(ligne_id);
    }

    const r = await pool.query(query, params);
    res.json(r.rows);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ══════════════════════════════════════
// 🔵 EXISTING — Proprietaire / Admin
// ══════════════════════════════════════

exports.getTrajets = async (req, res) => {
  try {
    const trajets = await TrajetModel.getDisponibles();
    res.json(trajets);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.getTrajetsByLigne = async (req, res) => {
  try {
    const trajets = await TrajetModel.getByLigne(req.params.ligneId);
    res.json(trajets);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.createTrajet = async (req, res) => {
  try {
    const trajet = await TrajetModel.create(req.body);
    res.status(201).json(trajet);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.deleteTrajet = async (req, res) => {
  try {
    await TrajetModel.delete(req.params.id);
    res.json({ message: 'Trajet supprimé' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};