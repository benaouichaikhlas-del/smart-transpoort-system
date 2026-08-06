const express = require('express');
const router = express.Router();

const {
  getDemandes,
  accepterDemande,
  refuserDemande,
  changerStatutDemande,
  supprimerDemande,
  getFeedbacks,
  getSignalements,
  getEvaluationsAdmin,
  updateStatutSignalement,
} = require('../controllers/admin.controller');

const { verifierToken } = require('../middleware/auth.middleware');

router.use(verifierToken);

router.get('/demandes', getDemandes);
router.put('/demandes/:id/accepter', accepterDemande);
router.put('/demandes/:id/refuser', refuserDemande);
router.put('/demandes/:id/statut', changerStatutDemande);

// 👇 هذا هو الصحيح فقط
router.delete('/demandes/:id', supprimerDemande);

router.get('/feedbacks', getFeedbacks);
router.get('/signalements', getSignalements);
router.get('/evaluations', getEvaluationsAdmin);
router.put('/signalements/:id/statut', updateStatutSignalement);

module.exports = router;