#!/usr/bin/env python3
"""
Script de migration pour ajouter les champs de localisation aux agents
"""

import psycopg2
from psycopg2.extras import RealDictCursor

def get_connection():
    return psycopg2.connect(
        host="localhost",
        database="essivivi_db",
        user="postgres",
        password="root",
        cursor_factory=RealDictCursor
    )

def apply_migration():
    """Applique la migration pour ajouter les champs de localisation aux agents"""
    try:
        conn = get_connection()
        cur = conn.cursor()

        print("🔍 Vérification de la structure actuelle de la table agents...")

        # Vérifier les colonnes existantes
        cur.execute("""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = 'agents'
            ORDER BY ordinal_position
        """)

        existing_columns = [row['column_name'] for row in cur.fetchall()]
        print(f"Colonnes actuelles: {', '.join(existing_columns)}")

        # Ajouter les nouvelles colonnes si elles n'existent pas
        new_columns = ['latitude', 'longitude', 'last_location_update']

        for column in new_columns:
            if column not in existing_columns:
                print(f"➕ Ajout de la colonne '{column}'...")

                if column in ['latitude', 'longitude']:
                    cur.execute(f"ALTER TABLE agents ADD COLUMN {column} DECIMAL(9,6)")
                elif column == 'last_location_update':
                    cur.execute(f"ALTER TABLE agents ADD COLUMN {column} TIMESTAMP DEFAULT CURRENT_TIMESTAMP")

                print(f"✅ Colonne '{column}' ajoutée avec succès")
            else:
                print(f"ℹ️  Colonne '{column}' existe déjà")

        # Mettre à jour last_location_update pour les agents existants
        print("🔄 Mise à jour des données existantes...")
        cur.execute("""
            UPDATE agents
            SET last_location_update = CURRENT_TIMESTAMP
            WHERE last_location_update IS NULL
        """)

        updated_count = cur.rowcount
        print(f"✅ {updated_count} agents mis à jour avec la date actuelle")

        # Vérifier le résultat final
        cur.execute("""
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns
            WHERE table_name = 'agents'
            ORDER BY ordinal_position
        """)

        print("\n📋 Structure finale de la table agents:")
        for row in cur.fetchall():
            nullable = "NULL" if row['is_nullable'] == 'YES' else "NOT NULL"
            default = f" DEFAULT {row['column_default']}" if row['column_default'] else ""
            print(f"  - {row['column_name']}: {row['data_type']} {nullable}{default}")

        # Compter les agents
        cur.execute("SELECT COUNT(*) as count FROM agents")
        agent_count = cur.fetchone()['count']
        print(f"\n👥 Nombre total d'agents: {agent_count}")

        conn.commit()
        print("\n🎉 Migration terminée avec succès!")

    except Exception as e:
        print(f"❌ Erreur lors de la migration: {e}")
        if 'conn' in locals():
            conn.rollback()
        return False

    finally:
        if 'conn' in locals():
            conn.close()

    return True

if __name__ == "__main__":
    print("🚀 Démarrage de la migration des agents...")
    success = apply_migration()
    if success:
        print("\n✅ La base de données est maintenant prête pour la localisation des agents!")
        print("📍 Les agents peuvent maintenant être localisés sur la carte.")
    else:
        print("\n❌ Échec de la migration. Vérifiez les logs ci-dessus.")