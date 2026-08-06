const NotificationModel = require('../models/notification.model');

// جلب الإشعارات
const getNotifications = async (req, res) => {
  try {
    const notifications = await NotificationModel.getByPassager(req.user.id);
    const nonLues       = await NotificationModel.countNonLues(req.user.id);
    res.json({ notifications, nonLues });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// تحديد إشعار واحد كمقروء
const marquerLu = async (req, res) => {
  try {
    await NotificationModel.marquerLu(req.params.id, req.user.id);
    res.json({ message: 'Notification lue' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// تحديد جميع الإشعارات كمقروءة
const marquerTousLus = async (req, res) => {
  try {
    await NotificationModel.marquerTousLus(req.user.id);
    res.json({ message: 'Toutes les notifications lues' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = { getNotifications, marquerLu, marquerTousLus };