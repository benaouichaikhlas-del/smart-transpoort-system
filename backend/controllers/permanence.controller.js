const PermanenceModel = require('../models/permanence.model');
const pool = require('../db/pool');

exports.getPermanencesAdmin = async (req, res) => {
  try {
    const rows = await PermanenceModel.getAll();
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const LigneModel = require('../models/ligne.model');

exports.creerPermanence = async (req, res) => {
  const { conducteur_id, date, heure_debut, heure_fin, ligne_id } = req.body;
  try {
    const d = new Date(date);
    if (d.getDay() !== 5)
      return res.status(400).json({ message: 'La permanence doit être un vendredi' });

    const ligne = await LigneModel.getById(ligne_id);
    if (!ligne) return res.status(404).json({ message: 'Ligne introuvable' });
    const limite = ligne.nb_bus || 1;

    const count = await PermanenceModel.countByDateAndLigne(date, ligne_id);
    if (count >= limite)
      return res.status(409).json({ message: `Déjà ${limite} conducteur(s) assigné(s) ce vendredi pour cette ligne` });

    const dejaAssignes = await PermanenceModel.getConducteursAssignes(date, ligne_id);
    if (dejaAssignes.includes(conducteur_id))
      return res.status(409).json({ message: 'Ce conducteur est déjà assigné ce vendredi sur cette ligne' });

    const perm = await PermanenceModel.create({ conducteur_id, date, heure_debut, heure_fin, ligne_id });
    res.status(201).json({ message: 'Permanence créée', permanence: perm });
  } catch (err) {
    console.error('❌ creerPermanence:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.genererRotation = async (req, res) => {
  const { ligne_id, nb_semaines, heure_debut, heure_fin } = req.body;
  try {
    const ligne = await LigneModel.getById(ligne_id);
    if (!ligne) return res.status(404).json({ message: 'Ligne introuvable' });
    const busParVendredi = ligne.nb_bus || 1;

    const cList = await PermanenceModel.getConducteursByLigne(ligne_id);
    if (cList.length === 0)
      return res.status(404).json({ message: 'Aucun conducteur affecté à cette ligne' });
    if (cList.length < busParVendredi)
      return res.status(400).json({
        message: `Cette ligne nécessite ${busParVendredi} bus/vendredi mais seulement ${cList.length} conducteur(s) affecté(s)`
      });

    const totalCount = await PermanenceModel.getTotalCountByLigne(ligne_id);
    let curseur = totalCount % cList.length;

    const today = new Date();
    let friday = new Date(today);
    const dayOfWeek = friday.getDay();
    const daysUntilFriday = dayOfWeek <= 5 ? 5 - dayOfWeek : 6;
    friday.setDate(friday.getDate() + (daysUntilFriday === 0 ? 7 : daysUntilFriday));

    const created = [];
    for (let semaine = 0; semaine < nb_semaines; semaine++) {
      const dateStr = friday.toISOString().split('T')[0];
      const dejaCount = await PermanenceModel.countByDateAndLigne(dateStr, ligne_id);
      const busRestants = busParVendredi - dejaCount;

      for (let b = 0; b < busRestants; b++) {
        const conducteur = cList[curseur % cList.length];
        curseur++;
        const perm = await PermanenceModel.create({
          conducteur_id: conducteur.id,
          date: dateStr,
          heure_debut,
          heure_fin,
          ligne_id,
        });
        created.push({ id: perm.id, date: dateStr, conducteur: `${conducteur.prenom} ${conducteur.nom}` });
      }
      friday.setDate(friday.getDate() + 7);
    }

    res.status(201).json({ message: `${created.length} permanence(s) créée(s)`, permanences: created });
  } catch (err) {
    console.error('❌ genererRotation:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
exports.getConducteursLigne = async (req, res) => {
  try {
    const conducteurs = await PermanenceModel.getConducteursByLigne(
      req.params.ligneId
    );
    res.json(conducteurs);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
exports.supprimerPermanence = async (req, res) => {
  try {
    await PermanenceModel.delete(req.params.id);
    res.json({ message: 'Permanence supprimée' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.genererRotation = async (req, res) => {
  const { ligne_id, nb_semaines, heure_debut, heure_fin } = req.body;
  try {
    const cList = await PermanenceModel.getConducteursByLigne(ligne_id);
    if (cList.length === 0)
      return res.status(404).json({ message: 'Aucun conducteur affecté à cette ligne' });

    const lastPerm = await PermanenceModel.getLastByLigne(ligne_id);
    let startIdx = 0;
    if (lastPerm) {
      const lastIdx = cList.findIndex(c => c.id === lastPerm.conducteur_id);
      startIdx = (lastIdx + 1) % cList.length;
    }

    const today = new Date();
    let friday = new Date(today);
    const dayOfWeek = friday.getDay();
    const daysUntilFriday = dayOfWeek <= 5 ? 5 - dayOfWeek : 6;
    friday.setDate(friday.getDate() + (daysUntilFriday === 0 ? 7 : daysUntilFriday));

    const created = [];
    for (let i = 0; i < nb_semaines; i++) {
      const conducteur = cList[(startIdx + i) % cList.length];
      const dateStr = friday.toISOString().split('T')[0];

      const exist = await PermanenceModel.existsByDateAndLigne(dateStr, ligne_id);
      if (!exist) {
        const perm = await PermanenceModel.create({
          conducteur_id: conducteur.id,
          date: dateStr,
          heure_debut,
          heure_fin,
          ligne_id,
        });
        created.push({
          id: perm.id,
          date: dateStr,
          conducteur: `${conducteur.prenom} ${conducteur.nom}`,
        });
      }

      friday.setDate(friday.getDate() + 7);
    }

    res.status(201).json({
      message: `${created.length} permanence(s) créée(s)`,
      permanences: created,
    });
  } catch (err) {
    console.error('❌ genererRotation:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.getMesPermanences = async (req, res) => {
  try {
    const r = await pool.query(
      'SELECT id FROM conducteur WHERE compte_id = $1', [req.user.id]
    );
    if (!r.rows[0])
      return res.status(404).json({ message: 'Conducteur introuvable' });

    const rows = await PermanenceModel.getByConducteur(r.rows[0].id);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};