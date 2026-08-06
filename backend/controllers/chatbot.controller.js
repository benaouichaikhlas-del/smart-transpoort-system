const pool = require('../db/pool');

/**
 * Chatbot intelligent — يقرأ السياق من الـ DB ويبني الرد ديناميكياً
 */
async function buildContext(userId) {
  const ctx = {
    lignes: [],
    horaires: [],
    retards: [],
    reservations: [],
    stats: { totalLignes: 0, totalHoraires: 0, incidents: 0 }
  };

  try {
    // 1. Lignes
    const lignesRes = await pool.query('SELECT id, numero, nom FROM ligne ORDER BY numero');
    ctx.lignes = lignesRes.rows;
    ctx.stats.totalLignes = lignesRes.rows.length;

    // 2. Horaires du jour
    const horRes = await pool.query(
      `SELECT l.numero, l.nom, h.heure_depart, h.heure_arrivee, h.places_restantes, h.jours
       FROM horaire h
       JOIN ligne l ON h.ligne_id = l.id
       ORDER BY h.heure_depart
       LIMIT 30`
    );
    ctx.horaires = horRes.rows;
    ctx.stats.totalHoraires = horRes.rows.length;

    // 3. Retards/Pannes en cours
    const retRes = await pool.query(
      `SELECT r.duree_minutes, r.motif, l.numero, l.nom, c.prenom, c.nom as c_nom
       FROM retard r
       JOIN ligne l ON r.ligne_id = l.id
       JOIN conducteur c ON r.conducteur_id = c.id
       WHERE r.resolu = false
       ORDER BY r.created_at DESC LIMIT 5`
    );
    ctx.retards = retRes.rows;
    ctx.stats.incidents = retRes.rows.length;

    // 4. Réservations du passager
    if (userId) {
      const resaRes = await pool.query(
        `SELECT r.nb_places, r.date, l.numero, l.nom, h.heure_depart
         FROM reservation r
         JOIN ligne l ON r.ligne_id = l.id
         LEFT JOIN horaire h ON r.horaire_id = h.id
         WHERE r.passager_id = $1 AND r.statut = 'active'
         ORDER BY r.date DESC LIMIT 5`,
        [userId]
      );
      ctx.reservations = resaRes.rows;
    }

  } catch (err) {
    console.error('❌ buildContext error:', err.message);
  }

  return ctx;
}

