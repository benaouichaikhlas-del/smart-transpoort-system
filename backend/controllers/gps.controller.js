const GpsModel    = require('../models/gps.model');
const TrajetModel = require('../models/trajet.model');

// ═══ إرسال الموضع + بث Socket.IO محسّن ═══
const envoyerPosition = async (req, res) => {
  console.log('📍 envoyerPosition appelé:', req.body);
  const { latitude, longitude, vitesse, ligne_id, trajet_id } = req.body;
  
  try {
    if (!latitude || !longitude)
      return res.status(400).json({ message: 'Coordonnées manquantes' });

    const conducteurId = await GpsModel.getConducteurId(req.user.id);
    if (!conducteurId)
      return res.status(404).json({ message: 'Conducteur introuvable' });

    // 1. حفظ في position_bus
    await GpsModel.upsertPosition({
      conducteurId, ligne_id, latitude, longitude, vitesse
    });

    // 2. جلب المعلومات الكاملة للبث
    const info = await GpsModel.getConducteurFullInfo(conducteurId);

    // 3. broadcast Socket.io مع كل البيانات المطلوبة
    req.io.emit('position_broadcast', {
      trajet_id:      trajet_id || conducteurId.toString(),
      latitude,
      longitude,
      vitesse:        vitesse || 0,
      ligne_id:       ligne_id || null,
      conducteur_id:  conducteurId,
      proprietaire_id: info?.proprietaire_id || null,
      ligne_numero:   info?.ligne_numero || '',
      ligne_nom:      info?.ligne_nom || '',
      conducteur_nom: info?.conducteur_nom || '',
      conducteur_prenom: info?.conducteur_prenom || '',
      immatriculation: info?.immatriculation || '',
      timestamp:      new Date().toISOString(),
    });

    res.status(200).json({ message: 'Position enregistrée' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══ إيقاف GPS ═══
const desactiverGPS = async (req, res) => {
  try {
    const conducteurId = await GpsModel.getConducteurId(req.user.id);
    if (!conducteurId)
      return res.status(404).json({ message: 'Conducteur introuvable' });

    await GpsModel.desactiverGPS(conducteurId);

    // broadcast إيقاف — نبعث trajet_id باش السويفي بيس يفهمو
    req.io.emit('trajet_termine', {
      trajet_id: conducteurId.toString(),
      conducteur_id: conducteurId,
    });

    res.json({ message: 'GPS désactivé' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ═══ جديد: الراوت اللي يطلبها السويفي بيس ═══
const getTrajetsActifs = async (req, res) => {
  try {
    const { proprietaire_id, ligne_id } = req.query;

    let rows;
    if (proprietaire_id) {
      // البروبريتار — نرجع باصاتو فقط
      rows = await GpsModel.getPositionsByProprietaireCompte(proprietaire_id);
    } else if (ligne_id) {
      // فلتر بالليغن
      rows = await GpsModel.getPositionByLigne(ligne_id);
      rows = rows.map(r => ({
        ...r,
        trajet_id: r.conducteur_id,
        derniere_maj: r.updated_at,
      }));
    } else {
      // الكل
      rows = await GpsModel.getToutesPositions();
      rows = rows.map(r => ({
        ...r,
        trajet_id: r.conducteur_id,
        derniere_maj: r.updated_at,
      }));
    }

    res.json(rows);
  } catch (err) {
    console.error('❌ getTrajetsActifs:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const getPositionLigne = async (req, res) => {
  try {
    const rows = await GpsModel.getPositionByLigne(req.params.ligne_id);
    res.json({ buses: rows, count: rows.length, active: rows.length > 0 });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const getToutesPositions = async (req, res) => {
  try {
    const rows = await GpsModel.getToutesPositions();
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = {
  envoyerPosition,
  desactiverGPS,
  getTrajetsActifs,    // ← جديد
  getPositionLigne,
  getToutesPositions,
};