#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de test de connexion à Supabase PostgreSQL
Vérifie que la base de données est accessible et fonctionnelle
"""

import psycopg2
from psycopg2.extras import RealDictCursor
import os
from dotenv import load_dotenv
from datetime import datetime

# Charger les variables d'environnement
load_dotenv()

def test_connection():
    """Tester la connexion à la base de données"""
    
    print("="*60)
    print("TEST DE CONNEXION SUPABASE POSTGRESQL")
    print("="*60)
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    # Récupérer les informations de connexion
    db_host = os.getenv('DB_HOST')
    db_port = os.getenv('DB_PORT')
    db_user = os.getenv('DB_USER')
    db_password = os.getenv('DB_PASSWORD')
    db_name = os.getenv('DB_NAME')
    db_sslmode = os.getenv('DB_SSLMODE', 'require')
    
    print("📋 Paramètres de connexion:")
    print(f"  Host: {db_host}")
    print(f"  Port: {db_port}")
    print(f"  User: {db_user}")
    print(f"  Database: {db_name}")
    print(f"  SSL Mode: {db_sslmode}")
    print()
    
    try:
        # Établir la connexion
        print("🔗 Connexion en cours...")
        conn = psycopg2.connect(
            host=db_host,
            port=db_port,
            user=db_user,
            password=db_password,
            database=db_name,
            sslmode=db_sslmode,
            cursor_factory=RealDictCursor
        )
        
        print("✅ CONNEXION RÉUSSIE!\n")
        
        # Récupérer les informations du serveur
        cursor = conn.cursor()
        
        # Version PostgreSQL
        cursor.execute("SELECT version();")
        version = cursor.fetchone()['version']
        print(f"📊 PostgreSQL: {version.split(',')[0]}\n")
        
        # Lister les tables
        print("📋 Tables dans la base de données:")
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)
        
        tables = cursor.fetchall()
        if tables:
            for table in tables:
                print(f"  ✓ {table['table_name']}")
            print(f"\n📊 Total: {len(tables)} tables\n")
        else:
            print("  ⚠️  Aucune table trouvée\n")
        
        # Compter les enregistrements
        if tables:
            print("📈 Nombre d'enregistrements par table:")
            for table in tables:
                table_name = table['table_name']
                cursor.execute(f"SELECT COUNT(*) as count FROM {table_name};")
                count = cursor.fetchone()['count']
                print(f"  {table_name}: {count} enregistrements")
            print()
        
        # Tester une requête simple
        print("🧪 Test de requête simple:")
        cursor.execute("SELECT 1 as test;")
        result = cursor.fetchone()
        print(f"  SELECT 1: {result['test']} ✓\n")
        
        # Vérifier les indexes
        cursor.execute("""
            SELECT indexname FROM pg_indexes 
            WHERE schemaname = 'public'
            ORDER BY indexname;
        """)
        
        indexes = cursor.fetchall()
        print(f"📑 Indexes: {len(indexes)} trouvés")
        if len(indexes) > 0:
            print(f"  (Premiers 5: {', '.join([idx['indexname'] for idx in indexes[:5]])}...)")
        print()
        
        # Vérifier les vues
        cursor.execute("""
            SELECT viewname FROM pg_views 
            WHERE schemaname = 'public'
            ORDER BY viewname;
        """)
        
        views = cursor.fetchall()
        print(f"👁️  Vues: {len(views)} trouvées")
        if len(views) > 0:
            print(f"  {', '.join([v['viewname'] for v in views])}")
        print()
        
        cursor.close()
        conn.close()
        
        print("="*60)
        print("✅ TOUS LES TESTS PASSED!")
        print("="*60)
        print("\nℹ️  Votre application peut se connecter à Supabase ✓")
        print("Prochaines étapes:")
        print("  1. Vérifier que vos données sont présentes")
        print("  2. Redémarrer l'application Flask")
        print("  3. Tester les endpoints API")
        print("="*60)
        
        return True
        
    except psycopg2.OperationalError as e:
        print(f"\n❌ ERREUR DE CONNEXION:")
        print(f"  {str(e)}\n")
        
        print("💡 Vérifications à faire:")
        print("  1. ✓ Variables d'environnement correctes dans .env")
        print("  2. ✓ Credentials Supabase valides")
        print("  3. ✓ Firewall/Network: Supabase accepte votre IP")
        print("  4. ✓ SSL mode=require correct")
        print("  5. ✓ Port 5432 accessible")
        print("  6. ✓ Base de données créée dans Supabase")
        
        return False
        
    except Exception as e:
        print(f"\n❌ ERREUR INATTENDUE:")
        print(f"  {type(e).__name__}: {str(e)}\n")
        return False


if __name__ == '__main__':
    success = test_connection()
    exit(0 if success else 1)