function trouverLigne(ctx, msg) {
  // يبحث عن رقم خط في الرسالة
  const match = msg.match(/(?:ligne|bus|numero|n°|#|خط)?\s*(\d+[a-z]?)/i);
  if (match) {
    const numero = match[1];
    return ctx.lignes.find(l => l.numero.toString().toLowerCase() === numero.toLowerCase());
  }
  // يبحث عن اسم مدينة
  for (const l of ctx.lignes) {
    const nomLower = l.nom.toLowerCase();
    const parts = nomLower.split('-').map(p => p.trim());
    for (const part of parts) {
      if (part.length > 2 && msg.includes(part)) {
        return l;
      }
    }
  }
  return null;
}

const chatbot = async (req, res) => {
  try {
    const { message } = req.body;
    const userId = req.user?.id || null;

    if (!message || message.trim() === '') {
      return res.json({ reponse: 'Veuillez poser une question.' });
    }

    const msg = message.toLowerCase().trim();
    const ctx = await buildContext(userId);
    let reponse = '';

    // ─── 1. Salutations ───
    if (/\b(bonjour|salut|hello|hey|hi|coucou|bonsoir|marhaba|ahlan|msa|sba7|هاي|بونجور|مرحبا|صباح|مساء|سلام)\b/.test(msg)) {
      const nomsLignes = ctx.lignes.slice(0, 3).map(l => l.nom).join(', ');
      reponse = `Bonjour ! 👋 Bienvenue sur TransportDZ. Nous avons ${ctx.stats.totalLignes} lignes actives, dont ${nomsLignes}... Comment puis-je vous aider ?`;
    }

    // ─── 2. Lignes disponibles ───
    else if (/\b(lignes?|bus|transport|trajets?)\b.*\b(disponibles?|existe|propose|y a|liste|lesquels|quels|quelles|toutes|عندكم|وش حال|كاين|كاينين|شحال)\b|\b(liste|quels|quelles|عندكم|كاين|كاينين)\b.*\b(lignes?|bus|transport|trajets?)\b/.test(msg)) {
      if (ctx.lignes.length === 0) {
        reponse = 'Aucune ligne n\'est disponible pour le moment.';
      } else {
        const lignes = ctx.lignes.map(l => `• **${l.numero}** — ${l.nom}`).join('\n');
        reponse = `Nous avons **${ctx.stats.totalLignes} lignes** disponibles actuellement :\n\n${lignes}\n\nDemandez-moi les horaires d'une ligne spécifique !`;
      }
    }

    // ─── 3. Horaires d'une ligne spécifique ───
    else if (/\b(horaires?|heures?|quand|a quelle heure|schedule|depart|arrivee|temps|ساعات|وقت|متى|منين|حتى|وين|من وين|للوين)\b/.test(msg)) {
      const ligne = trouverLigne(ctx, msg);
      if (ligne) {
        const horairesLigne = ctx.horaires.filter(h => h.numero === ligne.numero);
        if (horairesLigne.length > 0) {
          const liste = horairesLigne.map(h => 
            `🕐 ${h.heure_depart?.substring(0,5) || '--:--'} → ${h.heure_arrivee?.substring(0,5) || '--:--'} | ${h.places_restantes || '?'} places restantes`
          ).join('\n');
          reponse = `**Ligne ${ligne.numero} — ${ligne.nom}**\n\n${liste}\n\n💡 Tapez "réserver" pour réserver une place !`;
        } else {
          reponse = `La ligne **${ligne.numero} — ${ligne.nom}** existe, mais je n'ai pas d'horaires programmés pour elle actuellement.`;
        }
      } else {
        reponse = `De quelle ligne souhaitez-vous les horaires ? Voici les lignes disponibles :\n\n${ctx.lignes.slice(0, 5).map(l => `• ${l.numero} — ${l.nom}`).join('\n')}`;
      }
    }

    // ─── 4. Recherche par destination (ville) ───
    else if (/\b(pour|vers|a|aller|direction|roh|نروح|لوين|لو)\b/.test(msg)) {
      const ville = msg.replace(/.*\b(pour|vers|a|aller|direction|roh|نروح|لوين|لو)\b\s*/, '').trim();
      const lignesMatch = ctx.lignes.filter(l => l.nom.toLowerCase().includes(ville));
      if (lignesMatch.length > 0) {
        const liste = lignesMatch.map(l => `• **${l.numero}** — ${l.nom}`).join('\n');
        reponse = `Pour aller à **${ville}**, vous pouvez prendre :\n\n${liste}\n\nDemandez-moi les horaires de la ligne qui vous intéresse !`;
      } else {
        reponse = `Je n'ai trouvé aucune ligne vers **${ville}**. Voici les destinations disponibles :\n\n${ctx.lignes.slice(0, 5).map(l => `• ${l.nom}`).join('\n')}`;
      }
    }

    // ─── 5. Réservation ───
    else if (/\b(réserver|réservation|réserve|book|place|billet|ticket|acheter|حجز|حجزت|بلاص|تيكي|réserver)\b/.test(msg)) {
      reponse = 'Pour réserver une place :\n\n1️⃣ Allez dans l\'onglet **Réserver**\n2️⃣ Choisissez votre ligne\n3️⃣ Sélectionnez la date et l\'horaire\n4️⃣ Confirmez votre réservation\n\n💡 Vous pouvez aussi me demander : "Horaires ligne 10" pour voir les créneaux disponibles !';
    }

    // ─── 6. Mes réservations ───
    else if (/\b(mes réservations|mes billets|mes places|my reservations|mes tickets|حجوزاتي|حجوزات|رزرواتي|réservations)\b/.test(msg)) {
      if (!userId) {
        reponse = 'Connectez-vous pour voir vos réservations. Allez dans l\'onglet **Profil** → **Se connecter**.';
      } else if (ctx.reservations.length === 0) {
        reponse = 'Vous n\'avez aucune réservation active pour le moment.\n\n💡 Allez dans l\'onglet **Réserver** pour planifier votre prochain trajet !';
      } else {
        const resas = ctx.reservations.map(r => 
          `• **${r.numero}** — ${r.nom}\n  📅 ${r.date?.toISOString().split('T')[0] || ''} à ${r.heure_depart?.substring(0,5) || ''}\n  🎫 ${r.nb_places} place(s)`
        ).join('\n\n');
        reponse = `Vous avez **${ctx.reservations.length} réservation(s) active(s)** :\n\n${resas}`;
      }
    }

    // ─── 7. Retards / Pannes ───
    else if (/\b(retard|panne|problème|incident|en retard|retards|pannes|problèmes|تأخير|عطل|مشكل|بروبليم|واش كاين مشكل|واش كاين تأخير)\b/.test(msg)) {
      if (ctx.retards.length === 0) {
        reponse = '✅ Bonne nouvelle ! Aucun retard ou panne n\'est signalé actuellement. Tous les bus roulent normalement ! 🚌';
      } else {
        const incidents = ctx.retards.map(r => 
          `⚠️ **Ligne ${r.numero}** — ${r.nom}\n   ⏱️ Retard de ${r.duree_minutes} minutes\n   👤 Conducteur : ${r.prenom} ${r.c_nom}\n   📝 Motif : ${r.motif || 'Non spécifié'}`
        ).join('\n\n');
        reponse = `🚨 **${ctx.stats.incidents} incident(s) en cours** :\n\n${incidents}\n\n💡 Consultez l\'onglet **Alertes** pour plus de détails.`;
      }
    }

    // ─── 8. Places disponibles ───
    else if (/\b(places?|sièges?|disponibles?|reste|restent|بلاص|بلاصات|كاين بلاص|places restantes)\b/.test(msg)) {
      const ligne = trouverLigne(ctx, msg);
      if (ligne) {
        const horairesLigne = ctx.horaires.filter(h => h.numero === ligne.numero);
        if (horairesLigne.length > 0) {
          const placesInfo = horairesLigne.map(h => 
            `🕐 ${h.heure_depart?.substring(0,5)} → ${h.places_restantes || '?'} places restantes`
          ).join('\n');
          reponse = `**Ligne ${ligne.numero} — ${ligne.nom}**\n\nPlaces disponibles :\n${placesInfo}\n\n⚡ Réservez vite avant qu'il ne soit trop tard !`;
        } else {
          reponse = `Je n'ai pas d'informations sur les places pour la ligne ${ligne.numero} actuellement.`;
        }
      } else {
        reponse = `De quelle ligne voulez-vous connaître les places disponibles ?\n\n${ctx.lignes.slice(0, 5).map(l => `• ${l.numero} — ${l.nom}`).join('\n')}`;
      }
    }

    // ─── 9. Évaluation ───
    else if (/\b(évaluer|note|avis|rating|étoiles?|noter|commenter|تقييم|نقاط|نجوم|évaluation)\b/.test(msg)) {
      reponse = '⭐ Vous pouvez évaluer une ligne dans l\'onglet **Évaluer**.\n\nDonnez une note de 1 à 5 étoiles et laissez un commentaire pour aider les autres passagers !';
    }

    // ─── 10. Prix / Tarifs ───
    else if (/\b(prix|tarif|combien|cout|price|coûte|coût|بشحال|ثمن|سوما|فلوس|بيكم|بش حال)\b/.test(msg)) {
      reponse = '💰 Les tarifs varient selon la ligne et la distance parcourue.\n\nPour connaître le prix exact d\'un trajet :\n1️⃣ Allez dans l\'onglet **Réserver**\n2️⃣ Sélectionnez votre ligne\n3️⃣ Le prix s\'affichera avant la confirmation';
    }

    // ─── 11. Localisation / GPS ───
    else if (/\b(ou est|localisation|position|gps|ou se trouve|carte|suivre|trouver|وين|فين|خريطة|موقع|ou sont)\b/.test(msg)) {
      reponse = '🗺️ Vous pouvez suivre les bus en temps réel !\n\nAllez dans l\'onglet **Accueil** → **Voir sur la carte** pour localiser les bus en direct.';
    }

    // ─── 12. Statistiques générales ───
    else if (/\b(statistiques?|stats|info|informations|général|resume|résumé|واش كاين|شنو كاين|شنو جديد)\b/.test(msg)) {
      reponse = `📊 **TransportDZ en chiffres** :\n\n` +
        `🚌 ${ctx.stats.totalLignes} lignes actives\n` +
        `🕐 ${ctx.stats.totalHoraires} horaires programmés\n` +
        `${ctx.stats.incidents > 0 ? `⚠️ ${ctx.stats.incidents} incident(s) signalé(s)` : '✅ Aucun incident signalé'}\n\n` +
        `Demandez-moi les détails d'une ligne spécifique !`;
    }

    // ─── 13. Aide ───
    else if (/\b(aide|help|comment|comment ca marche|que peux-tu faire|que fais-tu|que peut|مساعدة|كيفاش|شنو|شكون|شنو تقدر|واش تقدر)\b/.test(msg)) {
      reponse = `🤖 **Voici ce que je peux faire pour vous :**\n\n` +
        `🚌 **Lignes** — "Quelles lignes disponibles ?"\n` +
        `🕐 **Horaires** — "Horaires ligne 10"\n` +
        `📍 **Destinations** — "Bus pour Constantine"\n` +
        `📅 **Réservations** — "Mes réservations" / "Comment réserver ?"\n` +
        `⚠️ **Incidents** — "Y a-t-il des retards ?"\n` +
        `💺 **Places** — "Places disponibles ligne 5"\n` +
        `⭐ **Évaluations** — "Comment évaluer ?"\n` +
        `🗺️ **Localisation** — "Où est le bus ?"\n\n` +
        `Posez-moi votre question ! 😊`;
    }

    // ─── 14. Au revoir ───
    else if (/\b(au revoir|bye|a plus|a bientot|salam|ciao|merci|شكرا|باي|الى اللقاء|تصبح على خير|bonne nuit)\b/.test(msg)) {
      reponse = 'Au revoir ! 👋 Bon voyage avec TransportDZ ! N\'hésitez pas à revenir si vous avez besoin d\'aide.';
    }

    // ─── 15. Fallback intelligent ───
    else {
      // يحاول يفهم السياق
      const ligne = trouverLigne(ctx, msg);
      if (ligne) {
        reponse = `Je vois que vous parlez de la **ligne ${ligne.numero} — ${ligne.nom}**.\n\nQue voulez-vous savoir ?\n• "Horaires ligne ${ligne.numero}"\n• "Places disponibles ligne ${ligne.numero}"\n• "Y a-t-il des retards sur la ligne ${ligne.numero} ?"`;
      } else {
        reponse = `Je n'ai pas bien compris votre demande. 😅\n\n` +
          `Essayez par exemple :\n` +
          `• "Quelles lignes disponibles ?"\n` +
          `• "Horaires ligne 10"\n` +
          `• "Bus pour Constantine"\n` +
          `• "Y a-t-il des retards ?"\n\n` +
          `Ou tapez **"aide"** pour voir la liste complète.`;
      }
    }

    console.log('🤖 CHATBOT:', message, '→', reponse.substring(0, 80) + '...');
    return res.json({ reponse });

  } catch (error) {
    console.error('❌ CHATBOT CRASH:', error);
    return res.json({ 
      reponse: 'Désolé, une erreur est survenue. Veuillez réessayer plus tard.' 
    });
  }
};

module.exports = { chatbot };