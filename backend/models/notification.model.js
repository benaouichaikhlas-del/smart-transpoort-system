const pool = require('../db/pool');

const NotificationModel = {

  // ── Créer notification PRIVÉE (غير للركاب اللي ريزارفاو) ──
  createWithRef: async (passagerId, titre, message, type, expiresAt, panneId = null, retardId = null) => {
    await pool.query(
      `INSERT INTO notification 
         (passager_id, titre, message, type, scope, expires_at, panne_id, retard_id, lu, created_at)
       VALUES ($1, $2, $3, $4, 'private', $5, $6, $7, false, NOW())`,
      [passagerId, titre, message, type, expiresAt, panneId, retardId]
    );
  },

  // ── Créer notification PUBLIQUE (للجميع) ──
  createPublic: async (titre, message, type, expiresAt, panneId = null, retardId = null) => {
    await pool.query(
      `INSERT INTO notification 
         (passager_id, titre, message, type, scope, expires_at, panne_id, retard_id, lu, created_at)
       VALUES (NULL, $1, $2, $3, 'public', $4, $5, $6, false, NOW())`,
      [titre, message, type, expiresAt, panneId, retardId]
    );
  },

  // ── Récupérer notifications (خاصة + عامة) ──
  getByPassager: async (passagerId) => {
    const r = await pool.query(
      `SELECT * FROM notification 
       WHERE (passager_id = $1 OR scope = 'public')
         AND (expires_at IS NULL OR expires_at > NOW())
       ORDER BY created_at DESC`,
      [passagerId]
    );
    return r.rows;
  },

  // ── Compter non lues (خاصة + عامة) ──
  countNonLues: async (passagerId) => {
    const r = await pool.query(
      `SELECT COUNT(*) FROM notification 
       WHERE (passager_id = $1 OR scope = 'public')
         AND lu = false
         AND (expires_at IS NULL OR expires_at > NOW())`,
      [passagerId]
    );
    return parseInt(r.rows[0].count);
  },

  // ── Marquer lu ──
  marquerLu: async (id, passagerId) => {
    await pool.query(
      `UPDATE notification SET lu = true 
       WHERE id = $1 AND (passager_id = $2 OR scope = 'public')`,
      [id, passagerId]
    );
  },

  // ── Marquer tous lus ──
  marquerTousLus: async (passagerId) => {
    await pool.query(
      `UPDATE notification SET lu = true 
       WHERE (passager_id = $1 OR scope = 'public')
         AND lu = false`,
      [passagerId]
    );
  },

  // ── Supprimer par panne_id ──
  deleteByPanneId: async (panneId) => {
    await pool.query(
      `DELETE FROM notification WHERE panne_id = $1`,
      [panneId]
    );
  },
  expireByPanneId: async (panneId) => {
  await pool.query(
    `UPDATE notification SET expires_at = NOW() WHERE panne_id = $1 AND (expires_at IS NULL OR expires_at > NOW())`,
    [panneId]
  );
},

  // ── Supprimer par retard_id ──
  deleteByRetardId: async (retardId) => {
    await pool.query(
      `DELETE FROM notification WHERE retard_id = $1`,
      [retardId]
    );
  },

  // ── Cleanup manuel ──
  deleteExpired: async () => {
    const r = await pool.query(
      `DELETE FROM notification WHERE expires_at IS NOT NULL AND expires_at < NOW()`
    );
    return r.rowCount;
  },
};

module.exports = NotificationModel;