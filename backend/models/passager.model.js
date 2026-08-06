const pool = require('../db/pool');

const PassagerModel = {

  getVisiteurId: async (compteId) => {
    return compteId;
  },

  getConducteurPourSignalement: async (ligneId) => {
    const r = await pool.query(
      `SELECT c.id FROM conducteur c
       LEFT JOIN trajet t ON t.conducteur_id = c.id AND t.ligne_id = $1
       ORDER BY (t.id IS NOT NULL) DESC LIMIT 1`,
      [ligneId || null]
    );
    return r.rows[0] || null;
  },

  createRetard: async (conducteurId, ligneId, motif) => {
    await pool.query(
      `INSERT INTO retard (conducteur_id, ligne_id, motif, statut)
       VALUES ($1,$2,$3,'en_attente')`,
      [conducteurId, ligneId || null, motif]
    );
  },

  createPanne: async (conducteurId, ligneId, description) => {
    await pool.query(
      `INSERT INTO panne (conducteur_id, ligne_id, description, statut)
       VALUES ($1,$2,$3,'en_attente')`,
      [conducteurId, ligneId || null, description]
    );
  },

  getMesReservations: async (compteId) => {
    const r = await pool.query(
      `SELECT res.*,
              t.places_dispo,
              l.numero AS ligne_numero,
              l.nom    AS ligne_nom
       FROM reservation res
       JOIN trajet t ON t.id = res.trajet_id
       JOIN ligne l  ON l.id = t.ligne_id
       WHERE res.passager_id = $1
       ORDER BY res.created_at DESC`,
      [compteId]
    );
    return r.rows;
  },

  getActiveReservation: async (visiteurId, trajetId) => {
    const r = await pool.query(
      `SELECT id FROM reservation
       WHERE passager_id = $1 AND trajet_id = $2 AND statut = 'active'`,
      [visiteurId, trajetId]
    );
    return r.rows[0];
  },

  createReservation: async (visiteurId, trajetId, nbPlaces) => {
    const r = await pool.query(
      `INSERT INTO reservation (passager_id, trajet_id, nb_places)
       VALUES ($1,$2,$3) RETURNING *`,
      [visiteurId, trajetId, nbPlaces]
    );
    return r.rows[0];
  },

  getReservationById: async (id, visiteurId) => {
    const r = await pool.query(
      'SELECT * FROM reservation WHERE id = $1 AND passager_id = $2',
      [id, visiteurId]
    );
    return r.rows[0];
  },

  updateReservation: async (id, nbPlaces) => {
    await pool.query(
      'UPDATE reservation SET nb_places = $1 WHERE id = $2',
      [nbPlaces, id]
    );
  },

  annulerReservation: async (id) => {
    await pool.query(
      "UPDATE reservation SET statut = 'annulee' WHERE id = $1", [id]
    );
  },

 // في passager.model.js — عدّل هكذا
insertNotification: async ({ passager_id, titre, message, type }) => {
  const NotificationModel = require('./notification.model');
  await NotificationModel.create(passager_id, titre, message, type);
},

 getRetardsPannes: async () => {
    const retards = await pool.query(
      `SELECT r.*, c.nom AS conducteur_nom, c.prenom AS conducteur_prenom,
              l.numero AS ligne_numero
       FROM retard r
       JOIN conducteur c ON c.id = r.conducteur_id
       LEFT JOIN ligne l ON l.id = r.ligne_id
       WHERE r.statut != 'resolu'
       ORDER BY r.created_at DESC`
    );
    const pannes = await pool.query(
      `SELECT p.*, c.nom AS conducteur_nom, c.prenom AS conducteur_prenom,
              l.numero AS ligne_numero
       FROM panne p
       JOIN conducteur c ON c.id = p.conducteur_id
       LEFT JOIN ligne l ON l.id = p.ligne_id
       WHERE p.resolue = false OR p.resolue IS NULL
       ORDER BY p.created_at DESC`
    );
    return { retards: retards.rows, pannes: pannes.rows };
  },

  createEvaluation: async (visiteurId, ligneId, note, commentaire) => {
    await pool.query(
      `INSERT INTO evaluation (passager_id, ligne_id, note, commentaire)
       VALUES ($1,$2,$3,$4)`,
      [visiteurId, ligneId, note, commentaire]
    );
  },

  getEvaluations: async () => {
    const r = await pool.query(
      `SELECT e.*, l.numero AS ligne_numero, l.nom AS ligne_nom
       FROM evaluation e
       JOIN ligne l ON l.id = e.ligne_id
       ORDER BY e.created_at DESC`
    );
    return r.rows;
  },

  getEvaluationByPassager: async (passagerId, ligneId) => {
    const r = await pool.query(
      `SELECT id, note, commentaire FROM evaluation
       WHERE passager_id = $1 AND ligne_id = $2`,
      [passagerId, ligneId]
    );
    return r.rows[0] || null;
  },

  updateEvaluation: async (id, note, commentaire) => {
    await pool.query(
      `UPDATE evaluation 
       SET note = $1, commentaire = $2, updated_at = NOW()
       WHERE id = $3`,
      [note, commentaire || null, id]
    );
  },

  getEvaluationsByPassager: async (passagerId) => {
    const r = await pool.query(
      `SELECT e.*, l.numero AS ligne_numero, l.nom AS ligne_nom
       FROM evaluation e
       JOIN ligne l ON l.id = e.ligne_id
       WHERE e.passager_id = $1
       ORDER BY e.created_at DESC`,
      [passagerId]
    );
    return r.rows;
  },

  signalerAutre: async (visiteurId, ligneId, description) => {
    await pool.query(
      `INSERT INTO signalement (passager_id, ligne_id, description, statut)
       VALUES ($1, $2, $3, 'nouveau')`,
      [visiteurId, ligneId || null, description]
    );
  },

  evaluationDejaExiste: async (passagerId, ligneId) => {
    const r = await pool.query(
      `SELECT id FROM evaluation
       WHERE passager_id = $1 AND ligne_id = $2`,
      [passagerId, ligneId]
    );
    return r.rows.length > 0;
  },

  getMoyennesLignes: async () => {
    const r = await pool.query(
      `SELECT l.id, l.numero, l.nom,
              ROUND(AVG(e.note)::numeric, 1) AS moyenne,
              COUNT(e.id) AS nb_evaluations
       FROM ligne l
       LEFT JOIN evaluation e ON e.ligne_id = l.id
       GROUP BY l.id, l.numero, l.nom
       ORDER BY l.numero`
    );
    return r.rows;
  },

  getProprietaireLigne: async (ligneId) => {
    const r = await pool.query(
      `SELECT p.compte_id
       FROM proprietaire p
       JOIN ligne l ON l.proprietaire_id = p.id
       WHERE l.id = $1`,
      [ligneId]
    );
    return r.rows[0] || null;
  },

  createFeedback: async (passagerId, ligneId, contenu) => {
    await pool.query(
      `INSERT INTO feedback (passager_id, ligne_id, contenu)
       VALUES ($1, $2, $3)`,
      [passagerId, ligneId || null, contenu]
    );
  },

  signalerProbleme: async (passagerId, ligneId, description) => {
    await pool.query(
      `INSERT INTO signalement (passager_id, ligne_id, description, statut)
       VALUES ($1, $2, $3, 'nouveau')`,
      [passagerId, ligneId || null, description]
    );
  },

};

module.exports = PassagerModel;