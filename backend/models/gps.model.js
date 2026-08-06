const pool = require('../db/pool');

const GpsModel = {

  getConducteurId: async (compteId) => {
    const r = await pool.query(
      'SELECT id FROM conducteur WHERE compte_id = $1', [compteId]
    );
    return r.rows[0]?.id;
  },

  upsertPosition: async ({ conducteurId, ligne_id, latitude, longitude, vitesse }) => {
    await pool.query(
      `INSERT INTO position_bus
         (conducteur_id, ligne_id, latitude, longitude, vitesse, actif, updated_at)
       VALUES ($1,$2,$3,$4,$5,true,NOW())
       ON CONFLICT (conducteur_id)
       DO UPDATE SET
         latitude   = EXCLUDED.latitude,
         longitude  = EXCLUDED.longitude,
         vitesse    = EXCLUDED.vitesse,
         ligne_id   = EXCLUDED.ligne_id,
         actif      = true,
         updated_at = NOW()`,
      [conducteurId, ligne_id || null, latitude, longitude, vitesse || 0]
    );
  },

  desactiverGPS: async (conducteurId) => {
    await pool.query(
      `UPDATE position_bus SET actif = false, updated_at = NOW()
       WHERE conducteur_id = $1`,
      [conducteurId]
    );
  },

  getPositionByLigne: async (ligneId) => {
  const r = await pool.query(
    `SELECT pb.conducteur_id,
            pb.latitude, pb.longitude, pb.vitesse, pb.updated_at,
            c.nom AS conducteur_nom, c.prenom AS conducteur_prenom,
            l.numero AS ligne_numero, l.nom AS ligne_nom,
            l.id AS ligne_id
     FROM position_bus pb
     JOIN conducteur c ON c.id = pb.conducteur_id
     LEFT JOIN ligne l ON l.id = pb.ligne_id
     WHERE pb.ligne_id = $1
       AND pb.actif = true
       AND pb.updated_at > NOW() - INTERVAL '10 minutes'  -- ← بدل 2
     ORDER BY pb.updated_at DESC`,
    [ligneId]
  );
  return r.rows;
},
 getToutesPositions: async () => {
  const r = await pool.query(
    `SELECT pb.conducteur_id,  -- ← زيد هذا
            pb.latitude, pb.longitude, pb.vitesse, pb.updated_at,
            pb.ligne_id,
            c.nom AS conducteur_nom,
            l.numero AS ligne_numero, l.nom AS ligne_nom
     FROM position_bus pb
     JOIN conducteur c ON c.id = pb.conducteur_id
     LEFT JOIN ligne l ON l.id = pb.ligne_id
     WHERE pb.actif = true
       AND pb.updated_at > NOW() - INTERVAL '2 minutes'`
  );
  return r.rows;
},
};

module.exports = GpsModel;