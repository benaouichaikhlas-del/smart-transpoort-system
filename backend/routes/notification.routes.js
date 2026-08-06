// routes/notification.routes.js

const express = require('express');
const router = express.Router();

const { verifierToken } =
  require('../middleware/auth.middleware');

const {
  getNotifications,
  marquerLu,
  marquerTousLus,
} = require('../controllers/notification.controller');

router.use(verifierToken);

// GET notifications
router.get('/', getNotifications);

// MARK AS READ
router.put('/:id/lu', marquerLu);

// MARK ALL AS READ
router.put('/toutes/lues', marquerTousLus);

module.exports = router;