-- ===========================================
-- ESSIVI - Système de Distribution d'Eau Potable
-- SCRIPT COMPLET DE CONFIGURATION DE LA BASE DE DONNÉES
-- Inclut le schéma principal et toutes les migrations
-- Date: 2026-01-23
-- ===========================================

-- ===========================================
-- PARTIE 1: CRÉATION DE LA BASE DE DONNÉES ET EXTENSIONS
-- ===========================================

-- Création de la base de données
CREATE DATABASE essivivi_db;
\c essivivi_db;

-- Activer l'extension pgcrypto pour le hashage des mots de passe
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ===========================================
-- PARTIE 2: TABLES PRINCIPALES
-- ===========================================

-- Table des utilisateurs (comptes)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100),  -- Nom de l'utilisateur
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'agent', 'client')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des agents (livreurs)
CREATE TABLE agents (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    telephone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100),
    tricycle VARCHAR(50),
    actif BOOLEAN DEFAULT TRUE,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    last_location_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id INTEGER UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Table des clients (points de vente)
CREATE TABLE clients (
    id SERIAL PRIMARY KEY,
    nom_point_vente VARCHAR(150) NOT NULL,
    responsable VARCHAR(100),
    telephone VARCHAR(20),
    adresse TEXT,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    user_id INTEGER UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Table des produits/articles
CREATE TABLE produits (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    description TEXT,
    prix_unitaire DECIMAL(10,2) NOT NULL,
    unite VARCHAR(20) DEFAULT 'bouteille', -- bouteille, pack, caisse, etc.
    quantite_par_unite INTEGER DEFAULT 1,
    actif BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des stocks
CREATE TABLE stocks (
    id SERIAL PRIMARY KEY,
    produit_id INTEGER NOT NULL,
    quantite_disponible INTEGER NOT NULL DEFAULT 0,
    seuil_alerte INTEGER DEFAULT 10,
    depot_principal BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (produit_id) REFERENCES produits(id) ON DELETE CASCADE,
    UNIQUE(produit_id, depot_principal)
);

-- Table des commandes
CREATE TABLE commandes (
    id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL,
    agent_id INTEGER,
    date_commande TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_livraison_prevue TIMESTAMP,
    date_livraison_effective TIMESTAMP,
    statut VARCHAR(20) DEFAULT 'en_attente' CHECK (statut IN ('en_attente', 'confirmee', 'en_cours', 'livree', 'annulee')),
    montant_total DECIMAL(10,2) DEFAULT 0,
    notes TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    adresse_livraison VARCHAR(500),
    produits JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE SET NULL
);

-- Table des détails de commande (lignes de commande)
CREATE TABLE commande_details (
    id SERIAL PRIMARY KEY,
    commande_id INTEGER NOT NULL,
    produit_id INTEGER NOT NULL,
    quantite INTEGER NOT NULL,
    prix_unitaire DECIMAL(10,2) NOT NULL,
    montant_ligne DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (commande_id) REFERENCES commandes(id) ON DELETE CASCADE,
    FOREIGN KEY (produit_id) REFERENCES produits(id) ON DELETE CASCADE
);

-- Table des livraisons
CREATE TABLE livraisons (
    id SERIAL PRIMARY KEY,
    commande_id INTEGER NOT NULL,
    agent_id INTEGER,
    client_id INTEGER,
    date_depart TIMESTAMP,
    date_arrivee TIMESTAMP,
    statut VARCHAR(20) DEFAULT 'en_cours' CHECK (statut IN ('en_cours', 'terminee', 'probleme', 'livree')),
    notes TEXT,
    quantite INTEGER DEFAULT 0,
    montant_percu DECIMAL(10,2) DEFAULT 0,
    latitude_gps DECIMAL(9,6),
    longitude_gps DECIMAL(9,6),
    adresse_livraison TEXT,
    photo_lieu VARCHAR(255),
    signature_client VARCHAR(255),
    date_livraison DATE,
    heure_livraison TIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (commande_id) REFERENCES commandes(id) ON DELETE CASCADE,
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL
);

-- Table des paiements
CREATE TABLE paiements (
    id SERIAL PRIMARY KEY,
    commande_id INTEGER NOT NULL,
    montant DECIMAL(10,2) NOT NULL,
    methode_paiement VARCHAR(20) CHECK (methode_paiement IN ('especes', 'mobile_money', 'virement', 'carte')),
    reference_paiement VARCHAR(100),
    date_paiement TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    statut VARCHAR(20) DEFAULT 'en_attente' CHECK (statut IN ('en_attente', 'confirme', 'annule')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (commande_id) REFERENCES commandes(id) ON DELETE CASCADE
);

-- ===========================================
-- PARTIE 3: TABLES DE SUIVI ET HISTORIQUE
-- ===========================================

-- Table des mouvements de stock
CREATE TABLE mouvements_stock (
    id SERIAL PRIMARY KEY,
    produit_id INTEGER NOT NULL,
    type_mouvement VARCHAR(20) NOT NULL CHECK (type_mouvement IN ('entree', 'sortie', 'ajustement')),
    quantite INTEGER NOT NULL,
    motif TEXT,
    utilisateur_id INTEGER,
    date_mouvement TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (produit_id) REFERENCES produits(id) ON DELETE CASCADE,
    FOREIGN KEY (utilisateur_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Table des notifications
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    utilisateur_id INTEGER NOT NULL,
    titre VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type_notification VARCHAR(20) DEFAULT 'info' CHECK (type_notification IN ('info', 'warning', 'error', 'success')),
    lue BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ===========================================
-- PARTIE 4: INDEXES POUR OPTIMISER LES PERFORMANCES
-- ===========================================

-- Indexes sur les tables fréquemment consultées
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_agents_user_id ON agents(user_id);
CREATE INDEX idx_clients_user_id ON clients(user_id);
CREATE INDEX idx_commandes_client_id ON commandes(client_id);
CREATE INDEX idx_commandes_agent_id ON commandes(agent_id);
CREATE INDEX idx_commandes_statut ON commandes(statut);
CREATE INDEX idx_commandes_date_commande ON commandes(date_commande);
CREATE INDEX idx_commandes_date_livraison_effective ON commandes(date_livraison_effective);
CREATE INDEX idx_commande_details_commande_id ON commande_details(commande_id);
CREATE INDEX idx_commande_details_produit_id ON commande_details(produit_id);
CREATE INDEX idx_livraisons_commande_id ON livraisons(commande_id);
CREATE INDEX idx_livraisons_agent_id ON livraisons(agent_id);
CREATE INDEX idx_livraisons_client_id ON livraisons(client_id);
CREATE INDEX idx_livraisons_date_livraison ON livraisons(date_livraison);
CREATE INDEX idx_livraisons_statut ON livraisons(statut);
CREATE INDEX idx_paiements_commande_id ON paiements(commande_id);
CREATE INDEX idx_mouvements_stock_produit_id ON mouvements_stock(produit_id);
CREATE INDEX idx_notifications_utilisateur_id ON notifications(utilisateur_id);
CREATE INDEX idx_commandes_produits ON commandes USING GIN (produits);

-- ===========================================
-- PARTIE 5: FONCTIONS ET TRIGGERS
-- ===========================================

-- Fonction pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers pour updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_agents_updated_at BEFORE UPDATE ON agents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_produits_updated_at BEFORE UPDATE ON produits FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_stocks_updated_at BEFORE UPDATE ON stocks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_commandes_updated_at BEFORE UPDATE ON commandes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_livraisons_updated_at BEFORE UPDATE ON livraisons FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Fonction pour calculer le montant total d'une commande
CREATE OR REPLACE FUNCTION calculate_commande_total()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE commandes
    SET montant_total = (
        SELECT COALESCE(SUM(montant_ligne), 0)
        FROM commande_details
        WHERE commande_id = COALESCE(NEW.commande_id, OLD.commande_id)
    )
    WHERE id = COALESCE(NEW.commande_id, OLD.commande_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

-- Trigger pour recalculer le total lors de modification des détails
CREATE TRIGGER update_commande_total
    AFTER INSERT OR UPDATE OR DELETE ON commande_details
    FOR EACH ROW EXECUTE FUNCTION calculate_commande_total();

-- Fonction pour mettre à jour la colonne produits depuis commande_details
CREATE OR REPLACE FUNCTION update_commandes_produits()
RETURNS VOID AS $$
BEGIN
    -- Mettre à jour la colonne produits pour les commandes existantes
    -- en récupérant les données depuis commande_details
    UPDATE commandes
    SET produits = (
        SELECT jsonb_agg(
            jsonb_build_object(
                'produit_id', cd.produit_id,
                'nom', p.nom,
                'quantite', cd.quantite,
                'prix_unitaire', cd.prix_unitaire,
                'montant_ligne', cd.montant_ligne
            )
        )
        FROM commande_details cd
        LEFT JOIN produits p ON cd.produit_id = p.id
        WHERE cd.commande_id = commandes.id
    )
    WHERE produits IS NULL;
END;
$$ LANGUAGE plpgsql;

-- ===========================================
-- PARTIE 6: VUES UTILES
-- ===========================================

-- Vue des commandes avec détails clients et agents
CREATE OR REPLACE VIEW vue_commandes_detaillees AS
SELECT
    c.id,
    c.date_commande,
    c.date_livraison_prevue,
    c.date_livraison_effective,
    c.statut,
    c.montant_total,
    c.notes,
    cl.nom_point_vente,
    cl.responsable,
    cl.telephone as tel_client,
    cl.adresse,
    a.nom as nom_agent,
    a.telephone as tel_agent,
    a.tricycle
FROM commandes c
LEFT JOIN clients cl ON c.client_id = cl.id
LEFT JOIN agents a ON c.agent_id = a.id;

-- Vue des stocks avec alertes
CREATE OR REPLACE VIEW vue_stocks_alertes AS
SELECT
    s.id,
    p.nom as produit,
    s.quantite_disponible,
    s.seuil_alerte,
    CASE
        WHEN s.quantite_disponible <= s.seuil_alerte THEN 'CRITIQUE'
        WHEN s.quantite_disponible <= s.seuil_alerte * 1.5 THEN 'ATTENTION'
        ELSE 'NORMAL'
    END as statut_stock
FROM stocks s
JOIN produits p ON s.produit_id = p.id
WHERE s.quantite_disponible <= s.seuil_alerte * 2;

-- Vue des livraisons avec détails
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

-- ===========================================
-- PARTIE 7: DONNÉES DE TEST (OPTIONNEL)
-- ===========================================

-- Insertion d'un utilisateur admin
INSERT INTO users (nom, email, password_hash, role) VALUES
('Administrateur', 'admin@essivi.com', crypt('admin123', gen_salt('bf')), 'admin');

-- Insertion de quelques produits
INSERT INTO produits (nom, description, prix_unitaire, unite) VALUES
('Eau 1.5L', 'Bouteille d''eau 1.5 litres', 500.00, 'bouteille'),
('Eau 50CL', 'Bouteille d''eau 50 centilitres', 300.00, 'bouteille'),
('Pack 6x1.5L', 'Pack de 6 bouteilles 1.5L', 2800.00, 'pack');

-- Insertion de stocks initiaux
INSERT INTO stocks (produit_id, quantite_disponible, seuil_alerte) VALUES
(1, 100, 20),
(2, 200, 30),
(3, 50, 10);

-- ===========================================
-- PARTIE 8: PERMISSIONS
-- ===========================================

-- Créer un rôle pour l'application
CREATE ROLE essivi_app WITH LOGIN PASSWORD 'essivi_password';
GRANT CONNECT ON DATABASE essivivi_db TO essivi_app;
GRANT USAGE ON SCHEMA public TO essivi_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO essivi_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO essivi_app;

-- ===========================================
-- PARTIE 9: COMMENTAIRES SUR LES TABLES
-- ===========================================

COMMENT ON TABLE users IS 'Comptes utilisateurs du système';
COMMENT ON TABLE agents IS 'Informations spécifiques aux agents/livreurs';
COMMENT ON TABLE clients IS 'Points de vente clients';
COMMENT ON TABLE produits IS 'Catalogue des produits disponibles';
COMMENT ON TABLE stocks IS 'Gestion des stocks par produit';
COMMENT ON TABLE commandes IS 'Commandes passées par les clients';
COMMENT ON TABLE commande_details IS 'Détails des lignes de commande';
COMMENT ON TABLE livraisons IS 'Suivi des livraisons';
COMMENT ON TABLE paiements IS 'Historique des paiements';
COMMENT ON TABLE mouvements_stock IS 'Historique des mouvements de stock';
COMMENT ON TABLE notifications IS 'Système de notifications utilisateurs';

COMMENT ON COLUMN commandes.latitude IS 'Client GPS latitude at time of order creation';
COMMENT ON COLUMN commandes.longitude IS 'Client GPS longitude at time of order creation';
COMMENT ON COLUMN commandes.adresse_livraison IS 'Adresse de livraison spécifiée par le client';
COMMENT ON COLUMN commandes.produits IS 'Liste des produits de la commande au format JSON (alternative à commande_details)';
COMMENT ON COLUMN livraisons.latitude_gps IS 'GPS latitude du lieu de livraison';
COMMENT ON COLUMN livraisons.longitude_gps IS 'GPS longitude du lieu de livraison';
COMMENT ON COLUMN livraisons.adresse_livraison IS 'Adresse complète de livraison';
COMMENT ON COLUMN livraisons.photo_lieu IS 'Chemin/URL de la photo du lieu de livraison';
COMMENT ON COLUMN livraisons.signature_client IS 'Signature électronique du client';
COMMENT ON COLUMN livraisons.date_livraison IS 'Date effectivement de la livraison';
COMMENT ON COLUMN livraisons.heure_livraison IS 'Heure de la livraison';
COMMENT ON COLUMN livraisons.montant_percu IS 'Montant effectivement perçu lors de la livraison';
COMMENT ON COLUMN agents.latitude IS 'Position GPS actuelle de l''agent';
COMMENT ON COLUMN agents.longitude IS 'Position GPS actuelle de l''agent';
COMMENT ON COLUMN agents.last_location_update IS 'Timestamp de la dernière mise à jour de localisation';

-- ===========================================
-- RÉSUMÉ DES MIGRATIONS APPLIQUÉES
-- ===========================================
-- 1. ✓ migration_add_user_id.sql - Ajout user_id à clients
-- 2. ✓ migration_add_gps_to_commandes.sql - Ajout latitude/longitude à commandes
-- 3. ✓ migration_add_products_to_commandes.sql - Ajout colonne produits (JSONB)
-- 4. ✓ migration_add_adresse_livraison.sql - Ajout adresse_livraison à commandes
-- 5. ✓ migration_agents_location.sql - Ajout localisation aux agents
-- 6. ✓ migrate_agents_location.py - Vérification et ajout champs localisation agents
-- 7. ✓ migration_allow_null_agent_id.sql - agent_id peut être NULL dans livraisons
-- 8. ✓ migration_update_livraisons_statut.sql - Ajout 'livree' au statut
-- 9. ✓ migration_20251227_livraisons.sql - Colonnes complètes pour livraisons
-- ===========================================
-- FIN DU SCRIPT COMPLET
-- ===========================================
