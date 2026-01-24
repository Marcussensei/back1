from db import get_connection

conn = get_connection()
cur = conn.cursor()

# Vérifier les colonnes de la table commandes
cur.execute("""
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name = 'commandes' 
    ORDER BY ordinal_position
""")

columns = cur.fetchall()
print("Colonnes de la table commandes:")
for col in columns:
    print(f"  - {col['column_name']}")

conn.close()
