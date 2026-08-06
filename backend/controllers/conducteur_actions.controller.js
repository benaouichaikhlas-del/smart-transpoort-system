const pool = require('../db/pool');
const ConducteurActionsModel = require('../models/conducteur_actions.model');
const NotificationModel = require('../models/notification.model');

// ═══════════════════════════════════════════════════════
// 🔧 دوال مساعدة
// ═══════════════════════════════════════════════════════
const getConducteurId = async (compteId) => {
  const r = await pool.query(
    'SELECT id FROM conducteur WHERE compte_id = $1',
    [compteId]
  );
  return r.rows[0]?.id || null;
};

const getAffectationActive = async (conducteurId) => {
  const r = await pool.query(
    `SELECT ligne_id, vehicule_id, created_at 
     FROM affectation 
     WHERE conducteur_id = $1 AND actif = true
     ORDER BY created_at DESC LIMIT 1`,
    [conducteurId]
  );
  return r.rows[0] || null;
};

const getVehiculeEtProprietaire = async (vehiculeId) => {
  const r = await pool.query(
    `SELECT v.*, p.id as proprietaire_id, p.email as proprietaire_email
     FROM vehicule v
     JOIN proprietaire p ON v.proprietaire_id = p.id
     WHERE v.id = $1`,
    [vehiculeId]
  );
  return r.rows[0] || null;
};

const getConducteurInfo = async (conducteurId) => {
  const r = await pool.query(
    `SELECT nom, prenom, telephone FROM conducteur WHERE id = $1`,
    [conducteurId]
  );
  return r.rows[0] || null;
};

// ═══════════════════════════════════════════════════════
// 🔔 إشعار الركاب — إشعارات مؤقتة
// ═══════════════════════════════════════════════════════
async function _notifierPassagersLigne(req, ligneId, titre, message, type, extraIds = {}, dureeMinutes = 360, dateTrajet = null) {
  console.log('🔍 [_notifierPassagersLigne] ligneId:', ligneId, 'dateTrajet:', dateTrajet);

  if (!ligneId) {
    console.warn('⚠️ ligneId manquant');
    return 0;
  }

  let query = `
    SELECT DISTINCT res.passager_id
    FROM reservation res
    JOIN trajet t ON t.id = res.trajet_id
    WHERE t.ligne_id = $1
      AND res.statut = 'active'
      AND t.date = CURRENT_DATE`;
  const params = [ligneId];

  if (dateTrajet) {
    query = `
      SELECT DISTINCT res.passager_id
      FROM reservation res
      JOIN trajet t ON t.id = res.trajet_id
      WHERE t.ligne_id = $1
        AND res.statut = 'active'
        AND t.date = $2`;
    params.push(dateTrajet);
  }

  const r = await pool.query(query, params);

  console.log(`🔍 [_notifierPassagersLigne] ${r.rows.length} passager(s) trouvé(s)`);

  if (r.rows.length === 0) {
    console.warn('⚠️ Aucun passager trouvé pour ligneId:', ligneId);
    return 0;
  }

  const expiresAt = new Date(Date.now() + dureeMinutes * 60 * 1000);

  await Promise.all(
    r.rows.map(async ({ passager_id }) => {
      await NotificationModel.createWithRef(
        passager_id,
        titre,
        message,
        type,
        expiresAt,
        extraIds.panneId ?? null,
        extraIds.retardId ?? null
      );

      if (req.io) {
        req.io.to(`passager_${passager_id}`).emit('notification', {
          titre,
          message,
          type,
          created_at: new Date().toISOString(),
          ...extraIds
        });
      }
    })
  );

  console.log(`📢 Notification envoyée à ${r.rows.length} passager(s)`);
  return r.rows.length;
}
// ═══════════════════════════════════════════════════════
// 📢 إشعار عام: لجميع الپاساجي
// ═══════════════════════════════════════════════════════
async function _notifierTousPassagers(titre, message, type, dureeMinutes = 360, panneId = null) {
  const r = await pool.query(
    `SELECT DISTINCT co.id
     FROM compte co
     JOIN reservation res ON res.passager_id = co.id
     WHERE co.role = 'visiteur' AND res.statut = 'active'`
  );

  const expiresAt = new Date(Date.now() + dureeMinutes * 60 * 1000);

  await Promise.all(
    r.rows.map(({ id }) =>
      NotificationModel.createWithRef(
        id,
        titre,
        message,
        type,
        expiresAt,
        panneId,
        null
      )
    )
  );

  console.log(`📢 Notification GÉNÉRALE envoyée à ${r.rows.length} passager(s)`);
}

