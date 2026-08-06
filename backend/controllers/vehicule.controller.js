const VehiculeModel = require('../models/vehicule.model');
const pool          = require('../db/pool');

const getPropId = async (compteId) => {
  const r = await pool.query(
    'SELECT id FROM proprietaire WHERE compte_id = $1', [compteId]
  );
  return r.rows[0]?.id ?? null;
};

// GET /api/vehicule
const getVehicules = async (req, res) => {
  try {
    const propId = await getPropId(req.user.id);
    if (!propId) return res.status(404).json({
      message: 'Propriétaire introuvable. Vérifiez que votre compte est bien validé.',
      code: 'PROPRIETAIRE_NOT_FOUND'
    });
    const rows = await VehiculeModel.getByProprietaire(propId);
    res.json(rows);
  } catch (err) {
    console.error('[getVehicules]', err.message);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// POST /api/vehicule
const ajouterVehicule = async (req, res) => {
  const { marque, modele, immatriculation, capacite,
          couleur, puissance, annee_service, type_vehicule,
          wilaya_mat, type_mat, serie_mat, annee_mat } = req.body;
  try {
    if (!marque?.trim())
      return res.status(400).json({ message: 'La marque est obligatoire' });
    if (!immatriculation?.trim())
      return res.status(400).json({ message: "L'immatriculation est obligatoire" });

    const propId = await getPropId(req.user.id);
    if (!propId) return res.status(404).json({
      message: 'Propriétaire introuvable', code: 'PROPRIETAIRE_NOT_FOUND'
    });

    await VehiculeModel.create({
      marque: marque.trim(), modele: modele?.trim() || null,
      immatriculation: immatriculation.trim().toUpperCase(),
      capacite: parseInt(capacite) || 30,
      proprietaire_id: propId,
      couleur: couleur || '#3B82F6',
      puissance: puissance ? parseInt(puissance) : null,
      annee_service: annee_service ? parseInt(annee_service) : null,
      type_vehicule: type_vehicule || null,
      wilaya_mat: wilaya_mat || null, type_mat: type_mat || null,
      serie_mat: serie_mat || null, annee_mat: annee_mat || null,
    });

    res.status(201).json({ message: 'Véhicule ajouté avec succès ✅' });
  } catch (err) {
    console.error('[ajouterVehicule]', err.message);
    if (err.code === '23505')
      return res.status(409).json({ message: `Immatriculation déjà enregistrée` });
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// PUT /api/vehicule/:id
const modifierVehicule = async (req, res) => {
  const { marque, modele, immatriculation, capacite, etat,
          couleur, puissance, annee_service, type_vehicule,
          wilaya_mat, type_mat, serie_mat, annee_mat } = req.body;
  const id = parseInt(req.params.id);
  try {
    if (!id || isNaN(id))
      return res.status(400).json({ message: 'ID invalide' });

    const propId = await getPropId(req.user.id);
    if (!propId) return res.status(404).json({ message: 'Propriétaire introuvable' });

    const check = await pool.query(
      'SELECT id FROM vehicule WHERE id = $1 AND proprietaire_id = $2', [id, propId]
    );
    if (check.rows.length === 0)
      return res.status(403).json({ message: 'Véhicule introuvable ou non autorisé' });

    await VehiculeModel.update({
      id, marque: marque?.trim(), modele: modele?.trim() || null,
      immatriculation: immatriculation?.trim().toUpperCase(),
      capacite: parseInt(capacite) || 30, etat: etat || 'actif',
      couleur: couleur || '#3B82F6',
      puissance: puissance ? parseInt(puissance) : null,
      annee_service: annee_service ? parseInt(annee_service) : null,
      type_vehicule: type_vehicule || null,
      wilaya_mat: wilaya_mat || null, type_mat: type_mat || null,
      serie_mat: serie_mat || null, annee_mat: annee_mat || null,
    });

    res.json({ message: 'Véhicule modifié avec succès ✅' });
  } catch (err) {
    console.error('[modifierVehicule]', err.message);
    if (err.code === '23505')
      return res.status(409).json({ message: 'Immatriculation déjà existante' });
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// DELETE /api/vehicule/:id
const supprimerVehicule = async (req, res) => {
  const id = parseInt(req.params.id);
  try {
    if (!id || isNaN(id))
      return res.status(400).json({ message: 'ID invalide' });

    const propId = await getPropId(req.user.id);
    if (!propId) return res.status(404).json({ message: 'Propriétaire introuvable' });

    const check = await pool.query(
      'SELECT id FROM vehicule WHERE id = $1 AND proprietaire_id = $2', [id, propId]
    );
    if (check.rows.length === 0)
      return res.status(403).json({ message: 'Véhicule introuvable ou non autorisé' });

    await VehiculeModel.delete(id);
    res.json({ message: 'Véhicule supprimé avec succès ✅' });
  } catch (err) {
    console.error('[supprimerVehicule]', err.message);
    if (err.code === '23503')
      return res.status(409).json({
        message: 'Impossible de supprimer : véhicule affecté à une ligne ou conducteur'
      });
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = { getVehicules, ajouterVehicule, modifierVehicule, supprimerVehicule };