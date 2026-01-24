-- Migration: Allow NULL agent_id in livraisons table
-- This allows creating deliveries without an assigned agent initially
-- The agent will be assigned later via the assignment endpoint

ALTER TABLE livraisons ALTER COLUMN agent_id DROP NOT NULL;
