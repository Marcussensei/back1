#!/usr/bin/env python3
"""
Script pour appliquer la migration livraisons à la base de données ESSIVI
"""

import psycopg2
from psycopg2 import sql
import os
from dotenv import load_dotenv

# Charger les variables d'environnement
load_dotenv()

# Configuration de connexion
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME', 'essivi')
DB_USER = os.getenv('DB_USER', 'postgres')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'postgres')

def apply_migration():
    """Appliquer la migration SQL"""
    try:
        # Connexion à la base de données
        print(f"📡 Connexion à PostgreSQL...")
        print(f"   Host: {DB_HOST}")
        print(f"   DB: {DB_NAME}")
        print(f"   User: {DB_USER}")
        
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        
        cursor = conn.cursor()
        print("✅ Connecté à la base de données")
        
        # Lire la migration
        with open('migration_20251227_livraisons.sql', 'r') as f:
            migration_sql = f.read()
        
        # Exécuter la migration
        print("\n🚀 Application des migrations...")
        cursor.execute(migration_sql)
        conn.commit()
        
        print("✅ Migrations appliquées avec succès!")
        
        # Vérifier les colonnes ajoutées
        print("\n📋 Vérification des colonnes de 'livraisons'...")
        cursor.execute("""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'livraisons'
            ORDER BY ordinal_position
        """)
        
        columns = cursor.fetchall()
        print(f"\nColonnes dans la table 'livraisons' ({len(columns)} total):")
        for col_name, col_type in columns:
            print(f"  ✓ {col_name}: {col_type}")
        
        # Vérifier les indexes
        print("\n📇 Vérification des indexes créés...")
        cursor.execute("""
            SELECT indexname FROM pg_indexes 
            WHERE tablename = 'livraisons' OR tablename = 'commandes' OR tablename = 'commande_details'
            ORDER BY indexname
        """)
        
        indexes = cursor.fetchall()
        print(f"\nIndexes créés ({len(indexes)} total):")
        for idx in indexes:
            print(f"  ✓ {idx[0]}")
        
        # Vérifier la vue
        print("\n👁️ Vérification de la vue 'vue_livraisons_detaillees'...")
        cursor.execute("""
            SELECT EXISTS(
                SELECT 1 FROM information_schema.views 
                WHERE table_name = 'vue_livraisons_detaillees'
            )
        """)
        
        if cursor.fetchone()[0]:
            print("  ✓ Vue 'vue_livraisons_detaillees' créée avec succès")
        
        cursor.close()
        conn.close()
        
        print("\n" + "="*50)
        print("🎉 MIGRATION COMPLÉTÉE AVEC SUCCÈS!")
        print("="*50)
        print("\nVous pouvez maintenant utiliser les endpoints:")
        print("  - POST /livraisons/")
        print("  - GET /livraisons/")
        print("  - PUT /livraisons/<id>")
        print("  - etc.")
        
    except psycopg2.OperationalError as e:
        print(f"\n❌ ERREUR DE CONNEXION:")
        print(f"   {str(e)}")
        print("\n💡 Vérifiez:")
        print("   1. PostgreSQL est démarré")
        print("   2. Base 'essivi' existe")
        print("   3. Variables d'env correctes (.env)")
        print(f"\nDébug - Tentative de connexion avec:")
        print(f"   Host: {DB_HOST}")
        print(f"   Port: {DB_PORT}")
        print(f"   Database: {DB_NAME}")
        print(f"   User: {DB_USER}")
        return False
        
    except psycopg2.ProgrammingError as e:
        print(f"\n❌ ERREUR SQL:")
        print(f"   {e}")
        return False
        
    except Exception as e:
        print(f"\n❌ ERREUR:")
        print(f"   {e}")
        return False
    
    return True

if __name__ == '__main__':
    success = apply_migration()
    exit(0 if success else 1)
