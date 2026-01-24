#!/usr/bin/env python3
"""
Script pour créer un produit avec stock
"""
import psycopg2
from psycopg2.extras import RealDictCursor

# Configuration de la base de données
DB_CONFIG = {
    'dbname': 'essivivi_db',
    'user': 'postgres',
    'password': 'root',
    'host': 'localhost',
    'port': 5432
}

def create_product_with_stock():
    """Créer un produit avec stock de 30 et seuil d'alerte de 5"""
    try:
        # Connexion à la base de données
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # Créer le produit
        cur.execute("""
            INSERT INTO produits (nom, description, prix_unitaire, unite, quantite_par_unite, actif)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id, nom, prix_unitaire, unite
        """, (
            'Eau Minérale 1.5L Premium',
            'Eau minérale naturelle en bouteille de 1.5 litres, qualité premium',
            600.00,
            'bouteille',
            1,
            True
        ))
        
        produit = cur.fetchone()
        produit_id = produit['id']
        
        print(f"✅ Produit créé:")
        print(f"   ID: {produit['id']}")
        print(f"   Nom: {produit['nom']}")
        print(f"   Prix: {produit['prix_unitaire']} FCFA")
        print(f"   Unité: {produit['unite']}")
        
        # Créer le stock associé
        cur.execute("""
            INSERT INTO stocks (produit_id, quantite_disponible, seuil_alerte, depot_principal)
            VALUES (%s, %s, %s, %s)
            RETURNING id, quantite_disponible, seuil_alerte
        """, (
            produit_id,
            30,  # Stock initial
            5,   # Seuil d'alerte
            True
        ))
        
        stock = cur.fetchone()
        
        print(f"\n✅ Stock créé:")
        print(f"   ID: {stock['id']}")
        print(f"   Quantité disponible: {stock['quantite_disponible']}")
        print(f"   Seuil d'alerte: {stock['seuil_alerte']}")
        
        # Valider la transaction
        conn.commit()
        
        print(f"\n🎉 Produit et stock créés avec succès!")
        print(f"\n📊 Résumé:")
        print(f"   - Produit ID: {produit_id}")
        print(f"   - Stock: {stock['quantite_disponible']} unités")
        print(f"   - Alerte si stock ≤ {stock['seuil_alerte']} unités")
        
        # Vérifier le produit créé
        cur.execute("""
            SELECT 
                p.id,
                p.nom,
                p.description,
                p.prix_unitaire,
                p.unite,
                s.quantite_disponible,
                s.seuil_alerte,
                CASE
                    WHEN s.quantite_disponible <= s.seuil_alerte THEN 'CRITIQUE'
                    WHEN s.quantite_disponible <= s.seuil_alerte * 1.5 THEN 'ATTENTION'
                    ELSE 'NORMAL'
                END as statut_stock
            FROM produits p
            LEFT JOIN stocks s ON p.id = s.produit_id
            WHERE p.id = %s
        """, (produit_id,))
        
        verification = cur.fetchone()
        
        print(f"\n✅ Vérification:")
        print(f"   Statut stock: {verification['statut_stock']}")
        
        cur.close()
        conn.close()
        
        return produit_id
        
    except psycopg2.Error as e:
        print(f"❌ Erreur PostgreSQL: {e}")
        if conn:
            conn.rollback()
        return None
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return None

if __name__ == "__main__":
    print("🚀 Création d'un produit avec stock...\n")
    create_product_with_stock()
