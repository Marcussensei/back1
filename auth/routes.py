from flask_restx import Namespace, Resource, fields
from flask import request, make_response
from flask_jwt_extended import (
    create_access_token,
    jwt_required,
    get_jwt_identity,
    get_jwt
)
from werkzeug.exceptions import HTTPException
from db import get_connection

auth_ns = Namespace(
    "authentication",
    path="/auth",
    description="Authentication endpoints"
)

# ===== Swagger Models =====
register_model = auth_ns.model("Register", {
    "nom": fields.String(required=True, example="Jean Dupont"),
    "email": fields.String(required=True, example="nouveau@test.com"),
    "password": fields.String(required=True, example="1234"),
    "role": fields.String(required=True, example="agent"),
})

create_client_model = auth_ns.model("CreateClient", {
    "nom": fields.String(required=True, example="Marie Martin"),
    "email": fields.String(required=True, example="client@test.com"),
    "password": fields.String(required=True, example="1234"),
    "nom_point_vente": fields.String(required=True, example="Boutique du Coin"),
    "responsable": fields.String(example="Jean Dupont"),
    "telephone": fields.String(example="0123456789"),
    "adresse": fields.String(example="123 Rue de la Paix"),
    "latitude": fields.Float(example=48.8566),
    "longitude": fields.Float(example=2.3522),
})

create_agent_model = auth_ns.model("CreateAgent", {
    "nom": fields.String(required=True, example="Kofi Mensah"),
    "email": fields.String(required=True, example="agent@test.com"),
    "password": fields.String(required=True, example="1234"),
    "telephone": fields.String(required=True, example="0123456789"),
    "tricycle": fields.String(required=True, example="TO-1234-AA"),
})

login_model = auth_ns.model("Login", {
    "email": fields.String(required=True, example="admin@essivi.com"),
    "password": fields.String(required=True, example="admin123"),
})

token_model = auth_ns.model("Token", {
    "access_token": fields.String,
})



# ===== Endpoints =====
@auth_ns.route("/register")
class Register(Resource):
    @auth_ns.expect(register_model)
    def post(self):
        data = request.json
        nom = data.get("nom")
        email = data.get("email")
        password = data.get("password")
        role = data.get("role")

        if not nom or not email or not password or not role:
            auth_ns.abort(400, "Données manquantes")

        conn = get_connection()
        cur = conn.cursor()

        # Vérifier doublon
        cur.execute("SELECT id FROM users WHERE email = %s", (email,))
        if cur.fetchone():
            conn.close()
            auth_ns.abort(409, "Utilisateur déjà existant")

        # Insertion avec pgcrypto (bcrypt SQL)
        cur.execute(
            """
            INSERT INTO users (nom, email, password_hash, role)
            VALUES (%s, %s, crypt(%s, gen_salt('bf')), %s)
            RETURNING id
            """,
            (nom, email, password, role)
        )

        user_id = cur.fetchone()["id"]
        conn.commit()
        conn.close()

        return {
            "message": "Utilisateur créé",
            "user_id": user_id
        }, 201

@auth_ns.route("/create-client")
class CreateClient(Resource):
    @auth_ns.expect(create_client_model)
    def post(self):
        data = request.json
        nom = data.get("nom")
        email = data.get("email")
        password = data.get("password")
        nom_point_vente = data.get("nom_point_vente")
        responsable = data.get("responsable")
        telephone = data.get("telephone")
        adresse = data.get("adresse")
        latitude = data.get("latitude")
        longitude = data.get("longitude")

        if not nom or not email or not password or not nom_point_vente:
            auth_ns.abort(400, "Données manquantes: nom, email, password et nom_point_vente requis")

        conn = get_connection()
        cur = conn.cursor()

        try:
            # Vérifier doublon email
            cur.execute("SELECT id FROM users WHERE email = %s", (email,))
            if cur.fetchone():
                auth_ns.abort(409, "Email déjà utilisé")

            # Créer l'utilisateur client
            cur.execute(
                """
                INSERT INTO users (nom, email, password_hash, role)
                VALUES (%s, %s, crypt(%s, gen_salt('bf')), 'client')
                RETURNING id
                """,
                (nom, email, password)
            )
            user_id = cur.fetchone()["id"]

            # Créer l'entrée client
            cur.execute(
                """
                INSERT INTO clients (nom_point_vente, responsable, telephone, adresse, latitude, longitude, user_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id
                """,
                (nom_point_vente, responsable, telephone, adresse, latitude, longitude, user_id)
            )
            client_id = cur.fetchone()["id"]

            conn.commit()

            return {
                "message": "Client créé avec succès",
                "user_id": user_id,
                "client_id": client_id
            }, 201

        except Exception as e:
            if isinstance(e, HTTPException):
                raise
            conn.rollback()
            auth_ns.abort(500, f"Erreur lors de la création du client: {str(e)}")
        finally:
            conn.close()

