#!/usr/bin/env python3
"""Vérifier les utilisateurs et clients"""

from db import get_connection

def check_users_and_clients():
    """Vérifier les utilisateurs clients"""
    conn = get_connection()
    cur = conn.cursor()
    
    try:
        # Vérifier les users clients
        cur.execute("SELECT id, email, role FROM users WHERE role = 'client' LIMIT 3")
        rows = cur.fetchall()
        print("USERS (clients):")
        for row in rows:
            print(f"  ID: {row[0]}, Email: {row[1]}, Role: {row[2]}")
        
        # Vérifier les clients
        cur.execute("SELECT id, nom_point_vente, user_id, adresse FROM clients LIMIT 3")
        rows = cur.fetchall()
        print("\nCLIENTS:")
        for row in rows:
            print(f"  ID: {row[0]}, Point Vente: {row[1]}, User ID: {row[2]}, Adresse: {row[3]}")
            
    except Exception as e:
        print(f"Erreur: {e}")
    finally:
        conn.close()

if __name__ == '__main__':
    check_users_and_clients()
