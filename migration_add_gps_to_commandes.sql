-- Migration: Add latitude and longitude to commandes table
-- Purpose: Store the client's GPS position when placing an order

ALTER TABLE commandes 
ADD COLUMN latitude DECIMAL(10, 8),
ADD COLUMN longitude DECIMAL(11, 8);

-- Add comment for documentation
COMMENT ON COLUMN commandes.latitude IS 'Client GPS latitude at time of order creation';
COMMENT ON COLUMN commandes.longitude IS 'Client GPS longitude at time of order creation';