@auth_ns.route("/create-agent")
class CreateAgent(Resource):
    @auth_ns.expect(create_agent_model)
    def post(self):
        data = request.json
        nom = data.get("nom")
        email = data.get("email")
        password = data.get("password")
        telephone = data.get("telephone")
        tricycle = data.get("tricycle")

        if not nom or not email or not password or not telephone or not tricycle:
            auth_ns.abort(400, "Données manquantes: nom, email, password, telephone et tricycle requis")

        conn = get_connection()
        cur = conn.cursor()

        try:
            # Vérifier doublon email
            cur.execute("SELECT id FROM users WHERE email = %s", (email,))
            if cur.fetchone():
                auth_ns.abort(409, "Email déjà utilisé")

            # Créer l'utilisateur agent
            cur.execute(
                """
                INSERT INTO users (nom, email, password_hash, role)
                VALUES (%s, %s, crypt(%s, gen_salt('bf')), 'agent')
                RETURNING id
                """,
                (nom, email, password)
            )
            user_id = cur.fetchone()["id"]

            # Créer l'entrée agent
            cur.execute(
                """
                INSERT INTO agents (nom, telephone, email, tricycle, actif, user_id)
                VALUES (%s, %s, %s, %s, true, %s)
                RETURNING id
                """,
                (nom, telephone, email, tricycle, user_id)
            )
            agent_id = cur.fetchone()["id"]

            conn.commit()

            return {
                "message": "Agent créé avec succès",
                "user_id": user_id,
                "agent_id": agent_id
            }, 201

        except Exception as e:
            if isinstance(e, HTTPException):
                raise
            conn.rollback()
            auth_ns.abort(500, f"Erreur lors de la création de l'agent: {str(e)}")
        finally:
            conn.close()

@auth_ns.route("/login")
class Login(Resource):
    @auth_ns.expect(login_model)
    def post(self):
        data = request.json
        email = data.get("email")
        password = data.get("password")

        conn = get_connection()
        cur = conn.cursor()
        cur.execute(
            """
            SELECT id, role
            FROM users
            WHERE email = %s
              AND password_hash = crypt(%s, password_hash)
            """,
            (email, password)
        )
        user = cur.fetchone()

        if not user:
            conn.close()
            auth_ns.abort(401, "Identifiants incorrects")

        # Récupérer le client_id si l'utilisateur est un client
        client_id = None
        if user["role"] == "client":
            cur.execute("SELECT id FROM clients WHERE user_id = %s", (user["id"],))
            client_result = cur.fetchone()
            if client_result:
                client_id = client_result["id"]
        
        # Récupérer l'agent_id si l'utilisateur est un agent
        agent_id = None
        if user["role"] == "agent":
            cur.execute("SELECT id FROM agents WHERE user_id = %s", (user["id"],))
            agent_result = cur.fetchone()
            if agent_result:
                agent_id = agent_result["id"]

        conn.close()

        token = create_access_token(
            identity=str(user["id"]),
            additional_claims={"role": user["role"]}
        )

        # Créer une réponse avec le token en HTTP-only cookie ET dans le JSON
        response_data = {
            "message": "Connecté avec succès",
            "role": user["role"],
            "access_token": token,
            "user_id": user["id"]
        }
        
        # Ajouter client_id ou agent_id si applicable
        if client_id:
            response_data["client_id"] = client_id
        if agent_id:
            response_data["agent_id"] = agent_id

        response = make_response(response_data)
        
        # Définir le cookie HTTP-only (sécurisé)
        # Pour cross-domain (localhost:8080 → render.com), besoin de samesite='None'
        # secure=False en dev, True en production avec HTTPS
        import os
        is_production = os.getenv("RENDER") is not None
        response.set_cookie(
            'access_token_cookie',
            token,
            httponly=True,  # Inaccessible par JavaScript
            secure=is_production,   # False en dev (HTTP), True en prod (HTTPS)
            samesite='None',  # None pour cross-domain, Lax/Strict sinon
            max_age=3600,
            path='/'
        )
        
        return response




