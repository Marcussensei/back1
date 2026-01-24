import os
from flask import Flask
from flask_cors import CORS
from flask_restx import Api
from flask_jwt_extended import JWTManager, jwt_required, get_jwt_identity, get_jwt
from auth.routes import auth_ns
from agents.routes import agents_ns
from clients.routes import clients_ns
from livraisons.routes import livraisons_ns
from commandes.routes import commandes_ns
from statistiques.routes import stats_ns
from cartographie.routes import carto_ns
from produits.routes import produits_ns
from notifications_admin import notifications_bp
from notification.routes import notification_ns
from user_notifications import user_notifications_ns
from rapports.routes import rapports_ns
from tours.blueprint import tours_bp
from db import get_connection

app = Flask(__name__)

# =========================
# CONFIG JWT
# =========================
app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "essivi-secret-key-dev")
app.config["JWT_TOKEN_LOCATION"] = ["headers", "cookies"]
app.config["JWT_HEADER_NAME"] = "Authorization"
app.config["JWT_HEADER_TYPE"] = ""  # Accept token without "Bearer " prefix
app.config["JWT_COOKIE_SECURE"] = True  # À mettre à True en production avec HTTPS
app.config["JWT_COOKIE_CSRF_PROTECT"] = False
app.config["JWT_COOKIE_SAMESITE"] = "None"

# =========================
# EXTENSIONS
# =========================
# Configure CORS for both local and production
allowed_origins = [
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://localhost:3000",
    "http://127.0.0.1:3000",
]
# Add production frontend URL if set in environment
if os.getenv("FRONTEND_URL"):
    allowed_origins.append(os.getenv("FRONTEND_URL"))

CORS(
    app,
    supports_credentials=True,
    allow_headers=["Content-Type", "Authorization", "Accept"],
    expose_headers=["Content-Type"],
    origins=allowed_origins,
    methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    max_age=3600
)
jwt = JWTManager(app)

# =========================
# SWAGGER / OPENAPI CONFIG
# =========================
authorizations = {
    "BearerAuth": {
        "type": "apiKey",
        "in": "header",
        "name": "Authorization",
        "description": "Entrez le token JWT directement (sans 'Bearer ')"
    }
}

api = Api(
    app,
    title="ESSIVI API",
    version="1.0",
    description="API de gestion de distribution d'eau potable",
    authorizations=authorizations,
    security="BearerAuth"
)

# =========================
# NAMESPACES
# =========================
api.add_namespace(auth_ns)
api.add_namespace(agents_ns)
api.add_namespace(clients_ns)
api.add_namespace(livraisons_ns)
api.add_namespace(commandes_ns)
api.add_namespace(stats_ns)
api.add_namespace(carto_ns)
api.add_namespace(produits_ns)
api.add_namespace(notification_ns)
api.add_namespace(user_notifications_ns)
api.add_namespace(rapports_ns)

# Enregistrer le blueprint notifications
app.register_blueprint(notifications_bp)

# Enregistrer le blueprint tours
app.register_blueprint(tours_bp)

# =========================
# ROUTES
# =========================
@app.route("/me")
@jwt_required()
def me():
    user_id = get_jwt_identity()
    claims = get_jwt()
    user_role = claims.get("role")

    conn = get_connection()
    cur = conn.cursor()

    try:
        if user_role == "agent":
            # Récupérer les infos utilisateur + agent
            cur.execute(
                """
                SELECT u.id, u.nom, u.email, u.role, u.created_at,
                       a.nom, a.telephone, a.email as agent_email, a.tricycle, a.actif
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
                    "nom": result["nom"],
                    "email": result["email"],
                    "role": result["role"],
                    "created_at": result["created_at"].isoformat() if result["created_at"] else None,
                    "agent_info": {
                        "nom": result["nom"],
                        "telephone": result["telephone"],
                        "email": result["agent_email"],
                        "tricycle": result["tricycle"],
                        "actif": result["actif"]
                    } if result["nom"] else None
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
                        "latitude": result["latitude"],
                        "longitude": result["longitude"]
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

        return {"error": "Utilisateur non trouvé"}, 404

    except Exception as e:
        return {"error": f"Erreur serveur: {str(e)}"}, 500
    finally:
        conn.close()

# =========================
# MAIN
# =========================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
