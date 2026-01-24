-- ===========================================
-- Migration: Ajouter une colonne produits à la table commandes
-- Date: 2025-12-28
-- Description: Ajoute une colonne JSON pour stocker les produits directement dans la table commandes
-- ===========================================

-- Ajouter la colonne produits (JSON) à la table commandes
ALTER TABLE commandes
ADD COLUMN produits JSONB;

-- Ajouter un commentaire à la colonne
COMMENT ON COLUMN commandes.produits IS 'Liste des produits de la commande au format JSON (alternative à commande_details)';

-- ===========================================
-- Exemple d'utilisation de la nouvelle colonne
-- ===========================================

-- La colonne produits peut contenir un tableau JSON comme :
-- [
--   {
--     "produit_id": 1,
--     "nom": "Eau 1.5L",
--     "quantite": 10,
--     "prix_unitaire": 500.00,
--     "montant_ligne": 5000.00
--   },
--   {
--     "produit_id": 2,
--     "nom": "Eau 50CL",
--     "quantite": 20,
--     "prix_unitaire": 300.00,
--     "montant_ligne": 6000.00
--   }
-- ]

-- ===========================================
-- Fonction utilitaire pour mettre à jour la colonne produits
-- ===========================================

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
-- Index pour optimiser les recherches JSON
-- ===========================================

-- Index GIN pour les recherches dans le JSON
CREATE INDEX idx_commandes_produits ON commandes USING GIN (produits);

-- ===========================================
-- Trigger pour maintenir la cohérence des données
-- ===========================================

-- Fonction pour synchroniser commande_details avec la colonne produits
CREATE OR REPLACE FUNCTION sync_commande_details_with_produits()
RETURNS TRIGGER AS $$
BEGIN
    -- Cette fonction peut être utilisée si vous voulez synchroniser
    -- automatiquement commande_details avec la colonne produits
    -- (implémentation selon les besoins)

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- ===========================================
-- Requêtes d'exemple pour utiliser la nouvelle colonne
-- ===========================================

-- Exemples de requêtes utilisant la colonne produits :

-- 1. Compter le nombre total de produits dans une commande
-- SELECT id, jsonb_array_length(produits) as nombre_produits FROM commandes WHERE id = 1;

-- 2. Calculer le montant total depuis la colonne produits
-- SELECT id, SUM((produit->>'montant_ligne')::decimal) as total_calcule
-- FROM commandes, jsonb_array_elements(produits) as produit
-- WHERE id = 1
-- GROUP BY id;

-- 3. Trouver les commandes contenant un produit spécifique
-- SELECT id, nom_point_vente
-- FROM commandes c
-- LEFT JOIN clients cl ON c.client_id = cl.id
-- WHERE produits @> '[{"produit_id": 1}]';

-- ===========================================
-- FIN DE LA MIGRATION
-- ===========================================

-- Note: Cette migration ajoute une colonne JSONB pour stocker les produits
-- directement dans la table commandes. Cela peut être utile pour :
-- - Des requêtes plus rapides sur les produits d'une commande
-- - Une alternative à la table commande_details
-- - De la dénormalisation pour des besoins spécifiques
--
-- Cependant, la structure normaleisée avec commande_details reste
-- la solution recommandée pour la plupart des cas d'usage.