@auth_ns.route("/me")
class Me(Resource):
    @auth_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        user_id = int(get_jwt_identity())
        claims = get_jwt()
        user_role = claims.get("role")

        conn = get_connection()
        cur = conn.cursor()

        try:
            if user_role == "agent":
                # Récupérer les infos utilisateur + agent
                cur.execute(
                    """
                    SELECT u.id, u.nom as user_nom, u.email as user_email, u.role, u.created_at,
                           a.id as agent_id, a.nom as agent_nom, a.telephone, a.email as agent_email, a.tricycle, a.actif
                    FROM users u
                    LEFT JOIN agents a ON u.id = a.user_id
                    WHERE u.id = %s
                    """,
                    (user_id,)
                )
                result = cur.fetchone()
                if result:
                    return {
                        "id": result["id"],
                        "agent_id": result["agent_id"],
                        "nom": result["agent_nom"] or result["user_nom"],
                        "email": result["agent_email"] or result["user_email"],
                        "role": result["role"],
                        "created_at": result["created_at"].isoformat() if result["created_at"] else None,
                        "agent_info": {
                            "nom": result["agent_nom"],
                            "telephone": result["telephone"],
                            "email": result["agent_email"],
                            "tricycle": result["tricycle"],
                            "actif": result["actif"]
                        } if result["agent_nom"] else None
                    }

            elif user_role == "client":
                # Récupérer les infos utilisateur + client
                cur.execute(
                    """
                    SELECT u.id, u.nom, u.email, u.role, u.created_at,
                           c.nom_point_vente, c.responsable, c.telephone, c.adresse, c.latitude, c.longitude
                    FROM users u
                    LEFT JOIN clients c ON u.id = c.user_id
                    WHERE u.id = %s
                    """,
                    (user_id,)
                )
                result = cur.fetchone()
                if result:
                    return {
                        "id": result["id"],
                        "nom": result["nom"],
                        "email": result["email"],
                        "role": result["role"],
                        "created_at": result["created_at"].isoformat() if result["created_at"] else None,
                        "client_info": {
                            "nom_point_vente": result["nom_point_vente"],
                            "responsable": result["responsable"],
                            "telephone": result["telephone"],
                            "adresse": result["adresse"],
                            "latitude": float(result["latitude"]) if result["latitude"] is not None else None,
                            "longitude": float(result["longitude"]) if result["longitude"] is not None else None
                        } if result["nom_point_vente"] else None
                    }

            else:
                # Pour admin ou autres rôles
                cur.execute(
                    """
                    SELECT id, nom, email, role, created_at
                    FROM users
                    WHERE id = %s
                    """,
                    (user_id,)
                )
                result = cur.fetchone()
                if result:
                    return {
                        "id": result["id"],
                        "nom": result["nom"],
                        "email": result["email"],
                        "role": result["role"],
                        "created_at": result["created_at"].isoformat() if result["created_at"] else None
                    }

            auth_ns.abort(404, "Utilisateur non trouvé")

        except Exception as e:
            auth_ns.abort(500, f"Erreur serveur: {str(e)}")
        finally:
            conn.close()


@auth_ns.route("/logout")
class Logout(Resource):
    @jwt_required(optional=True)
    def post(self):
        """Déconnecter l'utilisateur en supprimant le cookie"""
        response = make_response({"message": "Déconnecté avec succès"}, 200)
        
        # Supprimer le cookie
        response.set_cookie(
            'access_token_cookie',
            '',
            max_age=0,
            httponly=True,
            secure=False,
            samesite='Lax',
            path='/'
        )
        
        return response
