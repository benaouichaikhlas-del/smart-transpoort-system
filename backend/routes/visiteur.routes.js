const express = require('express');
const router = express.Router();

const { sInscrire } = require('../controllers/visiteur.controller');

// POST inscription
router.post('/inscrire', sInscrire);

module.exports = router;