const express = require('express');
const router  = express.Router();
const { verifierToken } = require('../middleware/auth.middleware');
const { getVehicules, ajouterVehicule, modifierVehicule, supprimerVehicule } =
  require('../controllers/vehicule.controller');

router.use(verifierToken);
router.get('/',       getVehicules);
router.post('/',      ajouterVehicule);
router.put('/:id',    modifierVehicule);
router.delete('/:id', supprimerVehicule);

module.exports = router;