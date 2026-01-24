# import requests
# import json

# BASE_URL = 'http://127.0.0.1:5000'

# try:
#     # 🔐 Login
#     login_response = requests.post(
#         f'{BASE_URL}/auth/login',
#         json={
#             'email': 'agent@essivi.com',
#             'password': 'agent123'
#         },
#         timeout=10
#     )

#     if login_response.status_code != 200:
#         print(f"❌ Login échoué: {login_response.text}")
#         exit()

#     token = login_response.json().get('access_token')

#     if not token:
#         print("❌ Token non reçu")
#         exit()

#     # 📦 Validation de la livraison
#     headers = {
#         'Content-Type': 'application/json',
#         'Authorization': token  # ⚠️ TRÈS IMPORTANT
#     }

#     response = requests.put(
#         f'{BASE_URL}/livraisons/45',
#         json={'statut': 'terminee'},
#         headers=headers,
#         timeout=10
#     )

#     print(f'Status: {response.status_code}')

#     if response.status_code == 200:
#         print('✅ Livraison ID 46 validée avec succès !')
#         print('Statut changé à: terminee')
#     else:
#         print(f'❌ Erreur: {response.text}')

# except requests.exceptions.Timeout:
#     print("❌ Timeout : le backend ne répond pas")

# except requests.exceptions.ConnectionError:
#     print("❌ Erreur de connexion réseau")

# except Exception as e:
#     print(f"❌ Erreur inattendue: {e}")
import requests
import json

BASE_URL = 'http://127.0.0.1:5000'

# Login
login_response = requests.post(f'{BASE_URL}/auth/login', json={'email': 'agent@essivi.com', 'password': 'agent123'})
token = login_response.json()['access_token']

headers = {'Content-Type': 'application/json', 'Authorization': token}

# Check delivery status
delivery_response = requests.get(f'{BASE_URL}/livraisons/46', headers=headers)
if delivery_response.status_code == 200:
    delivery = delivery_response.json()
    print(f'✅ Livraison ID 46 - Statut: {delivery.get("statut")}')

# Check order status (assuming delivery 46 belongs to order with same ID)
order_response = requests.get(f'{BASE_URL}/commandes/46', headers=headers)
if order_response.status_code == 200:
    order = order_response.json()
    print(f'✅ Commande ID 46 - Statut: {order.get("statut")}')
else:
    print('ℹ️ Impossible de vérifier le statut de la commande (endpoint peut ne pas exister)')
