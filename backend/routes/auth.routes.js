const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const pool = require('../db/pool');
const rateLimit = require('express-rate-limit');

const { verifierToken } = require('../middleware/auth.middleware');
const {
  sAuthentifier,
  demanderResetMotDePasse,
  resetMotDePasseAvecCode,
} = require('../controllers/auth.controller');

// ====== IMPORT MAILER ======
const { envoyerCodeReset, envoyerCodeVerification } = require('../config/mailer');

// ═══════════════════════════════════════════════════════════════════════
// 🛡️ RATE LIMITER — تحديد محاولات تسجيل الدخول
// ═══════════════════════════════════════════════════════════════════════
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 دقيقة
  max: 5,                   // 5 محاولات كحد أقصى
  message: { message: 'Trop de tentatives, réessayez dans 15 minutes' },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res, next, options) => {
    console.warn('🛑 RATE LIMIT déclenché pour IP:', req.ip); // ⭐ تصحيح مؤقت
    res.status(options.statusCode).json(options.message);
  },
});

// ═══════════════════════════════════════════════════════════════════════
// 📧 VÉRIFICATION EMAIL — Inscription
// ═══════════════════════════════════════════════════════════════════════

// POST /api/auth/envoyer-code
router.post('/envoyer-code', async (req, res) => {
  const { email } = req.body;

  if (!email || !email.includes('@')) {
    return res.status(400).json({ message: 'Email invalide' });
  }

  try {
    // Vérifier si email déjà utilisé et vérifié
    const exist = await pool.query(
      'SELECT id FROM compte WHERE email = $1 AND email_verifie = TRUE',
      [email]
    );
    if (exist.rows.length > 0) {
      return res.status(409).json({ message: 'Cet email est déjà utilisé' });
    }

    // Générer code 6 chiffres
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 min

    // Sauvegarder dans compte (insérer ou mettre à jour)
    await pool.query(
      `INSERT INTO compte (email, code_verification, code_expires_at, email_verifie, role, mot_de_passe, actif)
       VALUES ($1, $2, $3, FALSE, 'temp', '', FALSE)
       ON CONFLICT (email) DO UPDATE
       SET code_verification = EXCLUDED.code_verification,
           code_expires_at = EXCLUDED.code_expires_at`,
      [email, code, expiresAt]
    );

    // Envoyer l'email
    await envoyerCodeVerification(email, code);

    res.json({ message: 'Code envoyé avec succès' });
  } catch (err) {
    console.error('❌ Erreur envoyer-code:', err);
    res.status(500).json({ message: "Erreur lors de l'envoi du code" });
  }
});

// POST /api/auth/verifier-code
router.post('/verifier-code', async (req, res) => {
  const { email, code } = req.body;

  if (!email || !code) {
    return res.status(400).json({ message: 'Email et code requis' });
  }

  try {
    const result = await pool.query(
      'SELECT code_verification, code_expires_at FROM compte WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Email non trouvé' });
    }

    const user = result.rows[0];

    if (user.code_verification !== code) {
      return res.status(400).json({ message: 'Code incorrect' });
    }

    if (new Date() > new Date(user.code_expires_at)) {
      return res.status(400).json({ message: 'Code expiré, veuillez renvoyer' });
    }

    // Marquer comme vérifié
    await pool.query(
      'UPDATE compte SET email_verifie = TRUE WHERE email = $1',
      [email]
    );

    res.json({ message: 'Email vérifié avec succès', success: true });
  } catch (err) {
    console.error('❌ Erreur verifier-code:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// ═══════════════════════════════════════════════════════════════════════
// 🔐 ROUTES EXISTANTES
// ═══════════════════════════════════════════════════════════════════════

// POST /api/auth/login  (⭐ محمي بـ rate limiter)
router.post('/login', loginLimiter, sAuthentifier);

// POST /api/auth/forgot-password
router.post('/forgot-password', demanderResetMotDePasse);

// POST /api/auth/reset-password
router.post('/reset-password', resetMotDePasseAvecCode);

// PUT /api/auth/changer-mot-de-passe
router.put('/changer-mot-de-passe', verifierToken, async (req, res) => {
  const { nouveau_mot_de_passe } = req.body;

  try {
    if (!nouveau_mot_de_passe || nouveau_mot_de_passe.length < 6) {
      return res.status(400).json({
        message: 'Nouveau mot de passe requis (min 6 caractères)',
      });
    }

    const hash = await bcrypt.hash(nouveau_mot_de_passe, 10);

    await pool.query(
      `UPDATE compte 
       SET mot_de_passe = $1, premier_connexion = false 
       WHERE id = $2`,
      [hash, req.user.id]
    );

    res.status(200).json({
      message: 'Mot de passe changé avec succès',
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

module.exports = router;