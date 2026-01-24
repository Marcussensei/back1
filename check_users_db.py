#!/usr/bin/env python3
from db import get_connection

try:
    conn = get_connection()
    cur = conn.cursor()
    
    print("=== UTILISATEURS DANS LA BASE DE DONNEES ===\n")
    
    # Afficher tous les utilisateurs
    cur.execute("SELECT id, nom, email, role FROM users LIMIT 10")
    users = cur.fetchall()
    
    if users:
        for user in users:
            print(f"ID: {user['id']}, Nom: {user['nom']}, Email: {user['email']}, Role: {user['role']}")
    else:
        print("Aucun utilisateur trouvé!")
    
    # Vérifier les agents
    print("\n=== AGENTS ===")
    cur.execute("SELECT id, nom, telephone, email, actif FROM agents LIMIT 5")
    agents = cur.fetchall()
    
    if agents:
        for agent in agents:
            print(f"ID: {agent['id']}, Nom: {agent['nom']}, Email: {agent['email']}, Téléphone: {agent['telephone']}, Actif: {agent['actif']}")
    else:
        print("Aucun agent trouvé!")
    
    conn.close()
    print("\n✅ Vérification complétée!")
    
except Exception as e:
    print(f"❌ Erreur: {str(e)}")
    import traceback
    traceback.print_exc()
