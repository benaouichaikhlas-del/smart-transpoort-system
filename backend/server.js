require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });

const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const cron = require('node-cron');
const pool = require('./db/pool');

console.log('📁 .env path:', require('path').resolve(__dirname, '.env'));
console.log('SMTP_HOST:', process.env.SMTP_HOST);
console.log('SMTP_USER:', process.env.SMTP_USER);
console.log('SMTP_PASS:', process.env.SMTP_PASS ? '✅ موجود' : '❌ مفقود');
console.log('MAIL_FROM:', process.env.MAIL_FROM);

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
  transports: ['websocket', 'polling'],
});

app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
  req.io = io;
  next();
});

app.use((req, res, next) => {
  console.log('🌐 GLOBAL:', req.method, req.originalUrl);
  next();
});

// ═══════════════════════════════════════════════
// 📡 ROUTES
// ═══════════════════════════════════════════════
app.use('/api/auth',              require('./routes/auth.routes'));
app.use('/api/visiteur',          require('./routes/visiteur.routes'));
app.use('/api/proprietaire',      require('./routes/proprietaire.routes'));
app.use('/api/admin',             require('./routes/admin.routes'));
app.use('/api/conducteurs',       require('./routes/conducteur.routes'));
app.use('/api/vehicule',          require('./routes/vehicule.routes'));
app.use('/api/ligne',             require('./routes/ligne.routes'));
app.use('/api/affectation',       require('./routes/affectation.routes'));
app.use('/api/annonce',           require('./routes/annonce.routes'));
app.use('/api/conducteur-actions',require('./routes/conducteur_actions.routes'));
app.use('/api/passager',          require('./routes/passager.routes'));
app.use('/api/notifications',     require('./routes/notification.routes'));
app.use('/api/gps',               require('./routes/gps.routes'));
app.use('/api/trajets',           require('./routes/trajet.routes'));
app.use('/api/permanences',       require('./routes/permanence.routes'));

app.get('/', (req, res) => res.send('API OK'));

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    socket_clients: io.engine.clientsCount,
    timestamp: new Date().toISOString(),
  });
});

// ═══════════════════════════════════════════════
// 🔌 SOCKET.IO
// ═══════════════════════════════════════════════
const connectedUsers = new Map();

io.on('connection', (socket) => {
  console.log('🔌 Client connecté:', socket.id);

  socket.on('join_proprietaire', (data) => {
    const { proprietaire_id } = data;
    if (!proprietaire_id) return;
    const room = `proprietaire_${proprietaire_id}`;
    socket.join(room);
    connectedUsers.set(socket.id, { userId: proprietaire_id, role: 'proprietaire', room });
    console.log(`🏠 Propriétaire ${proprietaire_id} joined room: ${room}`);
  });

  socket.on('join_conducteur', (data) => {
    const { conducteur_id } = data;
    if (!conducteur_id) return;
    const room = `conducteur_${conducteur_id}`;
    socket.join(room);
    connectedUsers.set(socket.id, { userId: conducteur_id, role: 'conducteur', room });
    console.log(`🚌 Conducteur ${conducteur_id} joined room: ${room}`);
  });

  socket.on('join_passager', (data) => {
    const { passager_id } = data;
    if (!passager_id) return;
    const room = `passager_${passager_id}`;
    socket.join(room);
    connectedUsers.set(socket.id, { userId: passager_id, role: 'passager', room });
    console.log(`🧍 Passager ${passager_id} joined room: ${room}`);
  });

  socket.on('join_visiteur', () => {
    socket.join('visiteurs');
    connectedUsers.set(socket.id, { role: 'visiteur', room: 'visiteurs' });
    console.log(`👀 Visiteur ${socket.id} joined global room`);
  });

  socket.on('disconnect', () => {
    const user = connectedUsers.get(socket.id);
    if (user) {
      console.log(`❌ ${user.role?.toUpperCase()} ${user.userId || socket.id} déconnecté`);
      connectedUsers.delete(socket.id);
    } else {
      console.log('🔌 Client déconnecté:', socket.id);
    }
  });
});

app.notifyProprietaire = (proprietaireId, event, data) => {
  io.to(`proprietaire_${proprietaireId}`).emit(event, data);
};

app.notifyConducteur = (conducteurId, event, data) => {
  io.to(`conducteur_${conducteurId}`).emit(event, data);
};

app.notifyVisiteurs = (event, data) => {
  io.to('visiteurs').emit(event, data);
};

app.notifyPassagersLigne = (ligneId, event, data) => {
  io.to(`ligne_${ligneId}`).emit(event, data);
};

cron.schedule('* * * * *', async () => {
  try {
    const r = await pool.query(
      `DELETE FROM notification WHERE expires_at IS NOT NULL AND expires_at < NOW()`
    );
    if (r.rowCount > 0) {
      console.log(`🗑️ ${r.rowCount} notification(s) expirée(s) supprimée(s)`);
    }
  } catch (err) {
    console.error('❌ Cron error:', err);
  }
});

app.use((req, res) => {
  res.status(404).json({ message: 'Route introuvable' });
});

app.use((err, req, res, next) => {
  console.error('❌ Erreur serveur:', err);
  res.status(500).json({ message: 'Erreur serveur interne' });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
});