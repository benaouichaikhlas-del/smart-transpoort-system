const express = require('express');
const router = express.Router();

console.log('✅ ligne.routes.js STARTED');

const { verifierToken, verifierTokenOptional } = require('../middleware/auth.middleware');
const ligneController = require('../controllers/ligne.controller');

const checkAdmin = (req, res, next) => {
  if (req.user?.role !== 'admin')
    return res.status(403).json({ message: 'Admin seulement' });
  next();
};

// Debug
router.use((req, res, next) => {
  console.log('📍 LIGNE ROUTER:', req.method, req.originalUrl);
  next();
});

// ══════ PUBLIC (مسموح للجميع بدون توكن إجباري) ══════
router.get('/vehicules/liste', verifierTokenOptional, ligneController.getVehicules);
router.get('/', verifierTokenOptional, ligneController.getLignes);
router.get('/:id/arrets', verifierTokenOptional, ligneController.getArrets);
router.get('/:id/horaires', verifierTokenOptional, ligneController.getHoraires);

// ══════ PROTECTED (يتطلب تسجيل الدخول) ══════
router.use(verifierToken);

router.put('/:id/nb-bus', checkAdmin, ligneController.modifierNbBus);
router.put('/:id/vehicule', ligneController.associerVehicule);
router.put('/:id/arrets/:arretId', ligneController.modifierArret);
router.put('/:id/horaires/:horaireId', ligneController.modifierHoraire);
router.put('/:id', ligneController.modifierLigne);
router.delete('/:id/arrets/:arretId', ligneController.supprimerArret);
router.delete('/:id/horaires/:horaireId', ligneController.supprimerHoraire);
router.delete('/:id', ligneController.supprimerLigne);
router.post('/', ligneController.ajouterLigne);
router.post('/:id/arrets', ligneController.ajouterArret);
router.post('/:id/horaires', ligneController.ajouterHoraire);

console.log('✅ ligne.routes.js EXPORTED');

module.exports = router;