// ═══════════════════════════════════════════════════════
// 📝 إرسال تبرير (justification) لتأخير أو عطل
// ═══════════════════════════════════════════════════════
exports.envoyerJustification = async (req, res) => {
  try {
    const { type, declaration_id, justification } = req.body;
    const conducteurId = await getConducteurId(req.user.id);

    if (!conducteurId)
      return res.status(404).json({ message: 'السائق غير موجود' });

    if (!type || !declaration_id || !justification)
      return res.status(400).json({ message: 'البيانات ناقصة' });

    const dejaExiste = await ConducteurActionsModel.justificationDejaExiste(type, declaration_id);
    if (dejaExiste)
      return res.status(409).json({ message: 'التبرير موجود بالفعل' });

    await ConducteurActionsModel.insertJustification({
      type,
      declarationId: declaration_id,
      justification,
    });

    res.json({ message: 'تم إرسال التبرير بنجاح' });
  } catch (err) {
    console.error('❌ envoyerJustification:', err);
    res.status(500).json({ message: 'خطأ في الخادم' });
  }
};

// ═══════════════════════════════════════════════════════
// 📍 إرسال موقع GPS
// ═══════════════════════════════════════════════════════
exports.envoyerPosition = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    const conducteurId = await getConducteurId(req.user.id);

    if (!conducteurId)
      return res.status(404).json({ message: 'السائق غير موجود' });

    const aff = await getAffectationActive(conducteurId);
    const ligneId = aff?.ligne_id || null;

    await ConducteurActionsModel.upsertPosition({
      condId: conducteurId,
      ligneId: ligneId,
      latitude,
      longitude,
      vitesse: req.body.vitesse || 0,
    });

    req.io?.emit('position_update', {
      conducteur_id: conducteurId,
      ligne_id: ligneId,
      latitude,
      longitude,
      timestamp: new Date().toISOString(),
    });

    res.json({ message: 'تم إرسال الموقع بنجاح' });
  } catch (err) {
    console.error('❌ envoyerPosition:', err);
    res.status(500).json({ message: 'خطأ في الخادم' });
  }
};

// ═══════════════════════════════════════════════════════
// 📴 تعطيل GPS
// ═══════════════════════════════════════════════════════
exports.desactiverGPS = async (req, res) => {
  try {
    const conducteurId = await getConducteurId(req.user.id);

    if (!conducteurId)
      return res.status(404).json({ message: 'السائق غير موجود' });

    const aff = await getAffectationActive(conducteurId);

    await ConducteurActionsModel.desactiverGPS(conducteurId);

    req.io?.emit('gps_desactive', {
      conducteur_id: conducteurId,
      ligne_id: aff?.ligne_id || null,
    });

    res.json({ message: 'تم تعطيل GPS' });
  } catch (err) {
    console.error('❌ desactiverGPS:', err);
    res.status(500).json({ message: 'خطأ في الخادم' });
  }
};

