const pool = require('../db/pool');
const PassagerModel = require('../models/passager.model');
const TrajetModel   = require('../models/trajet.model');

// ═══════════════════════════════════════════
// 🔧 Helper: Parse GPS Point
// ═══════════════════════════════════════════
const parsePoint = (pt) => {
  if (!pt) return null;
  const match = String(pt).match(/\(([^,]+),([^)]+)\)/);
  if (!match) return null;
  return { lat: parseFloat(match[1]), lng: parseFloat(match[2]) };
};

// ═══════════════════════════════════════════
// 🔒 Helper: vérifier que le compte est bien un "visiteur"
// (récupère le role directement en base, pas depuis le token,
// pour éviter tout token périmé/incohérent)
// ═══════════════════════════════════════════
const verifierRolePassager = async (compteId) => {
  const r = await pool.query('SELECT role FROM compte WHERE id = $1', [compteId]);
  const role = r.rows[0]?.role;
  return role === 'visiteur';
};

// ═══════════════════════════════════════════
// 1. PUBLIC — GET TRAJETS (anciennement dans trajet.controller)
// ═══════════════════════════════════════════
const getTrajets = async (req, res) => {
  try {
    const { search } = req.query;
    const rows = (search && search.trim())
      ? await TrajetModel.searchDisponibles(search.trim())
      : await TrajetModel.getDisponibles();
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══════════════════════════════════════════
// 2. PUBLIC — RETARDS & PANNES
// ═══════════════════════════════════════════
const getRetardsPannes = async (req, res) => {
  try {
    const data = await PassagerModel.getRetardsPannes();
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══════════════════════════════════════════
// 3. PUBLIC — MOYENNES LIGNES
// ═══════════════════════════════════════════
const getMoyennes = async (req, res) => {
  try {
    const rows = await PassagerModel.getMoyennesLignes();
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══════════════════════════════════════════
// 4. NEW PUBLIC — RECHERCHE LIGNES (avec calendrier)
// ═══════════════════════════════════════════
const rechercherLignes = async (req, res) => {
  try {
    const { search } = req.query;

    let query = `
      SELECT 
        l.id, l.numero, l.nom,
        l.heure_debut, l.heure_fin,
        l.position_depart_gps,
        l.position_destination_gps,
        COALESCE(v.capacite, 0) as places_total,
        v.marque, v.modele,
        COALESCE(ROUND(AVG(e.note)::numeric, 1), 0) as moyenne,
        COUNT(e.id) as nb_evaluations
      FROM ligne l
      LEFT JOIN vehicule v ON v.id = l.vehicule_id
      LEFT JOIN evaluation e ON e.ligne_id = l.id
      WHERE 1=1
    `;

    const params = [];

    if (search && search.trim()) {
      query += ` AND (LOWER(l.nom) LIKE LOWER($1) OR LOWER(l.numero) LIKE LOWER($1))`;
      params.push(`%${search.trim()}%`);
    }

    // ✅ الحل: نحول point إلى text فقط في GROUP BY
    query += ` GROUP BY l.id, l.numero, l.nom, l.heure_debut, l.heure_fin, 
         l.position_depart_gps::text, l.position_destination_gps::text, 
         v.capacite, v.marque, v.modele 
         ORDER BY l.numero`;

    const r = await pool.query(query, params);

    // parsePoint يبقى يخدم عادي
    const rows = r.rows.map(row => ({
      ...row,
      position_depart_gps: parsePoint(row.position_depart_gps),
      position_destination_gps: parsePoint(row.position_destination_gps),
    }));

    res.json(rows);
  } catch (err) {
    console.error('rechercherLignes error:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══════════════════════════════════════════
// 5. NEW PUBLIC — GET HORAIRES D'UNE LIGNE POUR UN JOUR
// ═══════════════════════════════════════════
const getHorairesLigne = async (req, res) => {
  try {
    const { id } = req.params;
    const { date } = req.query;

    if (!date) {
      return res.status(400).json({ message: 'Date requise (YYYY-MM-DD)' });
    }

    // PostgreSQL: 1=dimanche, 7=samedi
    const jourSemaine = new Date(date).getDay() + 1;

    const r = await pool.query(
      `SELECT 
         h.id, h.point_depart, h.heure_depart,
         h.point_arrivee, h.heure_arrivee,
         h.est_retour,
         t.id as trajet_id,
         t.places_dispo,
         t.places_total,
         COALESCE(t.places_dispo, v.capacite, 30) as places_restantes
       FROM horaire h
       LEFT JOIN vehicule v ON v.id = (
         SELECT vehicule_id FROM ligne WHERE id = $1
       )
       LEFT JOIN trajet t ON t.horaire_id = h.id AND t.date = $2::date
       WHERE h.ligne_id = $1
         AND $3 = ANY(h.jours_semaine)
       ORDER BY h.heure_depart`,
      [id, date, jourSemaine]
    );

    res.json(r.rows);
  } catch (err) {
    console.error('getHorairesLigne error:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══════════════════════════════════════════
// 6. PROTECTED — RÉSERVER (ancien, trajet déjà existant)
// ═══════════════════════════════════════════
const reserver = async (req, res) => {
  const { trajet_id, nb_places } = req.body;
  try {
    // 🔒 seuls les comptes "visiteur" peuvent réserver
    const estPassager = await verifierRolePassager(req.user.id);
    if (!estPassager) {
      return res.status(403).json({
        message: 'Seuls les passagers peuvent effectuer une réservation',
      });
    }

    if (!nb_places || nb_places < 1)
      return res.status(400).json({ message: 'Nombre de places invalide' });

    const passagerId = req.user.id;
    const trajet = await TrajetModel.getById(trajet_id);
    if (!trajet)
      return res.status(404).json({ message: 'Trajet introuvable' });

    if (trajet.places_dispo < nb_places)
      return res.status(400).json({
        message: `Seulement ${trajet.places_dispo} place(s) disponible(s)`,
      });

    const dejaReserve = await PassagerModel.getActiveReservation(passagerId, trajet_id);
    if (dejaReserve)
      return res.status(409).json({ message: 'Vous avez déjà une réservation active' });

    await PassagerModel.createReservation(passagerId, trajet_id, nb_places);
    await TrajetModel.updatePlaces(trajet_id, -nb_places);

    res.status(201).json({ message: `${nb_places} place(s) réservée(s) avec succès` });
  } catch (err) {
    console.error('reserver error:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══════════════════════════════════════════
// 7. NEW PROTECTED — RÉSERVER AVEC DATE (crée trajet si besoin)
// ═══════════════════════════════════════════
const reserverAvecDate = async (req, res) => {
  const client = await pool.connect();

  try {
    // 🔒 seuls les comptes "visiteur" peuvent réserver
    const estPassager = await verifierRolePassager(req.user.id);
    if (!estPassager) {
      client.release();
      return res.status(403).json({
        message: 'Seuls les passagers peuvent effectuer une réservation',
      });
    }

    await client.query('BEGIN');

    const { ligne_id, horaire_id, date, nb_places } = req.body;
    const passagerId = req.user.id;

    if (!nb_places || nb_places < 1) {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: 'Nombre de places invalide' });
    }

    // 1. Chercher trajet existant
    let trajetResult = await client.query(
      `SELECT * FROM trajet WHERE horaire_id = $1 AND date = $2::date FOR UPDATE`,
      [horaire_id, date]
    );

    let trajet;

    // 2. Créer trajet si existe pas
       // 2. Créer trajet si existe pas
    if (trajetResult.rows.length === 0) {
      const horaire = await client.query(
        `SELECT * FROM horaire WHERE id = $1`, [horaire_id]
      );

      if (horaire.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ message: 'Horaire introuvable' });
      }

      const h = horaire.rows[0];
      
      // ✅ نجيب vehicule_id من ligne
      const ligne = await client.query(
        `SELECT vehicule_id FROM ligne WHERE id = $1`, [ligne_id]
      );

      if (ligne.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ message: 'Ligne introuvable' });
      }

      // ✅ نجيب conducteur_id من affectation
      const affectation = await client.query(
        `SELECT conducteur_id FROM affectation 
         WHERE ligne_id = $1 AND actif = true 
         LIMIT 1`,
        [ligne_id]
      );
      const conducteurId = affectation.rows[0]?.conducteur_id || null;

      const vehicule = await client.query(
        `SELECT capacite FROM vehicule WHERE id = $1`,
        [ligne.rows[0]?.vehicule_id]
      );

      const capacite = vehicule.rows[0]?.capacite || 30;

      const newTrajet = await client.query(
        `INSERT INTO trajet 
         (ligne_id, vehicule_id, conducteur_id, horaire_id, date,
          heure_depart, heure_arrivee, 
          places_total, places_dispo, statut, created_at)
         VALUES ($1, $2, $3, $4, $5::date, $6, $7, $8, $8, 'disponible', NOW())
         RETURNING *`,
        [
          ligne_id,
          ligne.rows[0]?.vehicule_id,
          conducteurId,  // ← من affectation
          horaire_id,
          date,
          h.heure_depart,
          h.heure_arrivee,
          capacite
        ]
      );

      trajet = newTrajet.rows[0];
    } else {
      trajet = trajetResult.rows[0];
    }

    // 3. Vérifier places
    if (trajet.places_dispo < nb_places) {
      await client.query('ROLLBACK');
      return res.status(409).json({
        message: `Il ne reste que ${trajet.places_dispo} place(s)`
      });
    }

    // 4. Vérifier pas déjà réservé
    const dejaReserve = await client.query(
      `SELECT id FROM reservation 
       WHERE passager_id = $1 AND trajet_id = $2 AND statut = 'active'`,
      [passagerId, trajet.id]
    );

    if (dejaReserve.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ message: 'Déjà réservé' });
    }

    // 5. Créer réservation
    const reservation = await client.query(
      `INSERT INTO reservation 
       (passager_id, trajet_id, nb_places, statut, created_at)
       VALUES ($1, $2, $3, 'active', NOW())
       RETURNING *`,
      [passagerId, trajet.id, nb_places]
    );

    // 6. Mettre à jour places
    await client.query(
      `UPDATE trajet SET places_dispo = places_dispo - $1 WHERE id = $2`,
      [nb_places, trajet.id]
    );

    await client.query('COMMIT');

    res.status(201).json({
      message: 'Réservation confirmée ✅',
      reservation: reservation.rows[0],
      trajet: {
        id: trajet.id,
        date: trajet.date,
        heure_depart: trajet.heure_depart,
        heure_arrivee: trajet.heure_arrivee,
        places_dispo: trajet.places_dispo - nb_places
      }
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('reserverAvecDate error:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  } finally {
    client.release();
  }
};

// ═══════════════════════════════════════════
// 8. PROTECTED — MES RÉSERVATIONS
// ═══════════════════════════════════════════
const getMesReservations = async (req, res) => {
  try {
    const rows = await PassagerModel.getMesReservations(req.user.id);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══════════════════════════════════════════
// 9. PROTECTED — MODIFIER RÉSERVATION
// ═══════════════════════════════════════════
const modifierReservation = async (req, res) => {
  const { id } = req.params;
  const { nb_places } = req.body;
  try {
    const resa = await PassagerModel.getReservationById(id, req.user.id);
    if (!resa)
      return res.status(404).json({ message: 'Réservation introuvable' });

    const diff   = nb_places - resa.nb_places;
    const trajet = await TrajetModel.getById(resa.trajet_id);
    if (trajet.places_dispo < diff)
      return res.status(400).json({ message: 'Pas assez de places disponibles' });

    await PassagerModel.updateReservation(id, nb_places);
    await TrajetModel.updatePlaces(resa.trajet_id, -diff);

    res.json({ message: 'Réservation modifiée avec succès' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══════════════════════════════════════════
// 10. PROTECTED — ANNULER RÉSERVATION
// ═══════════════════════════════════════════
const annulerReservation = async (req, res) => {
  const { id } = req.params;
  try {
    const resa = await PassagerModel.getReservationById(id, req.user.id);
    if (!resa)
      return res.status(404).json({ message: 'Réservation introuvable' });

    await PassagerModel.annulerReservation(id);
    await TrajetModel.updatePlaces(resa.trajet_id, +resa.nb_places);

    res.json({ message: 'Réservation annulée avec succès' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══════════════════════════════════════════
// 11. PROTECTED — ÉVALUER LIGNE
// ═══════════════════════════════════════════
const evaluerLigne = async (req, res) => {
  const { ligne_id, note, commentaire } = req.body;
  try {
    if (!note || note < 1 || note > 5)
      return res.status(400).json({ message: 'Note invalide (1 à 5)' });

    if (!ligne_id)
      return res.status(400).json({ message: 'Ligne requise' });

    const passagerId = req.user.id;

    const ancienneEval = await PassagerModel.getEvaluationByPassager(passagerId, ligne_id);

    if (ancienneEval) {
      await PassagerModel.updateEvaluation(ancienneEval.id, note, commentaire);
      return res.status(200).json({ message: 'Évaluation mise à jour !' });
    }

    await PassagerModel.createEvaluation(passagerId, ligne_id, note, commentaire);
    res.status(201).json({ message: 'Évaluation enregistrée, merci !' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══════════════════════════════════════════
// 12. PROTECTED — MES ÉVALUATIONS
// ═══════════════════════════════════════════
const getMesEvaluations = async (req, res) => {
  try {
    const rows = await PassagerModel.getEvaluationsByPassager(req.user.id);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══════════════════════════════════════════
// 13. PROTECTED — GET ÉVALUATIONS (publique ou perso)
// ═══════════════════════════════════════════
const getEvaluations = async (req, res) => {
  try {
    if (!req.user) return res.json([]);
    const rows = await PassagerModel.getEvaluationsByPassager(req.user.id);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══════════════════════════════════════════
// 14. PROTECTED — SIGNALER PROBLÈME
// ═══════════════════════════════════════════
const signalerProbleme = async (req, res) => {
  const { ligne_id, type, description } = req.body;
  try {
    if (!description || description.trim() === '')
      return res.status(400).json({ message: 'Description requise' });

    if (!['retard', 'panne', 'autre'].includes(type))
      return res.status(400).json({ message: 'Type invalide' });

    if (type === 'retard' || type === 'panne') {
      const conducteur = await PassagerModel.getConducteurPourSignalement(ligne_id);
      if (!conducteur)
        return res.status(422).json({ message: 'Aucun conducteur disponible' });

      if (type === 'retard') {
        await PassagerModel.createRetard(conducteur.id, ligne_id, description);
      } else {
        await PassagerModel.createPanne(conducteur.id, ligne_id, description);
      }
    } else {
      await PassagerModel.signalerAutre(req.user.id, ligne_id, description);
    }

    if (ligne_id) {
      const prop = await PassagerModel.getProprietaireLigne(ligne_id);
      if (prop) {
        await PassagerModel.insertNotification({
          passager_id: prop.compte_id,
          titre: '🚨 Signalement problème',
          message: `Type: ${type} — ${description}`,
          type: 'signalement',
        });
      }
    }

    res.status(201).json({ message: 'Signalement envoyé, merci !' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══════════════════════════════════════════
// 15. PROTECTED — ENVOYER FEEDBACK
// ═══════════════════════════════════════════
const envoyerFeedback = async (req, res) => {
  const { contenu, ligne_id } = req.body;
  try {
    if (!contenu || contenu.trim() === '')
      return res.status(400).json({ message: 'Contenu requis' });

    await PassagerModel.createFeedback(req.user.id, ligne_id || null, contenu.trim());

    if (ligne_id) {
      const prop = await PassagerModel.getProprietaireLigne(ligne_id);
      if (prop) {
        await PassagerModel.insertNotification({
          passager_id: prop.compte_id,
          titre: '💬 Nouveau feedback',
          message: contenu.trim(),
          type: 'feedback',
        });
      }
    }

    res.status(201).json({ message: 'Feedback envoyé, merci !' });
  } catch (err) {
    console.error('FEEDBACK ERROR:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
}
const modifierComptePassager = async (req, res) => {
  try {
    const compteId = req.user.id;
    const { email, tel, mot_de_passe_actuel, nouveau_mot_de_passe } = req.body;

    const current = await pool.query(
      'SELECT * FROM compte WHERE id = $1', [compteId]
    );
    if (current.rows.length === 0) {
      return res.status(404).json({ message: 'Compte introuvable' });
    }

    const compte = current.rows[0];
    const updates = [];
    const values = [];
    let idx = 1;

    if (email) {
      updates.push(`email = $${idx++}`);
      values.push(email);
    }

    if (tel) {
      updates.push(`tel = $${idx++}`);
      values.push(tel);
    }

    if (mot_de_passe_actuel && nouveau_mot_de_passe) {
      const bcrypt = require('bcryptjs');
      const match = await bcrypt.compare(mot_de_passe_actuel, compte.mot_de_passe);
      if (!match) {
        return res.status(400).json({ message: 'Mot de passe actuel incorrect' });
      }
      const hashed = await bcrypt.hash(nouveau_mot_de_passe, 10);
      updates.push(`mot_de_passe = $${idx++}`);
      values.push(hashed);
    }

    if (updates.length === 0) {
      return res.status(400).json({ message: 'Aucune donnée à modifier' });
    }

    values.push(compteId);
    const query = `UPDATE compte SET ${updates.join(', ')} WHERE id = $${idx} RETURNING id, email, tel, role`;

    const result = await pool.query(query, values);
    const updatedUser = result.rows[0];

    // ✅ أنشئ توكن JWT جديد بالبيانات المحدّثة
    const jwt = require('jsonwebtoken');
    const token = jwt.sign(
      { 
        id: updatedUser.id, 
        email: updatedUser.email, 
        tel: updatedUser.tel,
        role: updatedUser.role
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    console.log('✅ Nouveau token généré:', token); // ← تأكد

    res.json({ 
      message: 'Compte modifié avec succès ✅',
      token: token,        // ← يجب أن يكون موجود
      compte: updatedUser
    });
  } catch (err) {
    console.error('❌ modifierComptePassager:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
// ═══════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════
module.exports = {
  // PUBLIC
  getTrajets,
  getRetardsPannes,
  getMoyennes,
  rechercherLignes,
  getHorairesLigne,
  // PROTECTED
  reserver,
  reserverAvecDate,
  getMesReservations,
  modifierReservation,
  annulerReservation,
  evaluerLigne,
  getEvaluations,
  getMesEvaluations,
  signalerProbleme,
  envoyerFeedback,
  modifierComptePassager,
};