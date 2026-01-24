#!/usr/bin/env python3
"""Script pour appliquer la migration adresse_livraison"""

from db import get_connection

def apply_migration():
    """Appliquer la migration"""
    conn = get_connection()
    cur = conn.cursor()
    
    try:
        # Vérifier si la colonne existe déjà
        cur.execute("""
            SELECT column_name FROM information_schema.columns 
            WHERE table_name='commandes' AND column_name='adresse_livraison'
        """)
        
        if cur.fetchone():
            print("✓ La colonne 'adresse_livraison' existe déjà")
            return True
        
        # Ajouter la colonne
        cur.execute("""
            ALTER TABLE commandes
            ADD COLUMN adresse_livraison VARCHAR(500)
        """)
        
        conn.commit()
        print("✓ Migration appliquée avec succès: colonne 'adresse_livraison' ajoutée")
        return True
        
    except Exception as e:
        conn.rollback()
        print(f"✗ Erreur lors de la migration: {e}")
        return False
    finally:
        conn.close()

if __name__ == '__main__':
    success = apply_migration()
    exit(0 if success else 1)
