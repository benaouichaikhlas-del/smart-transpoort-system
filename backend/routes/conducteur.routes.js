const express        = require('express');
const router         = express.Router();
const { verifierToken } = require('../middleware/auth.middleware');
const ctrl           = require('../controllers/conducteur.controller');

router.use(verifierToken);

// routes ثابتة — لازم تجي قبل /:id
router.get   ('/mon-profil', ctrl.getMonProfil);
router.put   ('/mon-compte', ctrl.modifierMonCompte);
router.delete('/mon-compte', ctrl.supprimerMonCompte);
router.post  ('/changer-mot-de-passe', ctrl.changerMotDePasse); // ← زيد هادي

// بروبريتار
router.get   ('/',    ctrl.getConducteurs);
router.post  ('/',    ctrl.ajouterConducteur);
router.put   ('/:id', ctrl.modifierConducteur);
router.delete('/:id', ctrl.supprimerConducteur);

module.exports = router;