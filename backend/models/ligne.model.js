const pool = require('../db/pool');

// ════════════════════════════════════════════
// Helpers GPS
// ════════════════════════════════════════════
const parsePoint = (pt) => {
  if (!pt) return null;
  const match = String(pt).match(/\(([^,]+),([^)]+)\)/);
  if (!match) return null;
  return { lat: parseFloat(match[1]), lng: parseFloat(match[2]) };
};

const toPoint = (lat, lng) =>
  (lat != null && lng != null) ? `(${lat},${lng})` : null;

// ════════════════════════════════════════════
// LIGNE MODEL
// ════════════════════════════════════════════
const LigneModel = {

  getByProprietaire: async (propId) => {
    const r = await pool.query(
      `SELECT l.*,
              v.marque          AS vehicule_marque,
              v.modele          AS vehicule_modele,
              v.immatriculation AS vehicule_immat,
              v.etat            AS vehicule_etat
       FROM ligne l
       LEFT JOIN vehicule v ON v.id = l.vehicule_id
       WHERE l.proprietaire_id = $1
       ORDER BY l.numero`,
      [propId]
    );
    return r.rows.map(row => ({
      ...row,
      position_depart_gps:      parsePoint(row.position_depart_gps),
      position_destination_gps: parsePoint(row.position_destination_gps),
    }));
  },

  // جيب خط واحد بكل معلوماته (بما فيها nb_bus)
  getById: async (id) => {
    const r = await pool.query('SELECT * FROM ligne WHERE id = $1', [id]);
    return r.rows[0] || null;
  },

  getAll: async () => {
    const r = await pool.query(
      `SELECT l.*,
              v.marque          AS vehicule_marque,
              v.modele          AS vehicule_modele,
              v.immatriculation AS vehicule_immat,
              v.etat            AS vehicule_etat
       FROM ligne l
       LEFT JOIN vehicule v ON v.id = l.vehicule_id
       ORDER BY l.numero`
    );
    return r.rows.map(row => ({
      ...row,
      position_depart_gps:      parsePoint(row.position_depart_gps),
      position_destination_gps: parsePoint(row.position_destination_gps),
    }));
  },

  create: async ({ numero, nom, heure_debut, heure_fin, proprietaire_id,
                   depart_lat, depart_lng, destination_lat, destination_lng }) => {
    const r = await pool.query(
      `INSERT INTO ligne
         (numero, nom, heure_debut, heure_fin, proprietaire_id,
          position_depart_gps, position_destination_gps)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       RETURNING *`,
      [
        numero, nom, heure_debut, heure_fin, proprietaire_id,
        toPoint(depart_lat, depart_lng),
        toPoint(destination_lat, destination_lng),
      ]
    );
    return r.rows[0];
  },

  updateVehicule: async (ligneId, vehiculeId) => {
    const r = await pool.query(
      `UPDATE ligne SET vehicule_id = $1 WHERE id = $2 RETURNING *`,
      [vehiculeId ?? null, ligneId]
    );
    return r.rows[0];
  },

  // تحديث عدد الحافلات المطلوبة لخط معين
  updateNbBus: async (ligneId, nbBus) => {
    const r = await pool.query(
      `UPDATE ligne SET nb_bus = $1 WHERE id = $2 RETURNING *`,
      [nbBus, ligneId]
    );
    return r.rows[0];
  },

  delete: async (id) => {
    await pool.query('DELETE FROM ligne WHERE id = $1', [id]);
  },
};

// ════════════════════════════════════════════
// ARRET MODEL
// ════════════════════════════════════════════
const ArretModel = {

  getByLigne: async (ligneId) => {
    const r = await pool.query(
      `SELECT * FROM arret WHERE ligne_id = $1 ORDER BY ordre`,
      [ligneId]
    );
    return r.rows.map(row => ({
      ...row,
      position_gps: parsePoint(row.position_gps),
    }));
  },

  create: async ({ ligne_id, nom, lat, lng, ordre }) => {
    const r = await pool.query(
      `INSERT INTO arret (ligne_id, nom, position_gps, ordre)
       VALUES ($1,$2,$3,$4) RETURNING *`,
      [ligne_id, nom, toPoint(lat, lng), ordre ?? 0]
    );
    return r.rows[0];
  },

  update: async (id, { nom, lat, lng, ordre }) => {
    const r = await pool.query(
      `UPDATE arret SET nom = $1, position_gps = $2, ordre = $3
       WHERE id = $4 RETURNING *`,
      [nom, toPoint(lat, lng), ordre ?? 0, id]
    );
    return r.rows[0];
  },

  delete: async (id) => {
    await pool.query('DELETE FROM arret WHERE id = $1', [id]);
  },
};

// ════════════════════════════════════════════
// HORAIRE MODEL
// ════════════════════════════════════════════
const HoraireModel = {

  getByLigne: async (ligneId) => {
    const r = await pool.query(
      `SELECT * FROM horaire WHERE ligne_id = $1 ORDER BY heure_depart`,
      [ligneId]
    );
    return r.rows.map(row => ({
      ...row,
      position_depart_gps:  parsePoint(row.position_depart_gps),
      position_arrivee_gps: parsePoint(row.position_arrivee_gps),
    }));
  },

  create: async ({
    ligne_id,
    point_depart, heure_depart, depart_lat, depart_lng,
    point_arrivee, heure_arrivee, arrivee_lat, arrivee_lng,
    jours_semaine, est_retour, horaire_aller_id,
  }) => {
    const r = await pool.query(
      `INSERT INTO horaire
         (ligne_id,
          point_depart, heure_depart, position_depart_gps,
          point_arrivee, heure_arrivee, position_arrivee_gps,
          jours_semaine, est_retour, horaire_aller_id)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
       RETURNING *`,
      [
        ligne_id,
        point_depart, heure_depart, toPoint(depart_lat, depart_lng),
        point_arrivee, heure_arrivee, toPoint(arrivee_lat, arrivee_lng),
        jours_semaine ?? [1,2,3,4,5,6,7],
        est_retour ?? false,
        horaire_aller_id ?? null,
      ]
    );
    return r.rows[0];
  },

  update: async (id, {
    point_depart, heure_depart, depart_lat, depart_lng,
    point_arrivee, heure_arrivee, arrivee_lat, arrivee_lng,
    jours_semaine, est_retour,
  }) => {
    const r = await pool.query(
      `UPDATE horaire SET
         point_depart = $1, heure_depart = $2, position_depart_gps = $3,
         point_arrivee = $4, heure_arrivee = $5, position_arrivee_gps = $6,
         jours_semaine = $7, est_retour = $8
       WHERE id = $9 RETURNING *`,
      [
        point_depart, heure_depart, toPoint(depart_lat, depart_lng),
        point_arrivee, heure_arrivee, toPoint(arrivee_lat, arrivee_lng),
        jours_semaine ?? [1,2,3,4,5,6,7],
        est_retour ?? false,
        id,
      ]
    );
    return r.rows[0];
  },

  delete: async (id) => {
    await pool.query('DELETE FROM horaire WHERE id = $1', [id]);
  },
};

module.exports = { LigneModel, ArretModel, HoraireModel };