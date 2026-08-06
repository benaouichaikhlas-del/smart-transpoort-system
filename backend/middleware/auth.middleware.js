const jwt = require('jsonwebtoken');

const verifierToken = (req, res, next) => {
  const header = req.headers['authorization'];

  if (!header) {
    return res.status(401).json({ message: 'Token manquant' });
  }

  const token = header.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(403).json({ message: 'Token invalide' });
  }
};
const verifierTokenOptional = (req, res, next) => {
  const header = req.headers['authorization'];
  if (!header) return next(); // مش إجباري
  const token = header.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
  } catch {}
  next();
};


const verifierAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Accès refusé (admin فقط)' });
  }
  next();
};

module.exports = { verifierToken, verifierAdmin, verifierTokenOptional };
