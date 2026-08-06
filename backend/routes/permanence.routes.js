const express = require('express');
const router = express.Router();
const { verifierToken } = require('../middleware/auth.middleware');
const ctrl = require('../controllers/permanence.controller');

router.use(verifierToken);

const checkAdmin = (req, res, next) => {
  if (req.user?.role !== 'admin')
    return res.status(403).json({ message: 'Admin seulement' });
  next();
};

const checkConducteur = (req, res, next) => {
  if (req.user?.role !== 'conducteur')
    return res.status(403).json({ message: 'Conducteur seulement' });
  next();
};

// ⚠️ الـ routes الثابتة لازم تجي قبل الـ routes بـ params
// Conducteur
router.get('/mes-permanences',          checkConducteur, ctrl.getMesPermanences);

// Admin — ثابتة أولاً
router.get('/',                         checkAdmin, ctrl.getPermanencesAdmin);
router.post('/rotation',                checkAdmin, ctrl.genererRotation);
router.post('/',                        checkAdmin, ctrl.creerPermanence);
router.delete('/:id',                   checkAdmin, ctrl.supprimerPermanence);

// Admin — params في الآخر
router.get('/conducteurs/:ligneId',     checkAdmin, ctrl.getConducteursLigne);

module.exports = router;