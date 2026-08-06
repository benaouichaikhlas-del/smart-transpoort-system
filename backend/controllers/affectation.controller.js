const pool = require('../db/pool');

// ── helper: جيب id الـ proprietaire من compte_id ──
const getPropId = async (compteId) => {
  const r = await pool.query(
    'SELECT id FROM proprietaire WHERE compte_id = $1',
    [compteId]
  );
  return r.rows[0]?.id;
};

// ══════════════════════════════════════
// GET /api/affectation
// ══════════════════════════════════════
const getAffectations = async (req, res) => {
  try {
    const propId = await getPropId(req.user.id);
    if (!propId) return res.status(403).json({ message: 'Propriétaire introuvable' });

    const result = await pool.query(
      `SELECT a.*,
              c.nom  AS conducteur_nom,
              c.prenom AS conducteur_prenom,
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
    res.json(result.rows);
  } catch (err) {
    console.error('getAffectations:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ══════════════════════════════════════
// POST /api/affectation
// ══════════════════════════════════════
const ajouterAffectation = async (req, res) => {
  const { conducteur_id, vehicule_id, ligne_id } = req.body;
  try {
    if (!conducteur_id || !vehicule_id) {
      return res.status(400).json({ message: 'conducteur_id et vehicule_id obligatoires' });
    }

    const propId = await getPropId(req.user.id);
    if (!propId) return res.status(403).json({ message: 'Propriétaire introuvable' });

    // تحقق أن الكوندويكتار تبع نفس الـ proprietaire
    const check = await pool.query(
      'SELECT id FROM conducteur WHERE id = $1 AND proprietaire_id = $2',
      [conducteur_id, propId]
    );
    if (check.rows.length === 0) {
      return res.status(403).json({ message: 'Conducteur non autorisé' });
    }

    await pool.query(
      `INSERT INTO affectation (conducteur_id, vehicule_id, ligne_id, actif)
       VALUES ($1, $2, $3, true)`,
      [conducteur_id, vehicule_id, ligne_id || null]
    );

    res.status(201).json({ message: 'Affectation créée avec succès' });
  } catch (err) {
    console.error('ajouterAffectation:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
// PUT /api/affectations/:id
const modifierAffectation = async (req, res) => {
  const { conducteur_id, vehicule_id, ligne_id } = req.body;
  const id = parseInt(req.params.id);

  try {
    if (!conducteur_id || !vehicule_id) {
      return res.status(400).json({ message: 'conducteur_id et vehicule_id obligatoires' });
    }

    const propId = await getPropId(req.user.id);
    if (!propId) return res.status(403).json({ message: 'Propriétaire introuvable' });

    // تحقق أن الكوندويكتار تبع نفس البروبريتار
    const check = await pool.query(
      'SELECT id FROM conducteur WHERE id = $1 AND proprietaire_id = $2',
      [conducteur_id, propId]
    );
    if (check.rows.length === 0) {
      return res.status(403).json({ message: 'Conducteur non autorisé' });
    }

    await pool.query(
      `UPDATE affectation SET conducteur_id=$1, vehicule_id=$2, ligne_id=$3 WHERE id=$4`,
      [conducteur_id, vehicule_id, ligne_id || null, id]
    );

    res.json({ message: 'Affectation modifiée avec succès ✅' });
  } catch (err) {
    console.error('modifierAffectation:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};


// ══════════════════════════════════════
// DELETE /api/affectation/:id
// ══════════════════════════════════════
const supprimerAffectation = async (req, res) => {
  try {
    await pool.query('DELETE FROM affectation WHERE id = $1', [req.params.id]);
    res.json({ message: 'Affectation supprimée' });
  } catch (err) {
    console.error('supprimerAffectation:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = { getAffectations, ajouterAffectation, modifierAffectation, supprimerAffectation };
