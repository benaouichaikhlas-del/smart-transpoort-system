const pool = require('../db/pool');

const ConducteurActionsModel = {

  getIdByCompte: async (compteId) => {
    const r = await pool.query(
      'SELECT id FROM conducteur WHERE compte_id = $1', [compteId]
    );
    return r.rows[0]?.id;
  },

  getAffectationActive: async (condId) => {
    const r = await pool.query(
      `SELECT ligne_id, vehicule_id, created_at 
       FROM affectation
       WHERE conducteur_id = $1 AND actif = true
       ORDER BY created_at DESC LIMIT 1`,
      [condId]
    );
    return r.rows[0];
  },

  // ── TRAJET ACTIF ──
  getTrajetActif: async (ligneId) => {
    const r = await pool.query(
      `SELECT id, places_total, places_dispo, date, date_fin, heure_depart, heure_arrivee
       FROM trajet 
       WHERE ligne_id = $1 
         AND date <= CURRENT_DATE
         AND (date_fin >= CURRENT_DATE OR date_fin IS NULL)
       ORDER BY heure_depart DESC LIMIT 1`,
      [ligneId]
    );
    if (!r.rows[0]) {
      const r2 = await pool.query(
        `SELECT id, places_total, places_dispo, date, date_fin, heure_depart, heure_arrivee
         FROM trajet WHERE ligne_id = $1
         ORDER BY date DESC, heure_depart DESC LIMIT 1`,
        [ligneId]
      );
      return r2.rows[0] || null;
    }
    return r.rows[0];
  },

  // ── GPS ──
  upsertPosition: async ({ condId, ligneId, latitude, longitude, vitesse }) => {
    await pool.query(
      `INSERT INTO position_bus
         (conducteur_id, ligne_id, latitude, longitude, vitesse, actif, updated_at)
       VALUES ($1, $2, $3, $4, $5, true, NOW())
       ON CONFLICT (conducteur_id)
       DO UPDATE SET
         latitude   = EXCLUDED.latitude,
         longitude  = EXCLUDED.longitude,
         vitesse    = EXCLUDED.vitesse,
         ligne_id   = EXCLUDED.ligne_id,
         actif      = true,
         updated_at = NOW()`,
      [condId, ligneId || null, latitude, longitude, vitesse || 0]
    );
  },

  desactiverGPS: async (condId) => {
    await pool.query(
      `UPDATE position_bus SET actif = false, updated_at = NOW()
       WHERE conducteur_id = $1`,
      [condId]
    );
  },

 

  insertRetard: async ({ condId, duree_minutes, motif, ligneId }) => {
    const r = await pool.query(
      `INSERT INTO retard (conducteur_id, duree_minutes, motif, ligne_id, statut, created_at)
       VALUES ($1, $2, $3, $4, 'en_attente', NOW())
       RETURNING id`,
      [condId, duree_minutes, motif || null, ligneId || null]
    );
    return r.rows[0]?.id;
  },

  // ── PANNE ──
  panneActiveExiste: async (condId) => {
    const r = await pool.query(
      `SELECT id FROM panne
       WHERE conducteur_id = $1 AND statut = 'en_cours'
       LIMIT 1`,
      [condId]
    );
    return r.rows[0];
  },

  insertPanne: async ({ condId, typePanne, description, ligneId }) => {
    const r = await pool.query(
      `INSERT INTO panne (conducteur_id, description, ligne_id, statut, resolue, created_at)
       VALUES ($1, $2, $3, 'en_cours', false, NOW())
       RETURNING id`,
      [condId, `${typePanne} — ${description}`, ligneId || null]
    );
    return r.rows[0]?.id;
  },

  // ── JUSTIFICATION ──
  getDeclarationsEnAttente: async (condId) => {
    const retards = await pool.query(
      `SELECT id, 'retard' AS type, motif AS description,
              duree_minutes, created_at
       FROM retard
       WHERE conducteur_id = $1 AND statut = 'en_attente'
       ORDER BY created_at DESC`,
      [condId]
    );
    const pannes = await pool.query(
      `SELECT id, 'panne' AS type, description,
              NULL AS duree_minutes, created_at
       FROM panne
       WHERE conducteur_id = $1 AND statut = 'en_attente'
       ORDER BY created_at DESC`,
      [condId]
    );
    return [...retards.rows, ...pannes.rows].sort(
      (a, b) => new Date(b.created_at) - new Date(a.created_at)
    );
  },

  justificationDejaExiste: async (type, declarationId) => {
    const table = type === 'retard' ? 'retard' : 'panne';
    const r = await pool.query(
      `SELECT justification FROM ${table}
       WHERE id = $1 AND justification IS NOT NULL`,
      [declarationId]
    );
    return r.rows.length > 0;
  },

  insertJustification: async ({ type, declarationId, justification }) => {
    const table = type === 'retard' ? 'retard' : 'panne';
    await pool.query(
      `UPDATE ${table} SET justification = $1 WHERE id = $2`,
      [justification, declarationId]
    );
  },

  // ── ESPACES VIDES ──
  getPlacesLigne: async (ligneId) => {
    const trajet = await ConducteurActionsModel.getTrajetActif(ligneId);
    if (!trajet) {
      return { places_total: 0, places_dispo: 0, places_reservees: 0, trajet_id: null };
    }
    return {
      places_total: trajet.places_total,
      places_dispo: trajet.places_dispo,
      places_reservees: trajet.places_total - trajet.places_dispo,
      trajet_id: trajet.id
    };
  },

  updatePlacesDispo: async ({ ligneId, nouvellesPlaces, capaciteMax }) => {
    if (nouvellesPlaces < 0 || nouvellesPlaces > capaciteMax) {
      throw new Error(`Valeur invalide: entre 0 et ${capaciteMax}`);
    }
    await pool.query(
      `UPDATE trajet SET places_dispo = $1 WHERE ligne_id = $2`,
      [nouvellesPlaces, ligneId]
    );
  },

  // ── PERMANENCES ──
  getPermanences: async (condId) => {
    const r = await pool.query(
      `SELECT * FROM permanence WHERE conducteur_id = $1 ORDER BY id`,
      [condId]
    );
    return r.rows;
  },

 getReservationsLigne: async (ligneId) => {
    const r = await pool.query(
      `SELECT res.id, res.passager_id, res.trajet_id, res.statut, res.created_at,
             res.nb_places,
             co.email AS passager_email,
             co.role AS compte_role,
             v.nom AS visiteur_nom,
             v.prenom AS visiteur_prenom,
             v.tel AS visiteur_telephone,
             t.places_total, t.places_dispo,
             t.date AS date_reservation,
             t.heure_depart, t.heure_arrivee
       FROM reservation res
       JOIN trajet t ON t.id = res.trajet_id
       LEFT JOIN compte co ON co.id = res.passager_id
       LEFT JOIN visiteur v ON v.compte_id = co.id
       WHERE t.ligne_id = $1 AND res.statut = 'active'
       ORDER BY res.created_at DESC`,
      [ligneId]
    );
    
    // ✅ Debug: شوفي شنو كيرجع
    console.log('🔍 [getReservationsLigne] Raw rows:', JSON.stringify(r.rows, null, 2));
    
    return r.rows;
  },
  getLigne: async (ligneId) => {
    const r = await pool.query('SELECT * FROM ligne WHERE id = $1', [ligneId]);
    return r.rows[0];
  },

  getLigneNumero: async (ligneId) => {
    const r = await pool.query('SELECT numero FROM ligne WHERE id = $1', [ligneId]);
    return r.rows[0]?.numero || '';
  },

  getPlacesSummary: async (ligneId) => {
    const trajet = await ConducteurActionsModel.getTrajetActif(ligneId);
    if (!trajet) {
      return { places_total: 0, places_dispo: 0, trajet_id: null };
    }
    return {
      places_total: trajet.places_total,
      places_dispo: trajet.places_dispo,
      trajet_id: trajet.id
    };
  },

  // ── PASSAGERS LIGNE ──
  getPassagersLigne: async (ligneId) => {
    const r = await pool.query(
      `SELECT DISTINCT co.id, co.email, v.nom, v.prenom, v.tel AS telephone
       FROM compte co
       JOIN reservation res ON res.passager_id = co.id
       JOIN trajet t ON t.id = res.trajet_id
       LEFT JOIN visiteur v ON v.compte_id = co.id
       WHERE t.ligne_id = $1 AND res.statut = 'active'`,
      [ligneId]
    );
    return r.rows;
  },

  // ── NOTIFICATION ──
 insertNotification: async ({ passager_id, titre, message, type, expiresAt, panneId, retardId }) => {
    await pool.query(
      `INSERT INTO notification (passager_id, titre, message, type)
       VALUES ($1, $2, $3, $4)`,
      [passager_id, titre, message, type]
    );
  },
    // ── NOTIFICATIONS MISE À JOUR ──
  insertNotification: async ({ passager_id, titre, message, type, expiresAt, panneId, retardId }) => {
    await pool.query(
      `INSERT INTO notification (passager_id, titre, message, type, expires_at, panne_id, retard_id, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())`,
      [passager_id, titre, message, type, expiresAt, panneId || null, retardId || null]
    );
  },

  getNotificationsActives: async (passagerId) => {
    const r = await pool.query(
      `SELECT * FROM notification 
       WHERE passager_id = $1 
         AND (expires_at IS NULL OR expires_at > NOW())
       ORDER BY created_at DESC`,
      [passagerId]
    );
    return r.rows;
  },

  expireNotificationsByRetard: async (retardId) => {
    await pool.query(
      `UPDATE notification SET expires_at = NOW() 
       WHERE retard_id = $1 AND (expires_at IS NULL OR expires_at > NOW())`,
      [retardId]
    );
  },

  expireNotificationsByPanne: async (panneId) => {
    await pool.query(
      `UPDATE notification SET expires_at = NOW() 
       WHERE panne_id = $1 AND (expires_at IS NULL OR expires_at > NOW())`,
      [panneId]
    );
  },

  // ── RETARD MISE À JOUR ──
 retardDejaDeclareePourTrajet: async (condId, ligneId) => {
  // ✅ نحلو تلقائياً أي روطار "خلصت مدتو" (created_at + duree_minutes <= الآن)
  await pool.query(
    `UPDATE retard SET statut = 'resolu'
     WHERE conducteur_id = $1
       AND statut = 'en_attente'
       AND created_at + (duree_minutes || ' minutes')::interval <= NOW()`,
    [condId]
  );

  const r = await pool.query(
    `SELECT id FROM retard
     WHERE conducteur_id = $1
       AND ligne_id = $2
       AND statut = 'en_attente'
       AND created_at + (duree_minutes || ' minutes')::interval > NOW()
     ORDER BY created_at DESC LIMIT 1`,
    [condId, ligneId]
  );
  return r.rows[0];
},
};

module.exports = ConducteurActionsModel;