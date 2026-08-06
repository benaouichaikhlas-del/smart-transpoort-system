const pool = require('../db/pool');

const AffectationModel = {

  getByProprietaire: async (propId) => {
    const r = await pool.query(
      `SELECT a.*,
              c.nom AS conducteur_nom, c.prenom AS conducteur_prenom,
              v.marque, v.modele, v.immatriculation,
              l.numero AS ligne_numero, l.nom AS ligne_nom
       FROM affectation a
       JOIN conducteur c ON c.id = a.conducteur_id
       JOIN vehicule   v ON v.id = a.vehicule_id
       LEFT JOIN ligne l ON l.id = a.ligne_id
       WHERE c.proprietaire_id = $1
       ORDER BY a.created_at DESC`,
      [propId]
    );
    return r.rows;
  },

  conducteurAppartientProp: async (conducteurId, propId) => {
    const r = await pool.query(
      'SELECT id FROM conducteur WHERE id = $1 AND proprietaire_id = $2',
      [conducteurId, propId]
    );
    return r.rows.length > 0;
  },

  create: async ({ conducteur_id, vehicule_id, ligne_id }) => {
    await pool.query(
      `INSERT INTO affectation (conducteur_id, vehicule_id, ligne_id, actif)
       VALUES ($1,$2,$3,true)`,
      [conducteur_id, vehicule_id, ligne_id || null]
    );
  },
update: async ({ id, conducteur_id, vehicule_id, ligne_id }) => {
  await pool.query(
    `UPDATE affectation 
     SET conducteur_id=$1, vehicule_id=$2, ligne_id=$3
     WHERE id=$4`,
    [conducteur_id, vehicule_id, ligne_id || null, id]
  );
},
  delete: async (id) => {
    await pool.query('DELETE FROM affectation WHERE id = $1', [id]);
  },
};

module.exports = AffectationModel;