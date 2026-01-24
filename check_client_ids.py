import psycopg2
from psycopg2.extras import RealDictCursor
import os
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(
    host=os.getenv('DB_HOST', 'localhost'),
    port=int(os.getenv('DB_PORT', 5432)),
    database=os.getenv('DB_NAME'),
    user=os.getenv('DB_USER'),
    password=os.getenv('DB_PASSWORD')
)

cur = conn.cursor(cursor_factory=RealDictCursor)
cur.execute('SELECT id FROM clients ORDER BY id')
clients = cur.fetchall()
print('Actual client IDs in database:')
for c in clients:
    print(f'  {c["id"]}')
conn.close()
