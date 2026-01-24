#!/usr/bin/env python3
"""Créer un client test"""

from db import get_connection
from datetime import datetime

def create_test_client():
    """Créer un client de test"""
    conn = get_connection()
    cur = conn.cursor()
    
    try:
        # D'abord, créer un user avec crypt
        cur.execute("""
            INSERT INTO users (nom, email, password_hash, role, created_at)
            VALUES (%s, %s, crypt(%s, gen_salt('bf')), %s, %s)
            RETURNING id
        """, ('Client Test', 'client@example.com', 'password123', 'client', datetime.now()))
        
        user = cur.fetchone()
        user_id = user['id']
        print(f"✓ User créé avec ID: {user_id}")
        
        # Ensuite, créer le client associé
        cur.execute("""
            INSERT INTO clients (nom_point_vente, responsable, telephone, adresse, user_id, created_at)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            'Épicerie Test',
            'Ahmed Test',
            '+221776123456',
            '123 Rue de Test, Dakar',
            user_id,
            datetime.now()
        ))
        
        client = cur.fetchone()
        client_id = client['id']
        print(f"✓ Client créé avec ID: {client_id}")
        
        conn.commit()
        print(f"✓ Test client créé avec succès!")
        return client_id
        
    except Exception as e:
        conn.rollback()
        print(f"✗ Erreur: {e}")
        import traceback
        traceback.print_exc()
        return None
    finally:
        conn.close()

if __name__ == '__main__':
    create_test_client()
