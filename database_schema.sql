-- ===========================================
-- ESSIVI - Système de Distribution d'Eau Potable
-- Script de création de la base de données
-- ===========================================

-- Création de la base de données
CREATE DATABASE essivivi_db;
\c essivivi_db;

-- Activer l'extension pgcrypto pour le hashage des mots de passe
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ===========================================
-- TABLES PRINCIPALES
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
    agent_id INTEGER NOT NULL,
    date_depart TIMESTAMP,
    date_arrivee TIMESTAMP,
    statut VARCHAR(20) DEFAULT 'en_cours' CHECK (statut IN ('en_cours', 'terminee', 'probleme')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (commande_id) REFERENCES commandes(id) ON DELETE CASCADE,
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE
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
-- TABLES DE SUIVI ET HISTORIQUE
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
-- INDEXES POUR OPTIMISER LES PERFORMANCES
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
CREATE INDEX idx_commande_details_commande_id ON commande_details(commande_id);
CREATE INDEX idx_livraisons_commande_id ON livraisons(commande_id);
CREATE INDEX idx_livraisons_agent_id ON livraisons(agent_id);
CREATE INDEX idx_paiements_commande_id ON paiements(commande_id);
CREATE INDEX idx_mouvements_stock_produit_id ON mouvements_stock(produit_id);
CREATE INDEX idx_notifications_utilisateur_id ON notifications(utilisateur_id);

-- ===========================================
-- TRIGGERS POUR METTRE À JOUR LES TIMESTAMPS
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

-- ===========================================
-- TRIGGERS POUR CALCULER LES MONTANTS
-- ===========================================

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

-- ===========================================
-- DONNÉES DE TEST (OPTIONNEL)
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
-- VUES UTILES (OPTIONNEL)
-- ===========================================

-- Vue des commandes avec détails clients et agents
CREATE VIEW vue_commandes_detaillees AS
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
CREATE VIEW vue_stocks_alertes AS
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

-- ===========================================
-- PERMISSIONS (À AJUSTER SELON LES BESOINS)
-- ===========================================

-- Créer un rôle pour l'application
CREATE ROLE essivi_app WITH LOGIN PASSWORD 'essivi_password';
GRANT CONNECT ON DATABASE essivi_db TO essivi_app;
GRANT USAGE ON SCHEMA public TO essivi_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO essivi_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO essivi_app;

-- ===========================================
-- COMMENTAIRES SUR LES TABLES
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

-- ===========================================
-- FIN DU SCRIPT
-- ===========================================