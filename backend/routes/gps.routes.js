const express = require('express');
const router  = express.Router();
const { verifierToken } = require('../middleware/auth.middleware');
const {
  envoyerPosition,
  desactiverGPS,
  getTrajetsActifs,      // ← لازم تكون مستوردة
  getPositionLigne,
  getToutesPositions,
} = require('../controllers/gps.controller');

// Public
router.get('/positions',          getToutesPositions);
router.get('/position/:ligne_id', getPositionLigne);

// ← هاذي لازم تكون هكذا (verifierToken مش auth)
router.get('/trajets/actifs', verifierToken, getTrajetsActifs);

// Protégé conducteur
router.post('/position',  verifierToken, envoyerPosition);
router.put ('/desactiver',verifierToken, desactiverGPS);

module.exports = router;