// ═══════════════════════════════════════════════════════
// ⏱️ الإعلان عن تأخير — إشعار مؤقت
// ═══════════════════════════════════════════════════════
exports.declarerRetard = async (req, res) => {
  try {
    const { motif, duree_minutes, ligne_id } = req.body;
    const conducteurId = await getConducteurId(req.user.id);

    if (!conducteurId)
      return res.status(404).json({ message: 'السائق غير موجود' });

    if (!duree_minutes || !motif)
      return res.status(400).json({ message: 'المدة والسبب مطلوبان' });

    const aff = await getAffectationActive(conducteurId);
    const ligneId = ligne_id || aff?.ligne_id || null;

    if (!ligneId)
      return res.status(400).json({ message: 'لا يوجد خط مسند' });

    // ✅ التصحيح هنا: اسم الدالة الصحيح + تمرير ligneId
const retardExistant = await ConducteurActionsModel.retardDejaDeclareePourTrajet(conducteurId, ligneId);    if (retardExistant)
      return res.status(409).json({ message: 'يوجد تأخير قيد الانتظار بالفعل' });

    const retardId = await ConducteurActionsModel.insertRetard({
      condId: conducteurId,
      duree_minutes,
      motif,
      ligneId,
    });

    const ligneNum = await ConducteurActionsModel.getLigneNumero(ligneId);

    await _notifierPassagersLigne(
      req,
      ligneId,
      `⏱️ تأخير — خط ${ligneNum}`,
      `حافلتك (خط ${ligneNum}) سيتأخر حوالي ${duree_minutes} دقيقة. السبب: ${motif}.`,
      'retard',
      { retardId },
      duree_minutes
    );

    if (aff?.vehicule_id) {
      const vehicule = await getVehiculeEtProprietaire(aff.vehicule_id);
      const conducteur = await getConducteurInfo(conducteurId);

      if (vehicule?.proprietaire_id) {
        req.io?.to(`proprietaire_${vehicule.proprietaire_id}`).emit('retard_declare', {
          conducteur: { nom: conducteur?.nom, prenom: conducteur?.prenom },
          ligne: { numero: ligneNum },
          duree_minutes,
          motif,
          vehicule_immatriculation: vehicule.immatriculation,
          timestamp: new Date().toISOString()
        });
      }
    }

    req.io?.emit('retard_signale', {
      ligne_id: ligneId,
      motif,
      duree_minutes,
    });

    res.status(201).json({
      message: 'تم الإعلان عن التأخير',
      retard_id: retardId,
    });
  } catch (err) {
    console.error('❌ declarerRetard:', err);
    res.status(500).json({ message: 'خطأ في الخادم' });
  }
};
// ═══════════════════════════════════════════════════════
// 🔧 الإعلان عن عطل — إشعار يومي + المالك
// ═══════════════════════════════════════════════════════
exports.declarerPanne = async (req, res) => {
  console.log('📥 declarerPanne تم الاستدعاء', req.body);

  try {
    const { type_panne, description, ligne_id } = req.body;
    const conducteurId = await getConducteurId(req.user.id);

    if (!conducteurId)
      return res.status(404).json({ message: 'السائق غير موجود' });

    // ✅ نغلق أي عطل قديم مفتوح
    const existante = await ConducteurActionsModel.panneActiveExiste(conducteurId);
    if (existante) {
      await pool.query(
        `UPDATE panne SET statut = 'resolue', resolue = true, resolue_at = NOW()
         WHERE conducteur_id = $1 AND statut = 'en_cours'`,
        [conducteurId]
      );
    }

    if (!type_panne || !description)
      return res.status(400).json({ message: 'النوع والوصف مطلوبان' });

    const aff = await getAffectationActive(conducteurId);

    // ✅ ligne_id من الانتداب النشط أولاً
    const ligneId = aff?.ligne_id || ligne_id || null;
    const vehiculeId = aff?.vehicule_id || null;

    if (!ligneId)
      return res.status(400).json({ message: 'لا يوجد خط مسند' });

    console.log('📌 Affectation:', { ligneId, vehiculeId });

    // ✅ نحدث حالة المركبة
    if (vehiculeId) {
      await pool.query(
        `UPDATE vehicule SET etat = 'en panne' WHERE id = $1`,
        [vehiculeId]
      );
    }

    // ✅ INSERT مباشر مع vehicule_id
    const panneResult = await pool.query(
      `INSERT INTO panne (conducteur_id, ligne_id, vehicule_id, type_panne, description, statut, resolue, created_at)
       VALUES ($1, $2, $3, $4, $5, 'en_cours', false, NOW())
       RETURNING id, ligne_id, vehicule_id`,
      [conducteurId, ligneId, vehiculeId, type_panne, description]
    );

    const panneId = panneResult.rows[0].id;
    const panneVehiculeId = panneResult.rows[0].vehicule_id;

    console.log('✅ Panne insérée:', { panneId, ligneId, vehiculeId: panneVehiculeId });

    // ✅ إشعار خاص: غير للركاب اللي ريزارفاو
    const finDuJour = new Date();
    finDuJour.setHours(23, 59, 59, 999);
    const minutesRestantes = Math.floor((finDuJour - Date.now()) / 60000);

    const ligneNum = await ConducteurActionsModel.getLigneNumero(ligneId);
    await _notifierPassagersLigne(
      req,
      ligneId,
      `🚨 عطل — خط ${ligneNum}`,
      `حافلة الخط ${ligneNum} معطلة (${type_panne}). يرجى الانتظار.`,
      'panne',
      { panneId },
      minutesRestantes
    );

    // ✅ إشعار عام: للجميع
    await _notifierTousPassagers(
      `🚨 عطل — خط ${ligneNum}`,
      `${type_panne} — ${description}`,
      'panne',
      minutesRestantes,
      panneId
    );

    // إشعار المالك
    if (panneVehiculeId) {
      const vehicule = await getVehiculeEtProprietaire(panneVehiculeId);
      const conducteur = await getConducteurInfo(conducteurId);

      if (vehicule?.proprietaire_id && req.io) {
        req.io.to(`proprietaire_${vehicule.proprietaire_id}`).emit('panne_declaree', {
          vehicule_id: panneVehiculeId,
          immatriculation: vehicule.immatriculation,
          marque: vehicule.marque,
          modele: vehicule.modele,
          type_panne,
          description,
          conducteur: {
            nom: conducteur?.nom,
            prenom: conducteur?.prenom,
            telephone: conducteur?.telephone
          },
          panne_id: panneId,
          timestamp: new Date().toISOString()
        });
        console.log(`🚨 تم إشعار المالك ${vehicule.proprietaire_id} بالعطل`);
      }

      req.io?.emit('vehicule_status_change', {
        vehicule_id: panneVehiculeId,
        etat: 'en panne',
        type_panne
      });
    }

    req.io?.emit('panne_signalee', {
      ligne_id: ligneId,
      type_panne,
      description,
      panne_id: panneId,
    });

    res.status(201).json({
      message: 'تم الإعلان عن العطل',
      panne_id: panneId,
    });
  } catch (err) {
    console.error('❌ declarerPanne:', err);
    res.status(500).json({ message: 'خطأ في الخادم', error: err.message });
  }
};

