const bcrypt = require('bcryptjs');
const CompteModel = require('../models/compte.model');

// ═══ MODIFIER ═══
const modifierCompte = async (req, res) => {
  const { email, mot_de_passe } = req.body;
  
  // ⭐ شوف واش البيانات توصل
  console.log('📝 PUT /api/compte body:', req.body);
  console.log('🔍 req.user.id:', req.user?.id);

  try {
    if (email) {
      console.log('✏️ Updating email...');
      const updated = await CompteModel.updateEmail(req.user.id, email);
      console.log('✅ Email updated:', updated);
    }

    if (mot_de_passe) {
      console.log('🔐 Updating password...');
      const hash = await bcrypt.hash(mot_de_passe, 10);
      const updated = await CompteModel.updateMotDePasse(req.user.id, hash);
      console.log('✅ Password updated:', updated);
    }

    res.json({ message: 'Compte modifié avec succès' });
  } catch (err) {
    // ⭐ هادي غادي توريك شنو الصرا بالضبط
    console.error('❌ ERREUR modifierCompte:', err.message);
    console.error(err.stack);
    res.status(500).json({ message: err.message || 'Erreur serveur' });
  }
};

// ═══ SUPPRIMER ═══
const supprimerCompte = async (req, res) => {
  console.log('🗑️ DELETE /api/compte id:', req.user?.id);

  try {
    await CompteModel.delete(req.user.id);
    res.json({ message: 'Compte supprimé avec succès' });
  } catch (err) {
    console.error('❌ ERREUR supprimerCompte:', err.message);
    console.error(err.stack);
    res.status(500).json({ message: err.message || 'Erreur serveur' });
  }
};

module.exports = { modifierCompte, supprimerCompte };