const pool = require('../db/pool');

const VisiteurModel = {

  emailExiste: async (email) => {
    const r = await pool.query(
      'SELECT id FROM compte WHERE email = $1', [email]
    );
    return r.rows.length > 0;
  },

  creerCompte: async (email, hash) => {
    const r = await pool.query(
      `INSERT INTO compte (email, mot_de_passe, role, actif)
       VALUES ($1, $2, 'visiteur', true) RETURNING id`,
      [email, hash]
    );
    return r.rows[0].id;
  },

  creerVisiteur: async ({ nom, prenom, age, email, tel, adresse, compteId }) => {
    await pool.query(
      `INSERT INTO visiteur (nom, prenom, age, email, tel, adresse, compte_id)
       VALUES ($1,$2,$3,$4,$5,$6,$7)`,
      [nom, prenom, age, email, tel, adresse, compteId]
    );
  },
};

module.exports = VisiteurModel;