// ═══════════════════════════════════════════════════════
// ✅ حل العطل — حذف الإشعارات + إشعار المالك + إشعار الركاب
// ═══════════════════════════════════════════════════════
exports.resoudrePanne = async (req, res) => {
  try {
    const { id } = req.params;
    const conducteurId = await getConducteurId(req.user.id);

    if (!conducteurId)
      return res.status(404).json({ message: 'السائق غير موجود' });

    // ✅ نجيب العطل مع كل المعلومات
    const panneAvant = await pool.query(
      `SELECT p.*, v.proprietaire_id, v.immatriculation, v.id as vehicule_id, p.ligne_id
       FROM panne p
       LEFT JOIN vehicule v ON v.id = p.vehicule_id
       WHERE p.id = $1 AND p.conducteur_id = $2`,
      [id, conducteurId]
    );

    if (panneAvant.rows.length === 0) {
      return res.status(404).json({ message: 'العطل غير موجود أو لا يخصك' });
    }

    const panneInfo = panneAvant.rows[0];
    const ligneId = panneInfo.ligne_id;

    console.log('🔍 [resoudrePanne] panneInfo complet:', panneInfo);
    console.log('🔍 [resoudrePanne] ligneId utilisé pour notifier:', ligneId);

    // ✅ نحدث العطل
     await pool.query(
  `UPDATE panne SET statut = 'resolue', resolue = true WHERE id = $1`,
      [id]
    );

    // ✅ نحدث المركبة لو ماكاش عطل آخر
    const autresPannes = await pool.query(
      `SELECT COUNT(*) FROM panne 
       WHERE vehicule_id = $1 AND statut = 'en_cours' AND id != $2`,
      [panneInfo.vehicule_id, id]
    );

    if (parseInt(autresPannes.rows[0].count) === 0) {
      await pool.query(
        `UPDATE vehicule SET etat = 'actif' WHERE id = $1`,
        [panneInfo.vehicule_id]
      );
    }

    // ✅ نخلي الإشعارات القديمة تنتهي صلاحيتها بدل حذفها (بحال يبقى تتبع)
await NotificationModel.expireByPanneId(parseInt(id));
    // ✅ إشعار الركاب بالحل
    const ligneNum = await ConducteurActionsModel.getLigneNumero(ligneId);
    await _notifierPassagersLigne(
      req,
      ligneId,
      `✅ تم حل العطل — خط ${ligneNum}`,
      'عادت الحافلة للعمل بشكل طبيعي.',
      'info',
      { panneId: parseInt(id) },
      30
    );

    // ✅ إشعار المالك
    if (panneInfo.proprietaire_id && req.io) {
      req.io.to(`proprietaire_${panneInfo.proprietaire_id}`).emit('panne_resolue', {
        vehicule_id: panneInfo.vehicule_id,
        immatriculation: panneInfo.immatriculation,
        panne_id: parseInt(id),
        timestamp: new Date().toISOString()
      });
      console.log(`✅ تم إشعار المالك ${panneInfo.proprietaire_id} بحل العطل`);
    }

    // ✅ إشعارات عامة
    req.io?.emit('vehicule_status_change', {
      vehicule_id: panneInfo.vehicule_id,
      etat: 'actif'
    });

    req.io?.emit('panne_resolue', {
      panne_id: parseInt(id),
      ligne_id: ligneId,
    });

    res.json({ 
      message: 'تم حل العطل — تم إشعار الركاب والمالك',
      panne_id: parseInt(id)
    });
  } catch (err) {
    console.error('❌ resoudrePanne:', err);
    res.status(500).json({ message: 'خطأ في الخادم', error: err.message });
  }
};
exports.resoudreRetard = async (req, res) => {
  try {
    const { id } = req.params;
    const conducteurId = await getConducteurId(req.user.id);

    if (!conducteurId)
      return res.status(404).json({ message: 'السائق غير موجود' });

    const retardAvant = await pool.query(
      `SELECT * FROM retard WHERE id = $1 AND conducteur_id = $2`,
      [id, conducteurId]
    );

    if (retardAvant.rows.length === 0)
      return res.status(404).json({ message: 'التأخير غير موجود أو لا يخصك' });

    const retardInfo = retardAvant.rows[0];

    await pool.query(
      `UPDATE retard SET statut = 'resolu' WHERE id = $1`,
      [id]
    );

    const ligneNum = await ConducteurActionsModel.getLigneNumero(retardInfo.ligne_id);
    await _notifierPassagersLigne(
      req,
      retardInfo.ligne_id,
      `✅ انتهى التأخير — خط ${ligneNum}`,
      'عادت الحافلة لجدولها الطبيعي.',
      'info',
      { retardId: parseInt(id) },
      30
    );

    res.json({ message: 'تم إنهاء التأخير', retard_id: parseInt(id) });
  } catch (err) {
    console.error('❌ resoudreRetard:', err);
    res.status(500).json({ message: 'خطأ في الخادم', error: err.message });
  }
};
// ═══════════════════════════════════════════════════════
// 📋 لائحة الأعطال — كل الأعطال المفتوحة تاع السائق
// ═══════════════════════════════════════════════════════
exports.getPannesEnCours = async (req, res) => {
  try {
    const conducteurId = await getConducteurId(req.user.id);

    console.log('🔍 getPannesEnCours - req.user.id:', req.user.id);
    console.log('🔍 getPannesEnCours - conducteurId:', conducteurId);

    if (!conducteurId)
      return res.status(404).json({ message: 'السائق غير موجود' });

    // ✅ جيب كل البانات للتحقق (بدون فلتر statut)
    const allPannes = await pool.query(
      `SELECT id, conducteur_id, statut, type_panne, created_at, resolue
       FROM panne 
       WHERE conducteur_id = $1
       ORDER BY created_at DESC`,
      [conducteurId]
    );

    console.log('🔍 Toutes les pannes pour ce conducteur:', allPannes.rows);

    // ✅ جيب فقط البانات المفتوحة (مع فلتر مرن)
    const r = await pool.query(
      `SELECT p.id, p.type_panne, p.description, p.statut, p.created_at,
              l.numero as ligne_numero, l.nom as ligne_nom
       FROM panne p
       LEFT JOIN ligne l ON l.id = p.ligne_id
       WHERE p.conducteur_id = $1 
         AND (p.statut = 'en_cours' OR p.statut IS NULL)
         AND (p.resolue = false OR p.resolue IS NULL)
       ORDER BY p.created_at DESC`,
      [conducteurId]
    );

    console.log(`📋 Pannes en cours pour conducteur ${conducteurId}:`, r.rows.length);
    console.log('📋 Rows:', r.rows);

    res.json({ pannes: r.rows });
  } catch (err) {
    console.error('❌ getPannesEnCours:', err);
    res.status(500).json({ message: 'خطأ في الخادم', error: err.message });
  }
};
exports.getRetardEnCours = async (req, res) => {
  try {
    const conducteurId = await getConducteurId(req.user.id);
    if (!conducteurId)
      return res.status(404).json({ message: 'السائق غير موجود' });

    const r = await pool.query(
      `SELECT r.id, r.duree_minutes, r.motif, r.statut, r.created_at,
              l.numero as ligne_numero, l.nom as ligne_nom
       FROM retard r
       LEFT JOIN ligne l ON l.id = r.ligne_id
       WHERE r.conducteur_id = $1 AND r.statut = 'en_attente'
       ORDER BY r.created_at DESC LIMIT 1`,
      [conducteurId]
    );

    res.json({ retard: r.rows[0] || null });
  } catch (err) {
    console.error('❌ getRetardEnCours:', err);
    res.status(500).json({ message: 'خطأ في الخادم' });
  }
};
// ═══════════════════════════════════════════════════════
// 📋 جلب الإعلانات المعلقة
// ═══════════════════════════════════════════════════════
exports.getDeclarationsEnAttente = async (req, res) => {
  try {
    const conducteurId = await getConducteurId(req.user.id);

    if (!conducteurId)
      return res.status(404).json({ message: 'السائق غير موجود' });

    const declarations = await ConducteurActionsModel.getDeclarationsEnAttente(conducteurId);
    res.json(declarations);
  } catch (err) {
    console.error('❌ getDeclarationsEnAttente:', err);
    res.status(500).json({ message: 'خطأ في الخادم' });
  }
};

