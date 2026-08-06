const express = require('express');
const router = express.Router();

const {
  demanderInscription,
  getEvaluationsProp,
  getFeedbacksProp,
  getSignalementsProp,
} = require('../controllers/proprietaire.controller');

const { verifierToken } = require('../middleware/auth.middleware');

// ═══ PUBLIC ═══
router.post('/demande', demanderInscription);

// ═══ PROTECTED ═══
router.get('/evaluations',  verifierToken, getEvaluationsProp);
router.get('/feedbacks',    verifierToken, getFeedbacksProp);
router.get('/signalements', verifierToken, getSignalementsProp);
module.exports = router;