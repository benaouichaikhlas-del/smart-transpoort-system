const pool = require('../db/pool');

const TrajetModel = {

  // ══════════════════════════════════════
  // 🔵 EXISTING — Passager / Proprietaire
  // ══════════════════════════════════════

  getDisponibles: async () => {
    const r = await pool.query(
      `SELECT t.*,
              l.numero      AS ligne_numero,
              l.nom         AS ligne_nom,
              l.heure_debut,
              l.heure_fin,
              v.marque,
              v.immatriculation,
              ROUND(AVG(e.note)::numeric, 1) AS moyenne,
              COUNT(e.id)                    AS nb_evaluations
       FROM trajet t
       JOIN ligne l ON l.id = t.ligne_id
       LEFT JOIN vehicule v ON v.id = t.vehicule_id
       LEFT JOIN evaluation e ON e.ligne_id = l.id
       WHERE t.places_dispo > 0
       GROUP BY t.id, l.id, v.id
       ORDER BY t.created_at DESC`
    );
    return r.rows;
  },

  searchDisponibles: async (search) => {
    const r = await pool.query(
      `SELECT t.*,
              l.numero      AS ligne_numero,
              l.nom         AS ligne_nom,
              l.heure_debut,
              l.heure_fin,
              v.marque,
              v.immatriculation,
              ROUND(AVG(e.note)::numeric, 1) AS moyenne,
              COUNT(e.id)                    AS nb_evaluations
       FROM trajet t
       JOIN ligne l ON l.id = t.ligne_id
       LEFT JOIN vehicule v ON v.id = t.vehicule_id
       LEFT JOIN evaluation e ON e.ligne_id = l.id
       WHERE t.places_dispo > 0
         AND (LOWER(l.numero) LIKE LOWER($1) OR LOWER(l.nom) LIKE LOWER($1))
       GROUP BY t.id, l.id, v.id
       ORDER BY t.created_at DESC`,
      [`%${search}%`]
    );
    return r.rows;
  },

  getByLigne: async (ligneId) => {
    const r = await pool.query(
      `SELECT t.*, v.marque, v.immatriculation
       FROM trajet t
       LEFT JOIN vehicule v ON v.id = t.vehicule_id
       WHERE t.ligne_id = $1
       ORDER BY t.created_at DESC`,
      [ligneId]
    );
    return r.rows;
  },

  getById: async (id) => {
    const r = await pool.query(
      'SELECT * FROM trajet WHERE id = $1 FOR UPDATE', [id]
    );
    return r.rows[0] || null;
  },

  create: async ({ ligne_id, places_total, vehicule_id }) => {
    const r = await pool.query(
      `INSERT INTO trajet (ligne_id, places_total, places_dispo, vehicule_id, created_at)
       VALUES ($1, $2, $2, $3, NOW()) RETURNING *`,
      [ligne_id, places_total, vehicule_id || null]
    );
    return r.rows[0];
  },

  updatePlaces: async (id, diff) => {
    await pool.query(
      'UPDATE trajet SET places_dispo = places_dispo + $1 WHERE id = $2',
      [diff, id]
    );
  },

  delete: async (id) => {
    await pool.query('DELETE FROM trajet WHERE id = $1', [id]);
  },

  // ══════════════════════════════════════
  // 🔴 GPS Tracking — Conducteur
  // ══════════════════════════════════════

  getEnCoursByConducteur: async (conducteurId) => {
    const r = await pool.query(
      `SELECT id FROM trajet
       WHERE conducteur_id = $1 AND statut = 'en_cours'`,
      [conducteurId]
    );
    return r.rows;
  },

  getAffectationByConducteur: async (conducteurId) => {
    const r = await pool.query(
      `SELECT ligne_id, vehicule_id, id AS affectation_id
       FROM affectation
       WHERE conducteur_id = $1 AND actif = true
       LIMIT 1`,
      [conducteurId]
    );
    return r.rows[0] || null;
  },

  // ✅ نظيف — بدون dynamic query
  createTrajetConducteur: async ({ affectation_id, conducteur_id, vehicule_id, ligne_id }) => {
    const r = await pool.query(
      `INSERT INTO trajet
         (ligne_id, vehicule_id, statut, conducteur_id, affectation_id, created_at, updated_at)
       VALUES ($1, $2, 'en_cours', $3, $4, NOW(), NOW())
       RETURNING id, ligne_id, vehicule_id, statut, conducteur_id, created_at`,
      [ligne_id, vehicule_id || null, conducteur_id, affectation_id || null]
    );
    return r.rows[0];
  },

  updatePosition: async (trajetId, latitude, longitude, vitesse) => {
    const r = await pool.query(
      `UPDATE trajet
       SET latitude   = $1,
           longitude  = $2,
           vitesse    = $3,
           updated_at = NOW()
       WHERE id = $4 AND statut = 'en_cours'
       RETURNING *`,
      [latitude, longitude, vitesse || 0, trajetId]
    );
    return r.rows[0] || null;
  },

  terminerTrajet: async (trajetId, conducteurId) => {
    const r = await pool.query(
      `UPDATE trajet
       SET statut     = 'termine',
           updated_at = NOW()
       WHERE id = $1 AND conducteur_id = $2
       RETURNING *`,
      [trajetId, conducteurId]
    );
    return r.rows[0] || null;
  },

  getTrajetsActifs: async () => {
    const r = await pool.query(
      `SELECT
         t.id           AS trajet_id,
         t.latitude,
         t.longitude,
         t.vitesse,
         t.updated_at   AS derniere_maj,
         l.id           AS ligne_id,
         l.numero       AS ligne_numero,
         l.nom          AS ligne_nom,
         v.immatriculation,
         v.marque,
         c.nom          AS conducteur_nom,
         c.prenom       AS conducteur_prenom,
         t.conducteur_id
       FROM trajet t
       JOIN ligne l ON l.id = t.ligne_id
       LEFT JOIN vehicule v ON v.id = t.vehicule_id
       JOIN conducteur c ON c.id = t.conducteur_id
       WHERE t.statut = 'en_cours'`
    );
    return r.rows;
  },
};

module.exports = TrajetModel;