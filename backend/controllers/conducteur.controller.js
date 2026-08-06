const bcrypt          = require('bcryptjs');
const ConducteurModel = require('../models/conducteur.model');
const pool            = require('../db/pool');

// helper inline باش نتجنب cache Node.js
const getPropId = async (compteId) => {
  const r = await pool.query(
    'SELECT id FROM proprietaire WHERE compte_id = $1', [compteId]
  );
  return r.rows[0]?.id;
};

// ── GET كل الكوندويكتاريه ──
const getConducteurs = async (req, res) => {
  try {
    const propId = await getPropId(req.user.id);
    if (!propId)
      return res.status(404).json({ message: 'Propriétaire introuvable' });

    const rows = await ConducteurModel.getByProprietaire(propId);
    res.status(200).json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ── إضافة كوندويكتار ──
const ajouterConducteur = async (req, res) => {
  const { nom, prenom, age, telephone, num_permis, adresse, email, mot_de_passe } = req.body;
  try {
    if (!nom || !prenom || !age || !telephone || !num_permis || !mot_de_passe)
      return res.status(400).json({ message: 'Vérifiez les champs obligatoires' });

    const ageNum = parseInt(age);
    if (isNaN(ageNum) || ageNum < 18 || ageNum > 70)
      return res.status(400).json({ message: 'Âge invalide (18-70)' });

    const propId = await getPropId(req.user.id);
    if (!propId)
      return res.status(404).json({ message: 'Propriétaire introuvable' });

    const emailValue = (email && email.trim() !== '') ? email.trim() : null;

    if (emailValue && await ConducteurModel.emailExiste(emailValue))
      return res.status(409).json({ message: 'Cet email est déjà utilisé' });

    if (await ConducteurModel.telephoneExiste(telephone))
      return res.status(409).json({ message: 'Ce numéro est déjà utilisé' });

    if (await ConducteurModel.permisExiste(num_permis))
      return res.status(409).json({ message: 'Ce permis est déjà utilisé' });

    const hash     = await bcrypt.hash(mot_de_passe, 10);
    const compteId = await ConducteurModel.creerCompte(emailValue, hash);

    await ConducteurModel.create({
      nom, prenom,
      age:             ageNum,
      telephone,
      num_permis,
      adresse:         adresse || '',
      proprietaire_id: propId,
      compte_id:       compteId,
    });

    res.status(201).json({ message: 'Conducteur ajouté avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur: ' + err.message });
  }
};

// ── تعديل كوندويكتار ──
const modifierConducteur = async (req, res) => {
  const { id } = req.params;
  const { nom, prenom, age, telephone, num_permis, adresse, email } = req.body;
  try {
    const propId     = await getPropId(req.user.id);
    const conducteur = await ConducteurModel.getByIdAndProp(id, propId);
    if (!conducteur)
      return res.status(404).json({ message: 'Conducteur introuvable' });

    if (age !== undefined) {
      const ageNum = parseInt(age);
      if (isNaN(ageNum) || ageNum < 18 || ageNum > 70)
        return res.status(400).json({ message: 'Âge invalide (18-70)' });
    }

    if (await ConducteurModel.permisExiste(num_permis, id))
      return res.status(409).json({ message: 'Numéro de permis déjà utilisé' });

    if (await ConducteurModel.telephoneExiste(telephone, id))
      return res.status(409).json({ message: 'Numéro de téléphone déjà utilisé' });

    const updated = await ConducteurModel.update({
      id, nom, prenom, age, telephone, num_permis, adresse
    });

    if (email !== undefined)
      await ConducteurModel.updateEmail(conducteur.compte_id, email);

    res.status(200).json({
      message:    'Conducteur modifié avec succès',
      conducteur: updated,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ── حذف كوندويكتار ──
const supprimerConducteur = async (req, res) => {
  const { id } = req.params;
  try {
    const propId     = await getPropId(req.user.id);
    const conducteur = await ConducteurModel.getByIdAndProp(id, propId);
    if (!conducteur)
      return res.status(404).json({ message: 'Conducteur introuvable' });

    await ConducteurModel.deleteById(id);
    if (conducteur.compte_id)
      await ConducteurModel.deleteByCompteId(conducteur.compte_id);

    res.status(200).json({ message: 'Conducteur supprimé avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ── الكوندويكتار يجيب بروفيله ──
const getMonProfil = async (req, res) => {
  try {
    const conducteur = await ConducteurModel.getByCompteId(req.user.id);
    if (!conducteur)
      return res.status(404).json({ message: 'Conducteur introuvable' });
    res.json(conducteur);
  } catch (err) {
    console.error('❌ getMonProfil:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ── الكوندويكتار يعدل حسابه ──
const modifierMonCompte = async (req, res) => {
  const { nom, prenom, age, telephone, adresse } = req.body;
  try {
    const conducteur = await ConducteurModel.getByCompteId(req.user.id);
    if (!conducteur)
      return res.status(404).json({ message: 'Conducteur introuvable' });

    if (age !== undefined && age !== null) {
      const ageNum = parseInt(age);
      if (isNaN(ageNum) || ageNum < 18 || ageNum > 70)
        return res.status(400).json({ message: 'Âge invalide (18-70)' });
    }

    if (telephone && await ConducteurModel.telephoneExiste(telephone, conducteur.id))
      return res.status(409).json({ message: 'Numéro de téléphone déjà utilisé' });

    await ConducteurModel.updateMonCompte({
      compteId: req.user.id, nom, prenom, age, telephone, adresse
    });

    res.json({ message: 'Compte modifié avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ── الكوندويكتار يحذف حسابه ──
const supprimerMonCompte = async (req, res) => {
  try {
    const conducteur = await ConducteurModel.getByCompteId(req.user.id);
    if (!conducteur)
      return res.status(404).json({ message: 'Conducteur introuvable' });

    await ConducteurModel.deleteByCompteId(req.user.id);
    const CompteModel = require('../models/compte.model');
    await CompteModel.delete(req.user.id);

    res.json({ message: 'Compte supprimé avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ── الكوندويكتار يبدل كلمتو السرية ──
const changerMotDePasse = async (req, res) => {
  try {
    const { ancien_mot_de_passe, nouveau_mot_de_passe } = req.body;
    const compteId = req.user.id;

    if (!ancien_mot_de_passe || !nouveau_mot_de_passe)
      return res.status(400).json({ message: 'Les champs sont obligatoires' });

    if (nouveau_mot_de_passe.length < 6)
      return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 6 caractères' });

    const r = await pool.query('SELECT mot_de_passe FROM compte WHERE id = $1', [compteId]);
    if (r.rows.length === 0)
      return res.status(404).json({ message: 'Compte introuvable' });

    const match = await bcrypt.compare(ancien_mot_de_passe, r.rows[0].mot_de_passe);
    if (!match)
      return res.status(401).json({ message: 'Ancien mot de passe incorrect' });

    const nouveauHash = await bcrypt.hash(nouveau_mot_de_passe, 10);
    await pool.query('UPDATE compte SET mot_de_passe = $1 WHERE id = $2', [nouveauHash, compteId]);

    res.json({ message: 'Mot de passe modifié avec succès' });
  } catch (err) {
    console.error('❌ changerMotDePasse:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = {
  getConducteurs,
  ajouterConducteur,
  modifierConducteur,
  supprimerConducteur,
  getMonProfil,
  modifierMonCompte,
  supprimerMonCompte,
  changerMotDePasse,
};