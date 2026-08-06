const express = require('express');
const router  = express.Router();
const { verifierToken } = require('../middleware/auth.middleware');

const {
  getTrajets,
  getRetardsPannes,
  getMoyennes,
  rechercherLignes,
  getHorairesLigne,
  reserver,
  reserverAvecDate,
  getMesReservations,
  modifierReservation,
  annulerReservation,
  evaluerLigne,
  getEvaluations,
  getMesEvaluations,
  signalerProbleme,
  envoyerFeedback,
  modifierComptePassager,  
} = require('../controllers/passager.controller');

const {
  getNotifications,
  marquerLu,
  marquerTousLus,
} = require('../controllers/notification.controller');

// ⬇️ AJOUT : Chatbot controller
const { chatbot } = require('../controllers/chatbot.controller');

// ══════ PUBLIC ══════
router.get('/trajets',          getTrajets);
router.get('/retards-pannes',   getRetardsPannes);
router.get('/moyennes',         getMoyennes);
router.get('/lignes-recherche', rechercherLignes);
router.get('/ligne/:id/horaires', getHorairesLigne);

// ══════ PROTECTED ══════
router.use(verifierToken);

router.get ('/evaluations',              getEvaluations);
router.post('/feedback',                 envoyerFeedback);
router.post('/reserver',                 reserver);
router.post('/reserver-avec-date',       reserverAvecDate);
router.get ('/mes-reservations',         getMesReservations);
router.put ('/reservation/:id/modifier', modifierReservation);
router.put ('/reservation/:id/annuler',  annulerReservation);
router.post('/evaluer',                  evaluerLigne);
router.post('/signaler-probleme',        signalerProbleme);
router.get ('/mes-evaluations',          getMesEvaluations);
router.get ('/notifications',            getNotifications);
router.put ('/notifications/all/lu',     marquerTousLus);
router.put ('/notifications/:id',        marquerLu);
router.put('/modifier-compte', modifierComptePassager);

// ✅ AJOUT : Chatbot
router.post('/chatbot', chatbot);

module.exports = router;