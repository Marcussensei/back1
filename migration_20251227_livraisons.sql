-- Migration: Add missing columns to livraisons table for ESSIVI
-- Date: 2025-12-27

-- Ajouter les colonnes manquantes si elles n'existent pas
ALTER TABLE livraisons ADD COLUMN IF NOT EXISTS client_id INTEGER REFERENCES clients(id) ON DELETE SET NULL;
ALTER TABLE livraisons ADD COLUMN IF NOT EXISTS quantite INTEGER DEFAULT 0;
ALTER TABLE livraisons ADD COLUMN IF NOT EXISTS montant_percu DECIMAL(10,2) DEFAULT 0;
ALTER TABLE livraisons ADD COLUMN IF NOT EXISTS latitude_gps DECIMAL(9,6);
ALTER TABLE livraisons ADD COLUMN IF NOT EXISTS longitude_gps DECIMAL(9,6);
ALTER TABLE livraisons ADD COLUMN IF NOT EXISTS adresse_livraison TEXT;
ALTER TABLE livraisons ADD COLUMN IF NOT EXISTS photo_lieu VARCHAR(255);
ALTER TABLE livraisons ADD COLUMN IF NOT EXISTS signature_client VARCHAR(255);
ALTER TABLE livraisons ADD COLUMN IF NOT EXISTS date_livraison DATE;
ALTER TABLE livraisons ADD COLUMN IF NOT EXISTS heure_livraison TIME;

-- Créer les indexes pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_livraisons_client_id ON livraisons(client_id);
CREATE INDEX IF NOT EXISTS idx_livraisons_date_livraison ON livraisons(date_livraison);
CREATE INDEX IF NOT EXISTS idx_livraisons_statut ON livraisons(statut);

-- Ajouter des indexes sur les tables de stats
CREATE INDEX IF NOT EXISTS idx_commandes_date_livraison_effective ON commandes(date_livraison_effective);
CREATE INDEX IF NOT EXISTS idx_commande_details_produit_id ON commande_details(produit_id);

-- Créer une vue pour les livraisons avec détails
CREATE OR REPLACE VIEW vue_livraisons_detaillees AS
SELECT
    l.id,
    l.commande_id,
    l.agent_id,
    l.client_id,
    l.quantite,
    l.montant_percu,
    l.latitude_gps,
    l.longitude_gps,
    l.adresse_livraison,
    l.date_livraison,
    l.heure_livraison,
    l.statut,
    a.nom as agent_nom,
    a.telephone as agent_telephone,
    a.tricycle,
    c.nom_point_vente,
    c.responsable,
    c.telephone as client_telephone
FROM livraisons l
LEFT JOIN agents a ON l.agent_id = a.id
LEFT JOIN clients c ON l.client_id = c.id;

-- Trigger pour mettre à jour updated_at sur livraisons
DROP TRIGGER IF EXISTS update_livraisons_updated_at ON livraisons;
CREATE TRIGGER update_livraisons_updated_at BEFORE UPDATE ON livraisons 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Fin migration
