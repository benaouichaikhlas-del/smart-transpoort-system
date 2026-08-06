const express = require('express');
const router  = express.Router();

const { verifierToken } = require('../middleware/auth.middleware');

const {
  getAnnonces,
  envoyerAnnonce,
  supprimerAnnonce
} = require('../controllers/annonce.controller');

// ✅ PUBLIC
router.get('/', getAnnonces);

// ✅ TOKEN REQUIRED
router.use(verifierToken);

router.post('/', envoyerAnnonce);
router.delete('/:id', supprimerAnnonce);

module.exports = router;