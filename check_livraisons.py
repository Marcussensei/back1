#!/usr/bin/env python3
from db import get_connection

conn = get_connection()
cur = conn.cursor()

# Afficher les colonnes de livraisons
cur.execute("""
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_name = 'livraisons'
    ORDER BY ordinal_position
""")

print("=== STRUCTURE DE LA TABLE 'livraisons' ===\n")
columns = cur.fetchall()
for col in columns:
    print(f"{col['column_name']}: {col['data_type']}")

# Afficher quelques livraisons
print("\n\n=== EXEMPLE DE LIVRAISONS ===\n")
cur.execute("SELECT * FROM livraisons LIMIT 3")
livraisons = cur.fetchall()
for liv in livraisons:
    print(f"ID: {liv['id']}, Statut: {liv['statut']}, Montant: {liv['montant_percu']}, Date: {liv['date_livraison']}")

conn.close()
