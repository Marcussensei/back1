#!/usr/bin/env python3
"""Script de test pour créer une commande via API"""

import requests
import json
from datetime import datetime, timedelta

# Configuration
BASE_URL = 'http://localhost:5000'

def test_order_creation():
    """Tester la création d'une commande"""
    
    # 1. Se connecter d'abord
    print("1. Tentative de connexion...")
    login_response = requests.post(
        f'{BASE_URL}/auth/login',
        json={
            'email': 'marcusgigoh@gmail.com',
            'password': 'Marco227#'
        }
    )
    
    if login_response.status_code != 200:
        print(f"✗ Erreur de connexion: {login_response.status_code}")
        print(f"Réponse: {login_response.text}")
        return False
    
    data = login_response.json()
    token = data.get('access_token')
    
    if not token:
        print("✗ Pas de token reçu")
        return False
    
    print(f"✓ Connexion réussie, token: {token[:20]}...")
    
    # 2. Créer une commande
    print("\n2. Tentative de création de commande...")
    
    delivery_date = (datetime.now() + timedelta(days=2)).isoformat()
    
    order_data = {
        'items': [
            {
                'produit_id': 1,
                'quantite': 2,
                'prix_unitaire': 10000
            },
            {
                'produit_id': 2,
                'quantite': 1,
                'prix_unitaire': 15000
            }
        ],
        'delivery_address': '123 Rue de Test, Dakar',
        'date_livraison_prevue': delivery_date,
        'notes': 'Livrer à l\'arrière du magasin'
    }
    
    order_response = requests.post(
        f'{BASE_URL}/commandes/',
        json=order_data,
        headers={'Authorization': token}
    )
    
    print(f"Status: {order_response.status_code}")
    response_data = order_response.json()
    print(f"Réponse: {json.dumps(response_data, indent=2)}")
    
    if order_response.status_code in [200, 201]:
        print("✓ Commande créée avec succès!")
        return True
    else:
        print(f"✗ Erreur lors de la création: {order_response.status_code}")
        return False

if __name__ == '__main__':
    success = test_order_creation()
    exit(0 if success else 1)
