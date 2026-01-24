-- Migration pour ajouter les champs de localisation aux agents
-- À exécuter après avoir arrêté le serveur

ALTER TABLE agents ADD COLUMN IF NOT EXISTS latitude DECIMAL(9,6);
ALTER TABLE agents ADD COLUMN IF NOT EXISTS longitude DECIMAL(9,6);
ALTER TABLE agents ADD COLUMN IF NOT EXISTS last_location_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Mettre à jour last_location_update pour les agents existants
UPDATE agents SET last_location_update = CURRENT_TIMESTAMP WHERE last_location_update IS NULL;