// ═══════════════════════════════════════════════════════
// 🪑 المقاعد الفارغة — عرض
// ═══════════════════════════════════════════════════════
exports.getEspacesVides = async (req, res) => {
  try {
    const conducteurId = await getConducteurId(req.user.id);
    if (!conducteurId)
      return res.status(404).json({ message: 'السائق غير موجود' });

    const aff = await getAffectationActive(conducteurId);
    if (!aff) {
      return res.json({
        ligne_id: null,
        places_total: 0,
        places_reservees: 0,
        places_dispo: 0,
      });
    }

    const data = await ConducteurActionsModel.getPlacesLigne(aff.ligne_id);
    res.json({
      ligne_id: aff.ligne_id,
      places_total: Number(data.places_total || 0),
      places_dispo: Number(data.places_dispo || 0),
      places_reservees: Number(data.places_reservees || 0),
    });
  } catch (err) {
    console.error('❌ getEspacesVides:', err);
    res.status(500).json({ message: 'خطأ في الخادم' });
  }
};

// ═══════════════════════════════════════════════════════
// 🪑 المقاعد الفارغة — تعديل
// ═══════════════════════════════════════════════════════
exports.ajusterEspacesVides = async (req, res) => {
  try {
    const { places_dispo } = req.body;

    if (places_dispo === undefined || places_dispo === null)
      return res.status(400).json({ message: 'القيمة مطلوبة' });

    const conducteurId = await getConducteurId(req.user.id);
    if (!conducteurId)
      return res.status(404).json({ message: 'السائق غير موجود' });

    const aff = await getAffectationActive(conducteurId);
    if (!aff)
      return res.status(404).json({ message: 'لا يوجد رحلة جارية' });

    const data = await ConducteurActionsModel.getPlacesLigne(aff.ligne_id);
    const capaciteMax = Number(data.places_total || 0);

    if (places_dispo < 0 || places_dispo > capaciteMax) {
      return res.status(400).json({
        message: `قيمة غير صالحة، بين 0 و ${capaciteMax}`
      });
    }

    const actuel = Number(data.places_dispo || 0);
    if (places_dispo === actuel)
      return res.status(400).json({ message: 'لم يتم اكتشاف أي تغيير' });

    await ConducteurActionsModel.updatePlacesDispo({
      ligneId: aff.ligne_id,
      nouvellesPlaces: places_dispo,
      capaciteMax,
    });

    res.json({ message: 'تم تحديث عدد المقاعد بنجاح' });
  } catch (err) {
    console.error('❌ ajusterEspacesVides:', err);
    res.status(500).json({ message: err.message || 'خطأ في الخادم' });
  }
};

