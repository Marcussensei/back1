#!/usr/bin/env python3
"""Vérifier le schéma de la base de données ESSIVI"""

import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_NAME = os.getenv('DB_NAME', 'essivivi_db')
DB_USER = os.getenv('DB_USER', 'postgres')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'root')

conn = psycopg2.connect(host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASSWORD)
cur = conn.cursor()

tables = ['agents', 'clients', 'commandes', 'livraisons', 'produits', 'stocks']

print("=" * 70)
print("SCHEMA DE LA BASE DE DONNEES ESSIVI")
print("=" * 70)

for table in tables:
    print(f"\n{table.upper()}:")
    print("-" * 70)
    
    cur.execute("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_name = %s 
        ORDER BY ordinal_position
    """, (table,))
    
    cols = cur.fetchall()
    if cols:
        for col_name, col_type, nullable in cols:
            null_str = "NULL" if nullable == 'YES' else "NOT NULL"
            print(f"  {col_name:25} {col_type:20} {null_str}")
    else:
        print(f"  [Table non trouvée]")

conn.close()
print("\n" + "=" * 70)
