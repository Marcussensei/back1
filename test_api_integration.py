#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test d'integration complet pour tous les endpoints API
"""

import requests
import json
import time
from datetime import datetime, timedelta
from id_utils import extract_id

BASE_URL = "http://localhost:5000"
HEADERS = {
    "Content-Type": "application/json"
}

class TestAPIIntegration:
    def __init__(self):
        self.token = None
        self.agent_id = None
        self.client_id = None
        self.commande_id = None
        self.livraison_id = None
        self.produit_id = None
        
    def print_result(self, name, success, message=""):
        status = "[OK]" if success else "[FAIL]"
        print(f"{status} - {name}")
        if message:
            print(f"    {message}")
    
    # =========================
    # 1. AUTHENTIFICATION
    # =========================
    
    def test_login(self):
        """Test login et obtenir le token JWT"""
        print("\n[AUTH]")
        
        payload = {
            "email": "admin@essivi.com",
            "password": "admin123"
        }
        
        try:
            response = requests.post(f"{BASE_URL}/auth/login", json=payload, headers=HEADERS)
            if response.status_code == 200:
                data = response.json()
                self.token = data.get("access_token")
                HEADERS["Authorization"] = f"{self.token}"
                self.print_result("Login", True, f"Token: {self.token[:20]}...")
                return True
            else:
                self.print_result("Login", False, f"Status {response.status_code}")
                return False
        except Exception as e:
            self.print_result("Login", False, str(e))
            return False
    
    # =========================
    # 2. AGENTS
    # =========================
    
    def test_get_agents(self):
        """Recuperer la liste des agents"""
        print("\n[AGENTS]")
        
        try:
            response = requests.get(f"{BASE_URL}/agents/", headers=HEADERS)
            if response.status_code == 200:
                data = response.json()
                agents = data if isinstance(data, list) else data.get("data", [])
                if agents:
                    # Use a hardcoded ID that we know exists in the database
                    self.agent_id = 1
                    self.print_result("GET /agents/", True, f"{len(agents)} agents")
                    return True
                else:
                    self.print_result("GET /agents/", False, "Aucun agent")
                    return False
            else:
                self.print_result("GET /agents/", False, f"Status {response.status_code}")
                return False
        except Exception as e:
            self.print_result("GET /agents/", False, str(e))
            return False
    
    # =========================
    # 3. CLIENTS
    # =========================
    
    def test_get_clients(self):
        """Recuperer la liste des clients"""
        print("\n[CLIENTS]")
        
        try:
            response = requests.get(f"{BASE_URL}/clients/", headers=HEADERS)
            if response.status_code == 200:
                data = response.json()
                clients = data if isinstance(data, list) else data.get("data", [])
                if clients:
                    # Use a hardcoded ID that we know exists in the database
                    self.client_id = 1
                    self.print_result("GET /clients/", True, f"{len(clients)} clients")
                    return True
                else:
                    self.print_result("GET /clients/", False, "Aucun client")
                    return False
            else:
                self.print_result("GET /clients/", False, f"Status {response.status_code}")
                return False
        except Exception as e:
            self.print_result("GET /clients/", False, str(e))
            return False
    
    # =========================
    # 4. COMMANDES
    # =========================
    
    def test_get_commandes(self):
        """Recuperer la liste des commandes"""
        print("\n[COMMANDES]")
        
        try:
            response = requests.get(f"{BASE_URL}/commandes/", headers=HEADERS)
            if response.status_code == 200:
                data = response.json()
                commandes = data.get("commandes", [])
                # Can be empty
                self.print_result("GET /commandes/", True, f"{len(commandes)} commandes")
                if commandes and len(commandes) > 0:
                    self.commande_id = commandes[0].get("id")
                return True
            else:
                self.print_result("GET /commandes/", False, f"Status {response.status_code}")
                return False
        except Exception as e:
            self.print_result("GET /commandes/", False, str(e))
            return False
    
    def test_create_commande(self):
        """Creer une nouvelle commande"""
        if not self.client_id:
            self.print_result("POST /commandes/", False, "client_id manquant")
            return False
        
        date_livraison = (datetime.now() + timedelta(days=1)).isoformat()
        
        payload = {
            "client_id": self.client_id,
            "date_livraison_prevue": date_livraison,
            "notes": "Test API"
        }
        
        try:
            response = requests.post(f"{BASE_URL}/commandes/", json=payload, headers=HEADERS)
            if response.status_code in [200, 201]:
                data = response.json()
                self.commande_id = data.get("commande_id")
                self.print_result("POST /commandes/", True, f"ID: {self.commande_id}")
                return True
            else:
                self.print_result("POST /commandes/", False, f"Status {response.status_code}")
                return False
        except Exception as e:
            self.print_result("POST /commandes/", False, str(e))
            return False
    
    # =========================
    # 5. LIVRAISONS
    # =========================
    
    def test_get_livraisons(self):
        """Recuperer la liste des livraisons"""
        print("\n[LIVRAISONS]")
        
        try:
            response = requests.get(f"{BASE_URL}/livraisons/", headers=HEADERS)
            if response.status_code == 200:
                data = response.json()
                livraisons = data.get("data", [])
                # Can be empty
                self.print_result("GET /livraisons/", True, f"{len(livraisons)} livraisons")
                if livraisons and len(livraisons) > 0:
                    self.livraison_id = livraisons[0].get("id")
                return True
            else:
                self.print_result("GET /livraisons/", False, f"Status {response.status_code}")
                return False
        except Exception as e:
            self.print_result("GET /livraisons/", False, str(e))
            return False
    
    def test_create_livraison(self):
        """Creer une nouvelle livraison"""
        if not self.client_id or not self.commande_id:
            self.print_result("POST /livraisons/", False, "IDs manquants")
            return False
        
        payload = {
            "commande_id": self.commande_id,
            "client_id": self.client_id,
            "agent_id": self.agent_id or 1,
            "quantite": 10,
            "montant_percu": 5000.00,
            "latitude_gps": 48.8566,
            "longitude_gps": 2.3522,
            "adresse_livraison": "123 Rue Test"
        }
        
        try:
            response = requests.post(f"{BASE_URL}/livraisons/", json=payload, headers=HEADERS)
            if response.status_code in [200, 201]:
                data = response.json()
                self.livraison_id = data.get("id") or data.get("livraison_id")
                self.print_result("POST /livraisons/", True, f"ID: {self.livraison_id}")
                return True
            else:
                self.print_result("POST /livraisons/", False, f"Status {response.status_code}")
                return False
        except Exception as e:
            self.print_result("POST /livraisons/", False, str(e))
            return False
    
    # =========================
    # 6. PRODUITS & STOCKS
    # =========================
    
    def test_get_produits(self):
        """Recuperer la liste des produits"""
        print("\n[PRODUITS]")
        
        try:
            response = requests.get(f"{BASE_URL}/produits/", headers=HEADERS)
            if response.status_code == 200:
                data = response.json()
                produits = data.get("data", [])
                if produits:
                    self.produit_id = produits[0].get("id")
                    self.print_result("GET /produits/", True, f"{len(produits)} produits")
                    return True
                else:
                    self.print_result("GET /produits/", False, "Aucun produit")
                    return True
            else:
                self.print_result("GET /produits/", False, f"Status {response.status_code}")
                return False
        except Exception as e:
            self.print_result("GET /produits/", False, str(e))
            return False
    
    # =========================
    # 7. STATISTIQUES
    # =========================
    
    def test_statistics(self):
        """Tester tous les endpoints de statistiques"""
        print("\n[STATISTIQUES]")
        
        endpoints = [
            ("GET /statistiques/dashboard/kpi", f"{BASE_URL}/statistiques/dashboard/kpi"),
            ("GET /statistiques/performance/agents", f"{BASE_URL}/statistiques/performance/agents"),
        ]
        
        for name, url in endpoints:
            try:
                response = requests.get(url, headers=HEADERS)
                success = response.status_code == 200
                self.print_result(name, success, f"Status {response.status_code}")
            except Exception as e:
                self.print_result(name, False, str(e))
    
    # =========================
    # 8. CARTOGRAPHIE
    # =========================
    
    def test_cartography(self):
        """Tester tous les endpoints de cartographie"""
        print("\n[CARTOGRAPHIE]")
        
        endpoints = [
            ("GET /cartographie/agents/temps-reel", f"{BASE_URL}/cartographie/agents/temps-reel"),
            ("GET /cartographie/clients/geo", f"{BASE_URL}/cartographie/clients/geo"),
        ]
        
        for name, url in endpoints:
            try:
                response = requests.get(url, headers=HEADERS)
                success = response.status_code == 200
                self.print_result(name, success, f"Status {response.status_code}")
            except Exception as e:
                self.print_result(name, False, str(e))
    
    # =========================
    # EXECUTION
    # =========================
    
    def run_all_tests(self):
        """Executer tous les tests"""
        print("="*60)
        print("TEST D'INTEGRATION - API ESSIVI")
        print("="*60)
        print(f"Base URL: {BASE_URL}")
        
        if not self.test_login():
            print("\nErreur de connexion. Arret.")
            return
        
        self.test_get_agents()
        self.test_get_clients()
        # Create commande needs client_id from get_clients
        self.test_create_commande()
        self.test_get_commandes()
        # Create livraison needs commande_id and client_id
        self.test_get_livraisons()
        self.test_create_livraison()
        self.test_get_produits()
        self.test_statistics()
        self.test_cartography()
        
        print("\n" + "="*60)
        print("Tests termines")
        print("="*60)


if __name__ == "__main__":
    tester = TestAPIIntegration()
    tester.run_all_tests()
