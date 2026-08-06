const pool = require('../db/pool');

const AuthModel = {

  getByEmail: async (email) => {
    const r = await pool.query(
      'SELECT * FROM compte WHERE email = $1', [email]
    );
    return r.rows[0];
  },

  getById: async (id) => {
    const r = await pool.query(
      'SELECT * FROM compte WHERE id = $1', [id]
    );
    return r.rows[0] || null;
  },

  // ✅ صحيح — c.tel (في compte)
  getByTelVisiteur: async (tel) => {
    const r = await pool.query(
      `SELECT c.* FROM compte c
       JOIN visiteur v ON v.compte_id = c.id
       WHERE c.tel = $1`, [tel]
    );
    return r.rows[0];
  },

  // ✅ جديد — passager
  getByTelPassager: async (tel) => {
    const r = await pool.query(
      `SELECT c.* FROM compte c
       JOIN passager p ON p.compte_id = c.id
       WHERE c.tel = $1`, [tel]
    );
    return r.rows[0];
  },

  getByTelConducteur: async (tel) => {
    const r = await pool.query(
      `SELECT c.* FROM compte c
       JOIN conducteur cd ON cd.compte_id = c.id
       WHERE cd.telephone = $1`, [tel]
    );
    return r.rows[0];
  },

  getByTelProprietaire: async (tel) => {
    const r = await pool.query(
      `SELECT c.* FROM compte c
       JOIN proprietaire p ON p.compte_id = c.id
       WHERE p.tel = $1`, [tel]
    );
    return r.rows[0];
  },

  getUserInfoVisiteur: async (compteId) => {
    const r = await pool.query(
      'SELECT nom, prenom, age, tel FROM visiteur WHERE compte_id = $1',
      [compteId]
    );
    return r.rows[0];
  },

  // ✅ جديد
  getUserInfoPassager: async (compteId) => {
    const r = await pool.query(
      'SELECT nom, prenom, age, tel FROM passager WHERE compte_id = $1',
      [compteId]
    );
    return r.rows[0];
  },

  getUserInfoProprietaire: async (compteId) => {
    const r = await pool.query(
      'SELECT nom, prenom, age, tel FROM proprietaire WHERE compte_id = $1',
      [compteId]
    );
    return r.rows[0];
  },

  getUserInfoConducteur: async (compteId) => {
    const r = await pool.query(
      'SELECT nom, prenom, telephone AS tel FROM conducteur WHERE compte_id = $1',
      [compteId]
    );
    return r.rows[0];
  },

  changerMotDePasse: async (compteId, hash) => {
    await pool.query(
      `UPDATE compte SET mot_de_passe = $1, premier_connexion = false
       WHERE id = $2`,
      [hash, compteId]
    );
  },
  // ── ajouts pour "mot de passe oublié" ──

  setResetCode: async (compteId, code, expiresAt) => {
    await pool.query(
      `UPDATE compte SET reset_code = $1, reset_expires = $2 WHERE id = $3`,
      [code, expiresAt, compteId]
    );
  },

  clearResetCode: async (compteId) => {
    await pool.query(
      `UPDATE compte SET reset_code = NULL, reset_expires = NULL WHERE id = $1`,
      [compteId]
    );
  },
};

module.exports = AuthModel;