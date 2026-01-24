#!/usr/bin/env python3
from db import get_connection
from auth.routes import create_access_token

try:
    conn = get_connection()
    cur = conn.cursor()
    
    email = "agent@essivi.com"
    password = "agent123"
    
    # Vérifier si l'utilisateur existe déjà
    cur.execute("SELECT id FROM users WHERE email = %s", (email,))
    if cur.fetchone():
        print(f"❌ L'utilisateur {email} existe déjà!")
        conn.close()
        exit(1)
    
    # Créer l'utilisateur avec bcrypt
    cur.execute(
        """
        INSERT INTO users (nom, email, password_hash, role)
        VALUES (%s, %s, crypt(%s, gen_salt('bf')), 'agent')
        RETURNING id
        """,
        ("Agent de Livraison", email, password)
    )
    
    user_id = cur.fetchone()["id"]
    
    # Créer l'agent associé
    cur.execute(
        """
        INSERT INTO agents (nom, telephone, email, tricycle, actif, user_id)
        VALUES (%s, %s, %s, %s, true, %s)
        RETURNING id
        """,
        ("Agent de Livraison", "+213671234567", email, "TO-0001-AA", user_id)
    )
    
    agent_id = cur.fetchone()["id"]
    conn.commit()
    
    print(f"✅ Utilisateur créé avec succès!")
    print(f"   User ID: {user_id}")
    print(f"   Agent ID: {agent_id}")
    print(f"   Email: {email}")
    print(f"   Mot de passe: {password}")
    print(f"\nVous pouvez maintenant vous connecter avec ces identifiants.")
    
    conn.close()
    
except Exception as e:
    print(f"❌ Erreur: {str(e)}")
    import traceback
    traceback.print_exc()
