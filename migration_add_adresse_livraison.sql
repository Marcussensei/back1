-- Migration: Add adresse_livraison column to commandes table
-- Date: 2026-01-15

-- Check if column exists and add it if not
ALTER TABLE commandes
ADD COLUMN IF NOT EXISTS adresse_livraison VARCHAR(500);
