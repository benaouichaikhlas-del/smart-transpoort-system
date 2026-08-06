const pool = require('../db/pool');

const ConducteurModel = {

  // ── جلب كل الكوندويكتاريه تاع بروبريتار معين ──
  getByProprietaire: async (proprietaireId) => {
    const r = await pool.query(
      `SELECT c.id, c.nom, c.prenom, c.age, c.telephone, c.num_permis,
              c.adresse, c.statut, c.proprietaire_id, c.compte_id, c.created_at,
              co.email
       FROM conducteur c
       LEFT JOIN compte co ON co.id = c.compte_id
       WHERE c.proprietaire_id = $1
       ORDER BY c.created_at DESC`,
      [proprietaireId]
    );
    return r.rows;
  },

  // ── جلب كوندويكتار بالـ id، فقط إذا كان تاع هاد البروبريتار (أمان) ──
  getByIdAndProp: async (id, proprietaireId) => {
    const r = await pool.query(
      `SELECT * FROM conducteur WHERE id = $1 AND proprietaire_id = $2`,
      [id, proprietaireId]
    );
    return r.rows[0];
  },

  // ── جلب كوندويكتار بالـ compte_id (يستعملها الكوندويكتار نفسو: mon-profil) ──
  getByCompteId: async (compteId) => {
    const r = await pool.query(
      `SELECT c.id, c.nom, c.prenom, c.age, c.telephone, c.num_permis,
              c.adresse, c.statut, c.proprietaire_id, c.compte_id, c.created_at,
              co.email
       FROM conducteur c
       LEFT JOIN compte co ON co.id = c.compte_id
       WHERE c.compte_id = $1`,
      [compteId]
    );
    return r.rows[0];
  },

  // ── تحقق: هل الإيميل مستعمل (فـ compte) ──
  emailExiste: async (email) => {
    const r = await pool.query('SELECT id FROM compte WHERE email = $1', [email]);
    return r.rows.length > 0;
  },

  // ── تحقق: هل رقم الهاتف مستعمل (excludeId لتجاهل الكوندويكتار الحالي عند التعديل) ──
  telephoneExiste: async (telephone, excludeId = null) => {
    const query = excludeId
      ? 'SELECT id FROM conducteur WHERE telephone = $1 AND id != $2'
      : 'SELECT id FROM conducteur WHERE telephone = $1';
    const params = excludeId ? [telephone, excludeId] : [telephone];
    const r = await pool.query(query, params);
    return r.rows.length > 0;
  },

  // ── تحقق: هل رقم البرمي مستعمل ──
  permisExiste: async (numPermis, excludeId = null) => {
    const query = excludeId
      ? 'SELECT id FROM conducteur WHERE num_permis = $1 AND id != $2'
      : 'SELECT id FROM conducteur WHERE num_permis = $1';
    const params = excludeId ? [numPermis, excludeId] : [numPermis];
    const r = await pool.query(query, params);
    return r.rows.length > 0;
  },

  // ── إنشاء compte جديد (role='conducteur') ويرجع الـ id تاعو ──
  creerCompte: async (email, hash) => {
    const r = await pool.query(
      `INSERT INTO compte (email, mot_de_passe, role, actif, premier_connexion, created_at)
       VALUES ($1, $2, 'conducteur', true, true, NOW())
       RETURNING id`,
      [email, hash]
    );
    return r.rows[0].id;
  },

  // ── إنشاء سطر conducteur جديد ──
  create: async ({ nom, prenom, age, telephone, num_permis, adresse, proprietaire_id, compte_id }) => {
    const r = await pool.query(
      `INSERT INTO conducteur
         (nom, prenom, age, telephone, num_permis, adresse, proprietaire_id, compte_id, statut, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'actif', NOW())
       RETURNING *`,
      [nom, prenom, age, telephone, num_permis, adresse, proprietaire_id, compte_id]
    );
    return r.rows[0];
  },

  // ── تعديل من طرف البروبريتار ──
  update: async ({ id, nom, prenom, age, telephone, num_permis, adresse }) => {
    const r = await pool.query(
      `UPDATE conducteur SET
         nom        = COALESCE($2, nom),
         prenom     = COALESCE($3, prenom),
         age        = COALESCE($4, age),
         telephone  = COALESCE($5, telephone),
         num_permis = COALESCE($6, num_permis),
         adresse    = COALESCE($7, adresse)
       WHERE id = $1
       RETURNING *`,
      [id, nom, prenom, age, telephone, num_permis, adresse]
    );
    return r.rows[0];
  },

  // ── تعديل من طرف الكوندويكتار نفسو (مون كومت) ──
  updateMonCompte: async ({ compteId, nom, prenom, age, telephone, adresse }) => {
    const r = await pool.query(
      `UPDATE conducteur SET
         nom       = COALESCE($2, nom),
         prenom    = COALESCE($3, prenom),
         age       = COALESCE($4, age),
         telephone = COALESCE($5, telephone),
         adresse   = COALESCE($6, adresse)
       WHERE compte_id = $1
       RETURNING *`,
      [compteId, nom, prenom, age, telephone, adresse]
    );
    return r.rows[0];
  },

  // ── تحديث الإيميل (فـ compte) ──
  updateEmail: async (compteId, email) => {
    if (!compteId) return;
    await pool.query('UPDATE compte SET email = $1 WHERE id = $2', [email, compteId]);
  },

  // ── حذف سطر conducteur بالـ id ──
  deleteById: async (id) => {
    await pool.query('DELETE FROM conducteur WHERE id = $1', [id]);
  },

  // ── حذف سطر conducteur اللي مرتبط بـ compte_id معين ──
  // (فـ supprimerConducteur تُستدعى بعد deleteById كـ no-op أمان زايد؛
  //  فـ supprimerMonCompte تحذف السطر قبل ما CompteModel.delete يحذف compte)
  deleteByCompteId: async (compteId) => {
    await pool.query('DELETE FROM conducteur WHERE compte_id = $1', [compteId]);
  },

};

module.exports = ConducteurModel;