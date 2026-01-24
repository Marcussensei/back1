#!/usr/bin/env python3
from db import get_connection

conn = get_connection()
cur = conn.cursor()

# Lister toutes les tables
cur.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public'
    ORDER BY table_name
""")

print("=== TABLES DISPONIBLES ===\n")
tables = cur.fetchall()
for table in tables:
    print(f"- {table['table_name']}")

conn.close()
