const pool = require('../db/pool');

const PermanenceModel = {

  // ── جيب كل الـ permanences (admin) ──
  getAll: async () => {
    const r = await pool.query(
      `SELECT 
         p.*,
         c.nom    AS conducteur_nom,
         c.prenom AS conducteur_prenom,
         l.numero AS ligne_numero,
         l.nom    AS ligne_nom
       FROM permanence p
       JOIN conducteur c ON c.id = p.conducteur_id
       LEFT JOIN ligne l ON l.id = p.ligne_id
       ORDER BY p.date DESC`
    );
    return r.rows;
  },

  // ── جيب permanences كونديكتور واحد ──
  getByConducteur: async (conducteurId) => {
    const r = await pool.query(
      `SELECT 
         p.*,
         l.numero AS ligne_numero,
         l.nom    AS ligne_nom
       FROM permanence p
       LEFT JOIN ligne l ON l.id = p.ligne_id
       WHERE p.conducteur_id = $1
       ORDER BY p.date DESC`,
      [conducteurId]
    );
    return r.rows;
  },

  // ── جيب permanences خط واحد ──
  getByLigne: async (ligneId) => {
    const r = await pool.query(
      `SELECT 
         p.*,
         c.nom    AS conducteur_nom,
         c.prenom AS conducteur_prenom
       FROM permanence p
       JOIN conducteur c ON c.id = p.conducteur_id
       WHERE p.ligne_id = $1
       ORDER BY p.date DESC`,
      [ligneId]
    );
    return r.rows;
  },

  // ── جيب آخر permanence للخط ──
  getLastByLigne: async (ligneId) => {
    const r = await pool.query(
      `SELECT conducteur_id FROM permanence 
       WHERE ligne_id = $1 AND repos = false
       ORDER BY date DESC LIMIT 1`,
      [ligneId]
    );
    return r.rows[0] || null;
  },

  // ── تحقق إذا الجمعة محجوزة ──
  existsByDateAndLigne: async (date, ligneId) => {
    const r = await pool.query(
      `SELECT id FROM permanence 
       WHERE ligne_id = $1 AND date = $2 AND repos = false`,
      [ligneId, date]
    );
    return r.rows.length > 0;
  },

  // ── عدد البارمانونس في تاريخ وخط معين ──
  countByDateAndLigne: async (date, ligneId) => {
    const r = await pool.query(
      `SELECT COUNT(*) FROM permanence WHERE ligne_id = $1 AND date = $2 AND repos = false`,
      [ligneId, date]
    );
    return parseInt(r.rows[0].count, 10);
  },

  // ── جيب الكونديكتورين المسندين في تاريخ وخط معين ──
  getConducteursAssignes: async (date, ligneId) => {
    const r = await pool.query(
      `SELECT conducteur_id FROM permanence WHERE ligne_id = $1 AND date = $2 AND repos = false`,
      [ligneId, date]
    );
    return r.rows.map(row => row.conducteur_id);
  },

  // ── عدد كل البارمانونس للخط ──
  getTotalCountByLigne: async (ligneId) => {
    const r = await pool.query(
      `SELECT COUNT(*) FROM permanence WHERE ligne_id = $1 AND repos = false`,
      [ligneId]
    );
    return parseInt(r.rows[0].count, 10);
  },

  // ── إنشاء permanence ──
  create: async ({ conducteur_id, date, heure_debut, heure_fin, ligne_id }) => {
    const r = await pool.query(
      `INSERT INTO permanence 
         (conducteur_id, jour, date, heure_debut, heure_fin, ligne_id, repos, created_at)
       VALUES ($1, 'Vendredi', $2, $3, $4, $5, false, NOW())
       RETURNING *`,
      [conducteur_id, date, heure_debut, heure_fin, ligne_id]
    );
    return r.rows[0];
  },

  // ── حذف permanence ──
  delete: async (id) => {
    await pool.query('DELETE FROM permanence WHERE id = $1', [id]);
  },

  // ── جيب كل الكونديكتورين للخط (للـ rotation) ──
  getConducteursByLigne: async (ligneId) => {
    const r = await pool.query(
      `SELECT c.id, c.nom, c.prenom 
       FROM conducteur c
       JOIN affectation a ON a.conducteur_id = c.id AND a.actif = true
       WHERE a.ligne_id = $1
       ORDER BY c.id`,
      [ligneId]
    );
    return r.rows;
  },
};

module.exports = PermanenceModel;