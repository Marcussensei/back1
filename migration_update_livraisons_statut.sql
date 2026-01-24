-- Migration: Update livraisons statut check constraint to include 'livree'
-- Date: 2025-01-22

-- Drop the existing check constraint
ALTER TABLE livraisons DROP CONSTRAINT IF EXISTS livraisons_statut_check;

-- Add the new check constraint with 'livree' included
ALTER TABLE livraisons ADD CONSTRAINT livraisons_statut_check
CHECK (statut IN ('en_cours', 'terminee', 'probleme', 'livree'));

-- Fin migration
