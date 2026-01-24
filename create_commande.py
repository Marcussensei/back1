import psycopg2
from psycopg2.extras import RealDictCursor
import requests
import json
from datetime import datetime, timedelta

DB_CONFIG = {
     'dbname': 'essivivi_db',
     'user': 'postgres',
     'password': 'root',
     'host': 'localhost',
     'port': 5432
}

BASE_URL = "http://localhost:5000"

def login_client(email, password):
    """Authenticate client and return JWT token"""
    login_data = {
        "email": email,
        "password": password
    }

    print("🔐 Connexion du client...")
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)

    if response.status_code == 200:
        data = response.json()
        token = data.get("access_token")
        print("✅ Connexion réussie")
        return token
    else:
        print(f"❌ Échec de connexion: {response.status_code}")
        print(response.text)
        return None

def create_order(token, client_id, items):
    """Create an order via API"""
    headers = {
        "Authorization": token,
        "Content-Type": "application/json"
    }

    # Set delivery date to tomorrow
    tomorrow = datetime.now() + timedelta(days=1)
    date_livraison = tomorrow.strftime("%Y-%m-%dT14:00:00")

    order_data = {
        "client_id": client_id,
        "date_livraison_prevue": date_livraison,
        "notes": "Commande test créée automatiquement",
        "items": items
    }

    print("🛒 Création de la commande...")
    print(f"Données: {json.dumps(order_data, indent=2, ensure_ascii=False)}")

    response = requests.post(f"{BASE_URL}/commandes", json=order_data, headers=headers)

    if response.status_code == 201:
        result = response.json()
        print("✅ Commande créée avec succès!")
        print(f"ID commande: {result['commande_id']}")
        print(f"Montant total: {result['montant_total']} FCFA")
        print(f"Date création: {result['created_at']}")
        return result
    else:
        print(f"❌ Erreur création commande: {response.status_code}")
        print(response.text)
        return None

def get_client_orders(token, client_id):
    """Retrieve orders for a specific client"""
    headers = {
        "Authorization": token,
        "Content-Type": "application/json"
    }

    params = {
        "client_id": client_id,
        "page": 1,
        "per_page": 20
    }

    print(f"📋 Récupération des commandes du client {client_id}...")
    response = requests.get(f"{BASE_URL}/commandes", headers=headers, params=params)

    if response.status_code == 200:
        orders_data = response.json()
        orders = orders_data.get("commandes", [])
        print(f"✅ {len(orders)} commande(s) trouvée(s) pour ce client")
        if orders:
            print("📋 Liste des commandes:")
            for order in orders:
                print(f"  - ID {order['id']}: {order['montant_total']} FCFA - {order['statut']} - {order['date_commande']}")
        return orders
    else:
        print(f"❌ Erreur récupération commandes: {response.status_code}")
        print(response.text)
        return None

conn = psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)
cur = conn.cursor()
 # Vérifier si le client existe
cur.execute('SELECT u.id as user_id, u.email, c.id as client_id, c.nom_point_vente FROM users u JOIN clients c ON u.id = c.user_id WHERE u.email = %s', ('marcusgigoh@gmail.com',))
client = cur.fetchone()

if client:
    print(f'✅ Client trouvé: {client}')
else:
     print('❌ Client non trouvé')
     cur.close()
     conn.close()
     exit(1)

 # Vérifier les produits disponibles
cur.execute('SELECT id, nom, prix_unitaire FROM produits WHERE actif = true LIMIT 5')
produits = cur.fetchall()
print(f'📦 Produits disponibles: {len(produits)}')
for p in produits:
    print(f'  - ID {p["id"]}: {p["nom"]} - {p["prix_unitaire"]} FCFA')

cur.close()
conn.close()

# Authentifier le client
token = login_client('marcusgigoh@gmail.com', 'Marco227#')
if not token:
    print("❌ Impossible de continuer sans authentification")
    exit(1)

# Créer une commande exemple
sample_items = [
    {
        "produit_id": 1,  # Eau 1.5L
        "quantite": 10,
        "prix_unitaire": 500.00
    },
    {
        "produit_id": 2,  # Eau 50CL
        "quantite": 5,
        "prix_unitaire": 300.00
    }
]

order_result = create_order(token, client['client_id'], sample_items)
if order_result:
    # Récupérer la liste des commandes du client
    get_client_orders(token, client['client_id'])
    print("🎉 Processus terminé avec succès!")
else:
    print("❌ Échec de création de la commande")
