const bcrypt    = require('bcryptjs');
const jwt       = require('jsonwebtoken');
const AuthModel = require('../models/auth.model');
const { envoyerCodeReset } = require('../config/mailer');

const sAuthentifier = async (req, res) => {
  const { email, mot_de_passe } = req.body;
  try {
    let compte = null;

    // 1. email
    if (email && email.includes('@')) {
      compte = await AuthModel.getByEmail(email);
    }
    // 2. tel visiteur (باساجي)
    if (!compte) compte = await AuthModel.getByTelVisiteur(email);
    // 3. tel passager
    if (!compte) compte = await AuthModel.getByTelPassager(email);
    // 4. tel conducteur
    if (!compte) compte = await AuthModel.getByTelConducteur(email);
    // 5. tel proprietaire
    if (!compte) compte = await AuthModel.getByTelProprietaire(email);

    if (!compte)
      return res.status(401).json({
        code:    'IDENTIFIANT_INCORRECT',
        message: 'Email ou numéro de téléphone incorrect',
      });

    const valid = await bcrypt.compare(mot_de_passe, compte.mot_de_passe);
    if (!valid)
      return res.status(401).json({
        code:    'PASSWORD_INCORRECT',
        message: 'Mot de passe incorrect',
      });

    if (!compte.actif)
      return res.status(403).json({
        code:    'COMPTE_INACTIF',
        message: 'Compte non activé',
      });

    let userInfo = { nom: null, prenom: null, age: null, tel: null };

    if (compte.role === 'visiteur')
      userInfo = (await AuthModel.getUserInfoVisiteur(compte.id))    ?? userInfo;
    else if (compte.role === 'passager')
      userInfo = (await AuthModel.getUserInfoPassager(compte.id))    ?? userInfo;
    else if (compte.role === 'proprietaire')
      userInfo = (await AuthModel.getUserInfoProprietaire(compte.id)) ?? userInfo;
    else if (compte.role === 'conducteur')
      userInfo = (await AuthModel.getUserInfoConducteur(compte.id))  ?? userInfo;

    const token = jwt.sign(
      { id: compte.id, email: compte.email, role: compte.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.status(200).json({
      message:          'Connexion réussie',
      token,
      premier_connexion: compte.premier_connexion ?? false,
      user: {
        id:     compte.id,
        email:  compte.email,
        role:   compte.role,
        nom:    userInfo.nom,
        prenom: userInfo.prenom,
        age:    userInfo.age,
        tel:    userInfo.tel,
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ code: 'SERVER_ERROR', message: 'Erreur serveur' });
  }
};

const changerMotDePasse = async (req, res) => {
  const { nouveau_mot_de_passe } = req.body;
  try {
    if (!nouveau_mot_de_passe || nouveau_mot_de_passe.trim().length < 6)
      return res.status(400).json({ message: 'Mot de passe trop court (min 6 caractères)' });

    const compte = await AuthModel.getById(req.user.id);
    if (!compte)
      return res.status(404).json({ message: 'Compte introuvable' });

    const memeMDP = await bcrypt.compare(nouveau_mot_de_passe, compte.mot_de_passe);
    if (memeMDP)
      return res.status(400).json({ 
        message: 'Le nouveau mot de passe doit être différent de l\'ancien' 
      });

    const hash = await bcrypt.hash(nouveau_mot_de_passe, 10);
    await AuthModel.changerMotDePasse(req.user.id, hash);

    res.json({ message: 'Mot de passe changé avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
 
};
 // POST /api/auth/forgot-password
const demanderResetMotDePasse = async (req, res) => {
  const { email } = req.body;
  try {
    if (!email || !email.includes('@'))
      return res.status(400).json({ message: 'Email invalide' });

    const compte = await AuthModel.getByEmail(email);

    // Réponse générique même si le compte n'existe pas (sécurité)
    if (!compte) {
      return res.status(200).json({
        message: 'Si ce compte existe, un code a été envoyé par e-mail',
      });
    }

    const code = String(Math.floor(100000 + Math.random() * 900000)); // 6 chiffres
    const expires = new Date(Date.now() + 15 * 60 * 1000); // +15 min

    await AuthModel.setResetCode(compte.id, code, expires);
    await envoyerCodeReset(compte.email, code);

    res.status(200).json({
      message: 'Si ce compte existe, un code a été envoyé par e-mail',
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// POST /api/auth/reset-password
const resetMotDePasseAvecCode = async (req, res) => {
  const { email, code, nouveau_mot_de_passe } = req.body;
  try {
    if (!email || !code || !nouveau_mot_de_passe)
      return res.status(400).json({ message: 'Champs manquants' });

    if (nouveau_mot_de_passe.trim().length < 6)
      return res.status(400).json({ message: 'Mot de passe trop court (min 6 caractères)' });

    const compte = await AuthModel.getByEmail(email);
    if (!compte)
      return res.status(400).json({ message: 'Code invalide ou expiré' });

    if (
      !compte.reset_code ||
      compte.reset_code !== code ||
      !compte.reset_expires ||
      new Date(compte.reset_expires) < new Date()
    ) {
      return res.status(400).json({ message: 'Code invalide ou expiré' });
    }

    const hash = await bcrypt.hash(nouveau_mot_de_passe, 10);
    await AuthModel.changerMotDePasse(compte.id, hash);
    await AuthModel.clearResetCode(compte.id);

    res.status(200).json({ message: 'Mot de passe réinitialisé avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = {
  sAuthentifier,
  changerMotDePasse,
  demanderResetMotDePasse,
  resetMotDePasseAvecCode,
};