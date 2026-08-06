const { LigneModel, ArretModel, HoraireModel } = require('../models/ligne.model');
const pool = require('../db/pool');

const getPropId = async (compteId) => {
  const r = await pool.query(
    'SELECT id FROM proprietaire WHERE compte_id = $1', [compteId]
  );
  return r.rows[0]?.id;
};

const parsePoint = (pt) => {
  if (!pt) return null;
  const match = String(pt).match(/\(([^,]+),([^)]+)\)/);
  if (!match) return null;
  return { lat: parseFloat(match[1]), lng: parseFloat(match[2]) };
};

const toPoint = (lat, lng) =>
  (lat != null && lng != null) ? `(${lat},${lng})` : null;

// ══ LIGNE ══════════════════════════════════════════════════

const getLignes = async (req, res) => {
  try {
    const rows = req.user
      ? await LigneModel.getByProprietaire(await getPropId(req.user.id))
      : await LigneModel.getAll();
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const ajouterLigne = async (req, res) => {
  try {
    const { numero, nom, heure_debut, heure_fin,
            depart_lat, depart_lng, destination_lat, destination_lng } = req.body;
    if (!numero || !nom)
      return res.status(400).json({ message: 'Champs obligatoires manquants' });
    const propId = await getPropId(req.user.id);
    const ligne = await LigneModel.create({
      numero, nom, heure_debut, heure_fin, proprietaire_id: propId,
      depart_lat, depart_lng, destination_lat, destination_lng,
    });
    res.status(201).json({ message: 'Ligne ajoutée avec succès', ligne });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const modifierLigne = async (req, res) => {
  try {
    const ligneId = parseInt(req.params.id);
    const { numero, nom, heure_debut, heure_fin,
            depart_lat, depart_lng, destination_lat, destination_lng } = req.body;

    if (!numero || !nom)
      return res.status(400).json({ message: 'Champs obligatoires manquants' });

    const propId = await getPropId(req.user.id);
    const check = await pool.query(
      'SELECT id FROM ligne WHERE id = $1 AND proprietaire_id = $2',
      [ligneId, propId]
    );
    if (check.rows.length === 0)
      return res.status(403).json({ message: 'Ligne non autorisée' });

    const r = await pool.query(
      `UPDATE ligne SET
         numero = $1, nom = $2,
         heure_debut = $3, heure_fin = $4,
         position_depart_gps = $5,
         position_destination_gps = $6
       WHERE id = $7 RETURNING *`,
      [
        numero, nom, heure_debut, heure_fin,
        toPoint(depart_lat, depart_lng),
        toPoint(destination_lat, destination_lng),
        ligneId,
      ]
    );

    const ligne = {
      ...r.rows[0],
      position_depart_gps:      parsePoint(r.rows[0].position_depart_gps),
      position_destination_gps: parsePoint(r.rows[0].position_destination_gps),
    };

    res.json({ message: 'Ligne modifiée avec succès ✅', ligne });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const supprimerLigne = async (req, res) => {
  try {
    const ligneId = parseInt(req.params.id);
    const propId = await getPropId(req.user.id);
    const check = await pool.query(
      'SELECT id FROM ligne WHERE id = $1 AND proprietaire_id = $2',
      [ligneId, propId]
    );
    if (check.rows.length === 0)
      return res.status(403).json({ message: 'Ligne non autorisée' });
    await LigneModel.delete(ligneId);
    res.json({ message: 'Ligne supprimée' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ══ VÉHICULE ═══════════════════════════════════════════════

const getVehicules = async (req, res) => {
  try {
    const propId = await getPropId(req.user.id);
    const r = await pool.query(
      'SELECT id, marque, modele, immatriculation, capacite FROM vehicule WHERE proprietaire_id = $1',
      [propId]
    );
    res.json(r.rows);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const associerVehicule = async (req, res) => {
  const ligneId = parseInt(req.params.id);
  const { vehicule_id } = req.body;
  try {
if (Number.isNaN(ligneId) || !Number.isInteger(ligneId)) 
  return res.status(400).json({ message: 'ID ligne invalide' });    const propId = await getPropId(req.user.id);
    if (!propId) return res.status(403).json({ message: 'Propriétaire introuvable' });
    const checkLigne = await pool.query(
      'SELECT id, vehicule_id FROM ligne WHERE id = $1 AND proprietaire_id = $2',
      [ligneId, propId]
    );
    if (checkLigne.rows.length === 0)
      return res.status(403).json({ message: 'Ligne introuvable ou non autorisée' });
    if (vehicule_id === null || vehicule_id === undefined) {
      const enCours = await pool.query(
        `SELECT id FROM trajet WHERE ligne_id = $1 AND statut = 'en_cours' LIMIT 1`, [ligneId]
      );
      if (enCours.rows.length > 0)
        return res.status(409).json({ message: 'Impossible de dissocier : un trajet est en cours' });
      await LigneModel.updateVehicule(ligneId, null);
      return res.json({ message: 'Association supprimée avec succès ✅' });
    }
    const checkVeh = await pool.query(
      'SELECT id FROM vehicule WHERE id = $1 AND proprietaire_id = $2', [vehicule_id, propId]
    );
    if (checkVeh.rows.length === 0)
      return res.status(403).json({ message: 'Véhicule introuvable ou non autorisé' });
    const dejaAssocie = await pool.query(
      'SELECT id, numero FROM ligne WHERE vehicule_id = $1 AND id != $2', [vehicule_id, ligneId]
    );
    if (dejaAssocie.rows.length > 0)
      return res.status(409).json({ message: `Ce véhicule est déjà associé à la ligne ${dejaAssocie.rows[0].numero}` });
    await LigneModel.updateVehicule(ligneId, vehicule_id);
    const isModif = checkLigne.rows[0].vehicule_id !== null;
    res.json({ message: isModif ? 'Association modifiée ✅' : 'Association enregistrée ✅' });
  } catch (err) {
    console.error('[associerVehicule]', err.message);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ══ ARRÊTS ═════════════════════════════════════════════════

const getArrets = async (req, res) => {
  try { res.json(await ArretModel.getByLigne(req.params.id)); }
  catch (err) { console.error(err); res.status(500).json({ message: 'Erreur serveur' }); }
};

const ajouterArret = async (req, res) => {
  try {
    const ligneId = parseInt(req.params.id);
    const propId = await getPropId(req.user.id);
    const check = await pool.query(
      'SELECT id FROM ligne WHERE id = $1 AND proprietaire_id = $2',
      [ligneId, propId]
    );
    if (check.rows.length === 0)
      return res.status(403).json({ message: 'Ligne non autorisée' });
    const { nom, lat, lng, ordre } = req.body;
    if (!nom) return res.status(400).json({ message: "Nom de l'arrêt obligatoire" });
    const arret = await ArretModel.create({ ligne_id: ligneId, nom, lat, lng, ordre });
    res.status(201).json({ message: 'Arrêt ajouté avec succès', arret });
  } catch (err) { console.error(err); res.status(500).json({ message: 'Erreur serveur' }); }
};

const modifierArret = async (req, res) => {
  try {
    const ligneId = parseInt(req.params.id);
    const arretId = parseInt(req.params.arretId);
    const { nom, lat, lng, ordre } = req.body;
    const propId = await getPropId(req.user.id);
    const check = await pool.query(
      'SELECT a.id FROM arret a JOIN ligne l ON l.id = a.ligne_id WHERE a.id = $1 AND l.proprietaire_id = $2',
      [arretId, propId]
    );
    if (check.rows.length === 0)
      return res.status(403).json({ message: 'Arrêt non autorisé' });
    const arret = await ArretModel.update(arretId, { nom, lat, lng, ordre });
    res.json({ message: 'Arrêt modifié', arret });
  } catch (err) { console.error(err); res.status(500).json({ message: 'Erreur serveur' }); }
};

const supprimerArret = async (req, res) => {
  try {
    const arretId = parseInt(req.params.arretId);
    const propId = await getPropId(req.user.id);
    const check = await pool.query(
      'SELECT a.id FROM arret a JOIN ligne l ON l.id = a.ligne_id WHERE a.id = $1 AND l.proprietaire_id = $2',
      [arretId, propId]
    );
    if (check.rows.length === 0)
      return res.status(403).json({ message: 'Arrêt non autorisé' });
    await ArretModel.delete(arretId);
    res.json({ message: 'Arrêt supprimé' });
  } catch (err) { console.error(err); res.status(500).json({ message: 'Erreur serveur' }); }
};

// ══ HORAIRES ═══════════════════════════════════════════════

const getHoraires = async (req, res) => {
  try { res.json(await HoraireModel.getByLigne(req.params.id)); }
  catch (err) { console.error(err); res.status(500).json({ message: 'Erreur serveur' }); }
};

const ajouterHoraire = async (req, res) => {
  try {
    const ligneId = parseInt(req.params.id);
    const propId = await getPropId(req.user.id);
    const check = await pool.query(
      'SELECT id FROM ligne WHERE id = $1 AND proprietaire_id = $2',
      [ligneId, propId]
    );
    if (check.rows.length === 0)
      return res.status(403).json({ message: 'Ligne non autorisée' });
    const { type, point_depart, heure_depart, depart_lat, depart_lng,
            point_arrivee, heure_arrivee, arrivee_lat, arrivee_lng, jours } = req.body;
    if (!point_depart || !heure_depart || !point_arrivee || !heure_arrivee)
      return res.status(400).json({ message: 'Champs obligatoires manquants' });
    const horaire = await HoraireModel.create({
      ligne_id: ligneId,
      point_depart, heure_depart, depart_lat, depart_lng,
      point_arrivee, heure_arrivee, arrivee_lat, arrivee_lng,
      jours_semaine: jours || [1,2,3,4,5,6,7],
      est_retour: type === 'retour',
    });
    res.status(201).json({ message: 'Horaire ajouté avec succès', horaire });
  } catch (err) { console.error(err); res.status(500).json({ message: 'Erreur serveur' }); }
};

const modifierHoraire = async (req, res) => {
  try {
    const horaireId = parseInt(req.params.horaireId);
    const {
      point_depart, heure_depart, depart_lat, depart_lng,
      point_arrivee, heure_arrivee, arrivee_lat, arrivee_lng,
      jours, type,
    } = req.body;

    if (!point_depart || !heure_depart || !point_arrivee || !heure_arrivee)
      return res.status(400).json({ message: 'Champs obligatoires manquants' });

    const propId = await getPropId(req.user.id);
    const check = await pool.query(
      'SELECT h.id FROM horaire h JOIN ligne l ON l.id = h.ligne_id WHERE h.id = $1 AND l.proprietaire_id = $2',
      [horaireId, propId]
    );
    if (check.rows.length === 0)
      return res.status(403).json({ message: 'Horaire non autorisé' });

    const horaire = await HoraireModel.update(horaireId, {
      point_depart, heure_depart, depart_lat, depart_lng,
      point_arrivee, heure_arrivee, arrivee_lat, arrivee_lng,
      jours_semaine: jours || [1,2,3,4,5,6,7],
      est_retour: type === 'retour',
    });

    res.json({ message: 'Horaire modifié ✅', horaire });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const supprimerHoraire = async (req, res) => {
  try {
    const horaireId = parseInt(req.params.horaireId);
    const propId = await getPropId(req.user.id);
    const check = await pool.query(
      'SELECT h.id FROM horaire h JOIN ligne l ON l.id = h.ligne_id WHERE h.id = $1 AND l.proprietaire_id = $2',
      [horaireId, propId]
    );
    if (check.rows.length === 0)
      return res.status(403).json({ message: 'Horaire non autorisé' });
    await HoraireModel.delete(horaireId);
    res.json({ message: 'Horaire supprimé' });
  } catch (err) { console.error(err); res.status(500).json({ message: 'Erreur serveur' }); }
};

// ══════════════════════════════════════
// MODIFIER NB_BUS PAR LIGNE (Admin)
// ══════════════════════════════════════
const modifierNbBus = async (req, res) => {
  const { id } = req.params;
  const nb_bus = req.body.nb_bus ?? req.body.nb_bus_vendredi;
  try {
    if (!nb_bus || nb_bus < 1)
      return res.status(400).json({ message: 'Nombre de bus invalide' });

    const r = await pool.query(
      `UPDATE ligne SET nb_bus = $1 WHERE id = $2 RETURNING *`,
      [nb_bus, id]
    );
    if (!r.rows[0])
      return res.status(404).json({ message: 'Ligne introuvable' });

    res.json({ message: 'Nombre de bus mis à jour', ligne: r.rows[0] });
  } catch (err) {
    console.error('❌ modifierNbBus:', err);
    res.status(500).json({ message: 'Erreur serveur interne' });
  }
};

module.exports = {
  getLignes, ajouterLigne, modifierLigne, supprimerLigne,
  getVehicules, associerVehicule,
  getArrets, ajouterArret, modifierArret, supprimerArret,
  getHoraires, ajouterHoraire, modifierHoraire, supprimerHoraire,
  modifierNbBus,
};