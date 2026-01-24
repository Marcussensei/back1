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
cur.execute('SELECT id, nom_point_vente FROM clients ORDER BY id')
clients = cur.fetchall()
print('Database clients:')
for c in clients:
    print(f'  ID: {c["id"]}  Name: {c["nom_point_vente"]}')

# Now check the API response
import requests
payload = {'email': 'admin@essivi.com', 'password': 'admin123'}
r = requests.post('http://localhost:5000/auth/login', json=payload)
token = r.json().get('access_token')
headers = {'Authorization': token}

print('\nAPI returned clients:')
r_clients = requests.get('http://localhost:5000/clients/', headers=headers)
api_clients = r_clients.json()
for c in api_clients:
    print(f'  ID: {c["id"]}  Name: {c.get("businessName")}')

conn.close()
