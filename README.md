# 🚌 Smart Transport System

<div align="center">

**Système Intelligent de Gestion des Transports Urbains**

[![Flutter](https://img.shields.io/badge/Frontend-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Backend-Node.js-339933?logo=node.js)](https://nodejs.org)
[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-4169E1?logo=postgresql)](https://www.postgresql.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## 📋 Vue d'ensemble

Ce projet est un **système intelligent de gestion des transports urbains**, développé dans le cadre d'un projet de fin d'études.
Il permet aux voyageurs et aux chauffeurs d'interagir en temps réel via une application Flutter connectée à un Backend robuste.

### ✨ Fonctionnalités principales
- 🗺️ **Suivi GPS en temps réel** — connaître la position du bus instantanément
- 🪑 **Réservation de sièges** — réserver sa place à l'avance via l'application
- 🔔 **Notifications instantanées** — alertes lors de l'approche ou du retard du bus
- 👤 **Comptes multiples** — interface dédiée aux voyageurs et aux chauffeurs
- 📊 **Tableau de bord** — gestion des trajets et des voyageurs

---

## 🏗️ Architecture du projet

```
smart-transport-system/
│
├── 📁 frontend/          # Application Flutter (Voyageur + Chauffeur)
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── 📁 backend/           # API Node.js + Express
│   ├── src/
│   ├── routes/
│   ├── controllers/
│   ├── models/
│   └── package.json
│
├── 📄 README.md
├── 📄 .gitignore
└── 📄 LICENSE
```

---

## 🛠️ Technologies utilisées

| Couche | Technologie |
|--------|-------------|
| **Frontend** | Flutter, Dart |
| **Backend** | Node.js, Express.js |
| **Base de données** | PostgreSQL |
| **Temps réel** | Socket.io / WebSockets |
| **Cartes & GPS** | Google Maps API |
| **Authentification** | JWT (JSON Web Tokens) |

---

## 🚀 Comment exécuter le projet

### 1️⃣ Prérequis
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js](https://nodejs.org/) (v18+)
- [PostgreSQL](https://www.postgresql.org/download/)
- Git

### 2️⃣ Lancer le Backend

```bash
# Entrer dans le dossier Backend
cd backend

# Installer les dépendances
npm install

# Créer le fichier d'environnement
cp .env.example .env
# Modifier .env avec vos informations de base de données

# Démarrer le serveur
npm run dev
```

### 3️⃣ Lancer le Frontend

```bash
# Dans un nouveau terminal, entrer dans le dossier Frontend
cd frontend

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

---

## 📸 Captures d'écran

> Ajoutez ici des images de l'application

| Écran Voyageur | Écran Chauffeur | Carte GPS |
|:--------------:|:---------------:|:---------:|
| ![Passenger](screenshots/passenger.png) | ![Driver](screenshots/driver.png) | ![Map](screenshots/map.png) |

---

## 👩‍💻 Auteur

Ce projet a été développé dans le cadre d'un projet de fin d'études.

---

## 📄 Licence

Ce projet est sous licence [MIT](LICENSE).

---

<div align="center">

⭐ **Si vous aimez ce projet, n'oubliez pas de mettre une étoile !**

</div>
