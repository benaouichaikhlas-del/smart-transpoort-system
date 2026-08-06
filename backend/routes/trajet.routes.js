const express = require('express');
const router = express.Router();
const { verifierToken } = require('../middleware/auth.middleware');

const {
  // 🔴 NEW — Conducteur
  demarrer,
  updatePosition,
  terminer,
  getTrajetsActifs,
  
  // 🔵 EXISTING — Proprietaire/Admin
  getTrajets,
  getTrajetsByLigne,
  createTrajet,
  deleteTrajet,
} = require('../controllers/trajet.controller');

// ══════ PUBLIC (بدون token) ══════
router.get('/actifs', getTrajetsActifs);

// ══════ PROTECTED (خاص token) ══════
router.use(verifierToken);

// ══════ CONDUCTEUR فقط ══════
const checkConducteur = (req, res, next) => {
  if (req.user?.role !== 'conducteur') {
    return res.status(403).json({ message: 'Accès refusé — conducteur seulement' });
  }
  next();
};

router.post('/demarrer', checkConducteur, demarrer);
router.post('/position', checkConducteur, updatePosition);
router.put('/:id/terminer', checkConducteur, terminer);  // 🔴 PUT /api/trajets/:id/terminer

// ══════ PROPRIETAIRE فقط ══════
const checkProprietaire = (req, res, next) => {
  if (req.user?.role !== 'proprietaire' && req.user?.role !== 'admin') {
    return res.status(403).json({ message: 'Accès refusé' });
  }
  next();
};

router.get('/', checkProprietaire, getTrajets);
router.get('/ligne/:ligneId', checkProprietaire, getTrajetsByLigne);
router.post('/', checkProprietaire, createTrajet);
router.delete('/:id', checkProprietaire, deleteTrajet);

module.exports = router;