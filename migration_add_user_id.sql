-- ===========================================
-- MIGRATION : Ajout de la colonne user_id à la table clients
-- ===========================================

-- Ajouter la colonne user_id à la table clients
ALTER TABLE clients ADD COLUMN user_id INTEGER;

-- Ajouter la contrainte de clé étrangère
ALTER TABLE clients ADD CONSTRAINT fk_clients_user_id
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Ajouter un index pour optimiser les performances
CREATE INDEX idx_clients_user_id ON clients(user_id);

-- ===========================================
-- OPTIONNEL : Migrer les données existantes
-- ===========================================
-- Note: Cette section est commentée car elle nécessite une logique métier
-- pour déterminer quel user correspond à quel client
-- Vous devrez l'adapter selon vos besoins

-- Exemple de migration (à adapter selon vos données) :
-- UPDATE clients SET user_id = (
--     SELECT id FROM users WHERE email = 'client@example.com' LIMIT 1
-- ) WHERE nom_point_vente = 'Nom du point de vente';

-- ===========================================
-- FIN DE LA MIGRATION
-- ===========================================