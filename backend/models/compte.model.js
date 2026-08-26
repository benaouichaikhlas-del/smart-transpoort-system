const pool = require('../db/pool');

const CompteModel = {
  // ─── READ ───
  getById: async (id) => {
    const result = await pool.query(
      'SELECT * FROM compte WHERE id = $1',
      [id]
    );
    return result.rows[0];
  },

  // ─── UPDATE EMAIL ───
  updateEmail: async (id, email) => {
    const result = await pool.query(
      'UPDATE compte SET email = $1 WHERE id = $2 RETURNING *',
      [email, id]
    );
    return result.rows[0];
  },

  // ─── UPDATE PASSWORD ───
  updateMotDePasse: async (id, hash) => {
    const result = await pool.query(
      'UPDATE compte SET mot_de_passe = $1 WHERE id = $2 RETURNING *',
      [hash, id]
    );
    return result.rows[0];
  },

  // ─── DELETE ───
  delete: async (id) => {
    await pool.query('DELETE FROM compte WHERE id = $1', [id]);
    return { message: 'Compte supprimé' };
  },
};

module.exports = CompteModel;