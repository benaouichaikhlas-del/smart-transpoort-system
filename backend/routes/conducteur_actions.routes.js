const express        = require('express');
const router         = express.Router();
const { verifierToken } = require('../middleware/auth.middleware');
const ctrl           = require('../controllers/conducteur_actions.controller');

router.use(verifierToken);

// GPS
router.post('/position',  ctrl.envoyerPosition);
router.put ('/desactiver', ctrl.desactiverGPS);

// Retard
router.post('/retard', ctrl.declarerRetard);
router.post('/retard/:id/resoudre', ctrl.resoudreRetard);
router.get('/retard-en-cours', ctrl.getRetardEnCours);

// Panne
router.post('/panne', ctrl.declarerPanne);
router.post('/panne/:id/resoudre', ctrl.resoudrePanne);
router.get('/pannes-en-cours', ctrl.getPannesEnCours);

// Justification
router.get ('/justifications',  ctrl.getDeclarationsEnAttente);
router.post('/justification',   ctrl.envoyerJustification);

// Espaces vides
router.get ('/espaces', ctrl.getEspacesVides);
router.post('/espaces', ctrl.ajusterEspacesVides);

// Permanences
router.get('/permanences', ctrl.getPermanences);

// Réservations ligne
router.get('/reservations-ligne', ctrl.getReservationsLigne);


module.exports = router;