// ═══════════════════════════════════════════════════════
// 📅 الدوامات
// ═══════════════════════════════════════════════════════
exports.getPermanences = async (req, res) => {
  try {
    const conducteurId = await getConducteurId(req.user.id);
    if (!conducteurId)
      return res.status(404).json({ message: 'السائق غير موجود' });

    const rows = await ConducteurActionsModel.getPermanences(conducteurId);

    if (rows.length === 0) {
      const jours = ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'];
      return res.json(jours.map(j => ({
        jour: j,
        heure_debut: ['Samedi','Dimanche'].includes(j) ? null : '08:00',
        heure_fin: ['Samedi','Dimanche'].includes(j) ? null : '16:00',
        repos: ['Samedi','Dimanche'].includes(j),
      })));
    }

    res.json(rows);
  } catch (err) {
    console.error('❌ getPermanences:', err);
    res.status(500).json({ message: 'خطأ في الخادم' });
  }
};

// ═══════════════════════════════════════════════════════
// 🎫 حجوزات الخط
// ═══════════════════════════════════════════════════════
exports.getReservationsLigne = async (req, res) => {
  try {
    const conducteurId = await getConducteurId(req.user.id);
    console.log('🔍 conducteurId:', conducteurId);

    if (!conducteurId)
      return res.status(404).json({ message: 'السائق غير موجود' });

    const aff = await getAffectationActive(conducteurId);
    console.log('🔍 الانتداب النشط:', aff);

    if (!aff) {
      console.log('❌ لا يوجد انتداب نشط');
      return res.json({
        ligne: null,
        reservations: [],
        total_places: 0,
        places_reservees: 0,
        places_dispo: 0,
      });
    }

    const ligne = await ConducteurActionsModel.getLigne(aff.ligne_id);
    console.log('🔍 الخط:', ligne);

    // ✅ جيب نفس الـ trajet النشط
    const trajetActif = await ConducteurActionsModel.getTrajetActif(aff.ligne_id);
    console.log('🔍 Trajet actif:', trajetActif);

    const reservations = await ConducteurActionsModel.getReservationsLigne(aff.ligne_id);
    console.log('🔍 عدد الحجوزات:', reservations.length);

    const summary = await ConducteurActionsModel.getPlacesSummary(aff.ligne_id);
    console.log('🔍 الملخص:', summary);

    const total = Number(summary.places_total || 0);
    const dispo = Number(summary.places_dispo || 0);

    res.json({
      ligne,
      trajet: trajetActif,
      reservations,
      total_places: total,
      places_reservees: total - dispo,
      places_dispo: dispo,
    });
  } catch (err) {
    console.error('❌ getReservationsLigne:', err);
    res.status(500).json({ message: 'خطأ في الخادم' });
  }
  
};