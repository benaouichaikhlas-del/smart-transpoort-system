const express = require('express');
const router  = express.Router();
const { verifierToken } = require('../middleware/auth.middleware');
const { getAffectations, ajouterAffectation, modifierAffectation, supprimerAffectation } =
  require('../controllers/affectation.controller');

router.use(verifierToken);
router.get('/',       getAffectations);
router.post('/',      ajouterAffectation);
router.put('/:id',    modifierAffectation);
router.delete('/:id', supprimerAffectation);

module.exports = router;