const pool = require('../db/pool');

const ProprietaireModel = {

  getId: async (compteId) => {
    const r = await pool.query(
      'SELECT id FROM proprietaire WHERE compte_id = $1', [compteId]
    );
    return r.rows[0]?.id;
  },

  findNumero: async (numero) => {
    const r = await pool.query(
      `SELECT id, est_utilise FROM numeros_proprietaire WHERE numero = $1`,
      [numero]
    );
    return r.rows[0] || null;
  },

  findDemandeByNumero: async (numero) => {
    const r = await pool.query(
      `SELECT id FROM demande_inscription 
       WHERE numero_proprietaire = $1 
       AND statut IN ('en_attente', 'accepte')`,
      [numero]
    );
    return r.rows[0] || null;
  },

  findDemandeByTel: async (tel) => {
    const r = await pool.query(
      `SELECT id FROM demande_inscription 
       WHERE tel = $1 
       AND statut IN ('en_attente', 'accepte')`,
      [tel]
    );
    return r.rows[0] || null;
  },

  demanderInscription: async ({ nom, prenom, age, email, tel, adresse, hash, numero_proprietaire }) => {
    await pool.query(
      `INSERT INTO demande_inscription
       (nom, prenom, age, email, tel, adresse, mot_de_passe, statut, numero_proprietaire)
       VALUES ($1,$2,$3,$4,$5,$6,$7,'en_attente',$8)`,
      [nom, prenom, age, email, tel, adresse, hash, numero_proprietaire]
    );
  },

  getFeedbacksPourMoi: async (proprietaireId) => {
    const r = await pool.query(
      `SELECT f.*, l.numero AS ligne_numero, l.nom AS ligne_nom,
              c.email AS passager_email
       FROM feedback f
       LEFT JOIN ligne l ON l.id = f.ligne_id
       LEFT JOIN proprietaire p ON p.id = l.proprietaire_id
       LEFT JOIN compte c ON c.id = f.passager_id
       WHERE p.id = $1 OR f.ligne_id IS NULL
       ORDER BY f.created_at DESC`,
      [proprietaireId]
    );
    return r.rows;
  },

  getEvaluationsPourMoi: async (proprietaireId) => {
    const r = await pool.query(
      `SELECT e.*, l.numero AS ligne_numero, l.nom AS ligne_nom,
              c.email AS passager_email,
              ROUND(AVG(e.note) OVER (PARTITION BY e.ligne_id)::numeric, 1) AS moyenne_ligne
       FROM evaluation e
       JOIN ligne l ON l.id = e.ligne_id
       JOIN proprietaire p ON p.id = l.proprietaire_id
       LEFT JOIN compte c ON c.id = e.passager_id
       WHERE p.id = $1
       ORDER BY e.created_at DESC`,
      [proprietaireId]
    );
    return r.rows;
  },

  getSignalementsPourMoi: async (proprietaireId) => {
    const r = await pool.query(
      `SELECT s.*, l.numero AS ligne_numero, l.nom AS ligne_nom,
              c.email AS passager_email
       FROM signalement s
       LEFT JOIN ligne l ON l.id = s.ligne_id
       LEFT JOIN proprietaire p ON p.id = l.proprietaire_id
       LEFT JOIN compte c ON c.id = s.passager_id
       WHERE p.id = $1 OR s.ligne_id IS NULL
       ORDER BY s.created_at DESC`,
      [proprietaireId]
    );
    return r.rows;
  },

};

module.exports = ProprietaireModel;