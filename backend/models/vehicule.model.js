const pool = require('../db/pool');

const getByProprietaire = async (propId) => {
  const r = await pool.query(
    'SELECT * FROM vehicule WHERE proprietaire_id = $1 ORDER BY created_at DESC',
    [propId]
  );
  return r.rows;
};

const create = async ({
  marque, modele, immatriculation, capacite, proprietaire_id,
  couleur, puissance, annee_service, type_vehicule,
  wilaya_mat, type_mat, serie_mat, annee_mat
}) => {
  const r = await pool.query(
    `INSERT INTO vehicule
       (marque, modele, immatriculation, capacite, proprietaire_id,
        couleur, puissance, annee_service, type_vehicule,
        wilaya_mat, type_mat, serie_mat, annee_mat)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
     RETURNING id`,
    [marque, modele || null, immatriculation, capacite || 30, proprietaire_id,
     couleur || '#3B82F6', puissance || null, annee_service || null,
     type_vehicule || null, wilaya_mat || null, type_mat || null,
     serie_mat || null, annee_mat || null]
  );
  return r.rows[0];
};

const update = async ({
  id, marque, modele, immatriculation, capacite, etat,
  couleur, puissance, annee_service, type_vehicule,
  wilaya_mat, type_mat, serie_mat, annee_mat
}) => {
  await pool.query(
    `UPDATE vehicule
     SET marque=$1, modele=$2, immatriculation=$3, capacite=$4, etat=$5,
         couleur=$6, puissance=$7, annee_service=$8, type_vehicule=$9,
         wilaya_mat=$10, type_mat=$11, serie_mat=$12, annee_mat=$13
     WHERE id=$14`,
    [marque, modele || null, immatriculation, capacite || 30, etat || 'actif',
     couleur || '#3B82F6', puissance || null, annee_service || null,
     type_vehicule || null, wilaya_mat || null, type_mat || null,
     serie_mat || null, annee_mat || null, id]
  );
};

const deleteById = async (id) => {
  await pool.query('DELETE FROM vehicule WHERE id = $1', [id]);
};

module.exports = { getByProprietaire, create, update, delete: deleteById };