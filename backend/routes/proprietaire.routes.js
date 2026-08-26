const express = require('express');
const router = express.Router();

const {
  demanderInscription,
  getMonId,
  getEvaluationsProp,
  getFeedbacksProp,
  getSignalementsProp,
  getDashboardStats,  // ⭐ جديد
} = require('../controllers/proprietaire.controller');

const { verifierToken } = require('../middleware/auth.middleware');

// ═══ PUBLIC ═══
router.post('/demande', demanderInscription);

// ═══ PROTECTED ═══
router.get('/mon-id',         verifierToken, getMonId);
router.get('/evaluations',    verifierToken, getEvaluationsProp);
router.get('/feedbacks',      verifierToken, getFeedbacksProp);
router.get('/signalements',   verifierToken, getSignalementsProp);
router.get('/dashboard-stats', verifierToken, getDashboardStats); // ⭐ جديد

module.exports = router;