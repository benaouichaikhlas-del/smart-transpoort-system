const bcrypt       = require('bcryptjs');
const CompteModel  = require('../models/compte.model');

const modifierCompte = async (req, res) => {
  const { email, mot_de_passe } = req.body;
  try {
    if (email)
      await CompteModel.updateEmail(req.user.id, email);

    if (mot_de_passe) {
      const hash = await bcrypt.hash(mot_de_passe, 10);
      await CompteModel.updateMotDePasse(req.user.id, hash);
    }

    res.json({ message: 'Compte modifié avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const supprimerCompte = async (req, res) => {
  try {
    await CompteModel.delete(req.user.id);
    res.json({ message: 'Compte supprimé avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = { modifierCompte, supprimerCompte };