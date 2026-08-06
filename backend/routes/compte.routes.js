const express = require('express');
const router = express.Router();

const { verifierToken } = require('../middleware/auth.middleware');
const {
  modifierCompte,
  supprimerCompte
} = require('../controllers/compte.controller');

router.use(verifierToken);

router.put('/', modifierCompte);
router.delete('/', supprimerCompte);

module.exports = router;