#!/usr/bin/env python3
"""Script de test pour récupérer une commande"""

import requests
import json

BASE_URL = 'http://localhost:5000'

def test_get_order():
    """Tester la récupération d'une commande"""
    
    # 1. Se connecter
    print("1. Connexion...")
    login_response = requests.post(
        f'{BASE_URL}/auth/login',
        json={
            'email': 'client@example.com',
            'password': 'password123'
        }
    )
    
    token = login_response.json()['access_token']
    print("[OK] Connexion reussie")
    
    # 2. Récupérer les commandes
    print("\n2. Recuperation des commandes...")
    orders_response = requests.get(
        f'{BASE_URL}/commandes/',
        headers={'Authorization': token}
    )
    
    if orders_response.status_code == 200:
        data = orders_response.json()
        commandes = data.get('commandes', [])
        print(f"[OK] {len(commandes)} commande(s) trouvee(s)")
        
        if commandes:
            # Récupérer la dernière commande
            commande = commandes[0]
            print(f"\nCommande ID: {commande['id']}")
            print(f"Adresse de livraison: {commande.get('adresse_livraison', 'N/A')}")
            
            # 3. Récupérer les détails de la commande
            print(f"\n3. Recuperation des details de la commande {commande['id']}...")
            detail_response = requests.get(
                f'{BASE_URL}/commandes/{commande["id"]}',
                headers={'Authorization': token}
            )
            
            if detail_response.status_code == 200:
                detail_data = detail_response.json()
                print(f"[OK] Details recus")
                print(json.dumps(detail_data, indent=2))
            else:
                print(f"[ERROR] {detail_response.status_code}")
    else:
        print(f"[ERROR] {orders_response.status_code}")

if __name__ == '__main__':
    test_get_order()
