const bcrypt         = require('bcryptjs');
const VisiteurModel  = require('../models/visiteur.model');

const sInscrire = async (req, res) => {
  const { nom, prenom, age, email, tel, adresse, mot_de_passe } = req.body;
  try {
    if (!nom || !prenom || !email || !mot_de_passe)
      return res.status(400).json({ message: 'Vérifiez les champs' });

    if (await VisiteurModel.emailExiste(email))
      return res.status(409).json({ message: 'Ce compte existe déjà' });

    const hash     = await bcrypt.hash(mot_de_passe, 10);
    const compteId = await VisiteurModel.creerCompte(email, hash);

    await VisiteurModel.creerVisiteur({
      nom, prenom, age, email, tel, adresse, compteId
    });

    res.status(201).json({
      message: 'Compte créé avec succès, vous pouvez vous connecter'
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = { sInscrire };