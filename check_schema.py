import psycopg2

conn = psycopg2.connect(host='localhost', database='essivivi_db', user='postgres', password='root')
cur = conn.cursor()

# Vérifier structure commandes
cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name='commandes' ORDER BY ordinal_position")