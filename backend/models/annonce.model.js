const pool = require('../db/pool');

const AnnonceModel = {

  getVisible: async () => {
    const r = await pool.query(
      `SELECT a.*, p.nom AS proprietaire_nom
       FROM annonce a
       JOIN proprietaire p ON p.id = a.proprietaire_id
       ORDER BY a.created_at DESC`
    );
    return r.rows;
  },

  create: async ({ titre, contenu, proprietaire_id }) => {
    const r = await pool.query(
      `INSERT INTO annonce (titre, contenu, proprietaire_id)
       VALUES ($1, $2, $3) RETURNING *`,
      [titre, contenu, proprietaire_id]
    );
    return r.rows[0];
  },

  delete: async (id) => {
    await pool.query('DELETE FROM annonce WHERE id = $1', [id]);
  },
};

module.exports = AnnonceModel;