const AnnonceModel      = require('../models/annonce.model');
const ProprietaireModel = require('../models/proprietaire.model');

const getAnnonces = async (req, res) => {
  try {
    const rows = await AnnonceModel.getVisible();
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const envoyerAnnonce = async (req, res) => {
  const { titre, contenu } = req.body;
  try {
    const propId = await ProprietaireModel.getId(req.user.id);
    await AnnonceModel.create({ titre, contenu, proprietaire_id: propId });
    res.status(201).json({ message: 'Annonce envoyée' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const supprimerAnnonce = async (req, res) => {
  try {
    await AnnonceModel.delete(req.params.id);
    res.json({ message: 'Annonce supprimée' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = { getAnnonces, envoyerAnnonce, supprimerAnnonce };