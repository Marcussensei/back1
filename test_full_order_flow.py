#!/usr/bin/env python3
"""Test complet du circuit de création de commande"""

import requests
import json
from datetime import datetime, timedelta

BASE_URL = 'http://localhost:5000'

def run_full_test():
    """Test complet"""
    print("=" * 70)
    print("TEST COMPLET: CREATION ET RECUPERATION DE COMMANDE")
    print("=" * 70)
    
    # 1. Login
    print("\n[1] LOGIN CLIENT")
    print("-" * 70)
    login_resp = requests.post(
        f'{BASE_URL}/auth/login',
        json={'email': 'client@example.com', 'password': 'password123'}
    )
    
    if login_resp.status_code != 200:
        print(f"[ERROR] Login failed: {login_resp.status_code}")
        return False
    
    token = login_resp.json()['access_token']
    print(f"[OK] Login successful, token: {token[:30]}...")
    
    # 2. Créer une commande
    print("\n[2] CREATION DE COMMANDE")
    print("-" * 70)
    
    delivery_date = (datetime.now() + timedelta(days=3)).isoformat()
    order_data = {
        'items': [
            {'produit_id': 1, 'quantite': 2, 'prix_unitaire': 10000},
            {'produit_id': 2, 'quantite': 1, 'prix_unitaire': 15000}
        ],
        'delivery_address': '123 Rue de Test, Dakar',
        'date_livraison_prevue': delivery_date,
        'notes': 'Test de commande automatique'
    }
    
    create_resp = requests.post(
        f'{BASE_URL}/commandes/',
        json=order_data,
        headers={'Authorization': token}
    )
    
    if create_resp.status_code not in [200, 201]:
        print(f"[ERROR] Order creation failed: {create_resp.status_code}")
        print(f"Response: {create_resp.json()}")
        return False
    
    created_order = create_resp.json()
    commande_id = created_order['commande_id']
    print(f"[OK] Order created successfully")
    print(f"    - Commande ID: {commande_id}")
    print(f"    - Montant total: {created_order['montant_total']} FCFA")
    print(f"    - Adresse livraison: {created_order.get('adresse_livraison', 'N/A')}")
    
    # 3. Récupérer la liste des commandes
    print("\n[3] RECUPERATION DES COMMANDES")
    print("-" * 70)
    
    list_resp = requests.get(
        f'{BASE_URL}/commandes/',
        headers={'Authorization': token}
    )
    
    if list_resp.status_code != 200:
        print(f"[ERROR] Get orders failed: {list_resp.status_code}")
        return False
    
    orders_list = list_resp.json()['commandes']
    print(f"[OK] Retrieved {len(orders_list)} order(s)")
    
    # Vérifier que notre commande est dans la liste
    found_order = None
    for order in orders_list:
        if order['id'] == commande_id:
            found_order = order
            break
    
    if found_order:
        print(f"\n    Commande trouvee dans la liste:")
        print(f"    - ID: {found_order['id']}")
        print(f"    - Statut: {found_order['statut']}")
        print(f"    - Montant: {found_order['montant_total']} FCFA")
        print(f"    - Adresse livraison: {found_order.get('adresse_livraison', 'N/A')}")
    else:
        print(f"[WARNING] Order {commande_id} not found in list")
    
    # 4. Vérifier les données
    print("\n[4] VERIFICATION DES DONNEES")
    print("-" * 70)
    
    checks = [
        ("Adresse stockee", found_order and found_order.get('adresse_livraison') == '123 Rue de Test, Dakar'),
        ("Montant correct", found_order and found_order['montant_total'] == 35000),
        ("Statut initial", found_order and found_order['statut'] == 'en_attente'),
    ]
    
    all_ok = True
    for check_name, check_result in checks:
        status = "[OK]" if check_result else "[FAIL]"
        print(f"{status} {check_name}")
        if not check_result:
            all_ok = False
    
    print("\n" + "=" * 70)
    if all_ok:
        print("TEST COMPLET: SUCCES!")
    else:
        print("TEST COMPLET: ECHECS!")
    print("=" * 70)
    
    return all_ok

if __name__ == '__main__':
    success = run_full_test()
    exit(0 if success else 1)
