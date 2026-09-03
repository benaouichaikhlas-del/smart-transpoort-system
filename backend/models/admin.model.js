const pool = require('../db/pool');

const AdminModel = {
  getDemandes: async () => {
    const r = await pool.query(
      'SELECT * FROM demande_inscription ORDER BY created_at DESC'
    );
    return r.rows;
  },

  getDemandeById: async (id) => {
    const r = await pool.query(
      'SELECT * FROM demande_inscription WHERE id = $1', [id]
    );
    return r.rows[0];
  },

  compteEmailExiste: async (email) => {
    const r = await pool.query(
      'SELECT id FROM compte WHERE LOWER(email) = LOWER($1)', [email]
    );
    return r.rows.length > 0;
  },

  // ✅ جيب الحساب بالإيميل (case-insensitive)
  getCompteByEmail: async (email) => {
    const r = await pool.query(
      'SELECT * FROM compte WHERE LOWER(email) = LOWER($1)', [email]
    );
    return r.rows[0];
  },

  // ✅ حدث الباسورد
  updateComptePassword: async (id, motDePasseHash) => {
    await pool.query(
      'UPDATE compte SET mot_de_passe = $1 WHERE id = $2',
      [motDePasseHash, id]
    );
  },

  // ✅ فعل الحساب وخليه proprietaire (هادي لازمة!)
  activerCompteProprietaire: async (id) => {
    const r = await pool.query(
      `UPDATE compte SET actif = true, role = 'proprietaire' WHERE id = $1 RETURNING id, email, actif, role`,
      [id]
    );
    return r.rows[0];
  },

  // ✅ شوف واش proprietaire موجود
  getProprietaireByEmail: async (email) => {
    const r = await pool.query(
      'SELECT * FROM proprietaire WHERE LOWER(email) = LOWER($1)', [email]
    );
    return r.rows[0];
  },

  creerCompteProprietaire: async (email, motDePasseHash) => {
    const r = await pool.query(
      `INSERT INTO compte (email, mot_de_passe, role, actif)
       VALUES ($1, $2, 'proprietaire', true) RETURNING id`,
      [email, motDePasseHash]
    );
    return r.rows[0].id;
  },

  creerProprietaire: async ({ nom, prenom, email, tel, adresse, compteId, age }) => {
    await pool.query(
      `INSERT INTO proprietaire (nom, prenom, email, tel, adresse, compte_id, age)
       VALUES ($1,$2,$3,$4,$5,$6,$7)`,
      [nom, prenom || null, email, tel || null, adresse || null, compteId, age || null]
    );
  },

  accepterDemande: async (id) => {
    await pool.query(
      `UPDATE demande_inscription SET statut = 'accepte' WHERE id = $1`, [id]
    );
  },

  refuserDemande: async (id) => {
    const r = await pool.query(
      `UPDATE demande_inscription SET statut = 'refuse' WHERE id = $1 RETURNING *`,
      [id]
    );
    return r.rows[0];
  },

  changerStatutDemande: async (id, statut) => {
    await pool.query(
      `UPDATE demande_inscription SET statut = $1 WHERE id = $2`,
      [statut, id]
    );
  },

  desactiverCompte: async (email) => {
    await pool.query(
      `UPDATE compte SET actif = false WHERE LOWER(email) = LOWER($1)`, [email]
    );
  },

  reactiverCompte: async (email) => {
    await pool.query(
      `UPDATE compte SET actif = true WHERE LOWER(email) = LOWER($1)`, [email]
    );
  },

  supprimerDemande: async (id) => {
    const r = await pool.query(
      `DELETE FROM demande_inscription WHERE id = $1 RETURNING *`, [id]
    );
    return r.rows[0];
  },

  getFeedbacks: async () => {
    const r = await pool.query(
      `SELECT f.*,
              l.numero AS ligne_numero, l.nom AS ligne_nom,
              c.email AS passager_email
       FROM feedback f
       LEFT JOIN ligne l ON l.id = f.ligne_id
       LEFT JOIN compte c ON c.id = f.passager_id
       ORDER BY f.created_at DESC`
    );
    return r.rows;
  },

  getSignalements: async () => {
    const r = await pool.query(
      `SELECT s.*,
              l.numero AS ligne_numero, l.nom AS ligne_nom,
              c.email AS passager_email
       FROM signalement s
       LEFT JOIN ligne l ON l.id = s.ligne_id
       LEFT JOIN compte c ON c.id = s.passager_id
       ORDER BY s.created_at DESC`
    );
    return r.rows;
  },

  getEvaluationsAvecMoyenne: async () => {
    const r = await pool.query(
      `SELECT e.*,
              l.numero AS ligne_numero, l.nom AS ligne_nom,
              c.email AS passager_email,
              ROUND(AVG(e.note) OVER (PARTITION BY e.ligne_id)::numeric, 1) AS moyenne_ligne
       FROM evaluation e
       JOIN ligne l ON l.id = e.ligne_id
       LEFT JOIN compte c ON c.id = e.passager_id
       ORDER BY e.created_at DESC`
    );
    return r.rows;
  },

  updateStatutSignalement: async (id, statut) => {
    await pool.query(
      `UPDATE signalement SET statut = $1 WHERE id = $2`, [statut, id]
    );
  },

  getSignalementById: async (id) => {
    const r = await pool.query(
      'SELECT * FROM signalement WHERE id = $1', [id]
    );
    return r.rows[0];
  },
};

module.exports = AdminModel;