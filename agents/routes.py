from flask_restx import Namespace, Resource, fields
from flask import request
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity
from werkzeug.security import generate_password_hash
from werkzeug.exceptions import HTTPException
from db import get_connection
import psycopg2
from datetime import datetime

agents_ns = Namespace(
    "agents",
    path="/agents",
    description="Agent management endpoints"
)

# Modèles pour la validation des données
agent_model = agents_ns.model('Agent', {
    'nom': fields.String(required=True, description='Nom de l\'agent'),
    'email': fields.String(required=True, description='Email de l\'agent'),
    'password': fields.String(required=True, description='Mot de passe de l\'agent'),
    'telephone': fields.String(required=True, description='Téléphone de l\'agent'),
    'tricycle': fields.String(description='Numéro du tricycle'),
    'actif': fields.Boolean(description='Statut actif de l\'agent'),
    'latitude': fields.Float(description='Latitude GPS'),
    'longitude': fields.Float(description='Longitude GPS')
})

agent_update_model = agents_ns.model('AgentUpdate', {
    'nom': fields.String(description='Nom de l\'agent'),
    'email': fields.String(description='Email de l\'agent'),
    'telephone': fields.String(description='Téléphone de l\'agent'),
    'tricycle': fields.String(description='Numéro du tricycle'),
    'actif': fields.Boolean(description='Statut actif de l\'agent'),
    'latitude': fields.Float(description='Latitude GPS'),
    'longitude': fields.Float(description='Longitude GPS')
})

@agents_ns.route("/")
class AgentsList(Resource):
    @agents_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer la liste de tous les agents"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            cur.execute(
                """
                SELECT
                    a.id as agent_id,
                    u.nom,
                    u.email,
                    u.created_at,
                    a.telephone,
                    a.tricycle,
                    a.actif,
                    a.latitude,
                    a.longitude,
                    a.last_location_update
                FROM users u
                JOIN agents a ON u.id = a.user_id
                ORDER BY u.created_at DESC
                """
            )

            agents = cur.fetchall()

            result = []
            for agent in agents:
                # Compter les livraisons (simplifié pour l'exemple)
                cur.execute(
                    "SELECT COUNT(*) as delivery_count FROM livraisons WHERE agent_id = %s",
                    (agent["agent_id"],)
                )
                delivery_count = cur.fetchone()["delivery_count"]

                result.append({
                    "id": agent['agent_id'],
                    "matricule": f"AG-{agent['agent_id']:03d}",
                    "name": agent["nom"],
                    "firstName": agent["nom"].split()[0] if agent["nom"] else "",
                    "lastName": " ".join(agent["nom"].split()[1:]) if len(agent["nom"].split()) > 1 else "",
                    "initials": "".join([n[0] for n in agent["nom"].split()[:2]]).upper() if agent["nom"] else "AG",
                    "phone": agent["telephone"] or "",
                    "email": agent["email"],
                    "tricycle": agent["tricycle"] or "",
                    "status": "active" if agent["actif"] else "inactive",
                    "deliveries": delivery_count,
                    "hireDate": agent["created_at"].strftime("%d/%m/%Y") if agent["created_at"] else "",
                    "latitude": float(agent["latitude"]) if agent["latitude"] else None,
                    "longitude": float(agent["longitude"]) if agent["longitude"] else None,
                    "lastLocationUpdate": agent["last_location_update"].strftime("%d/%m/%Y %H:%M") if agent["last_location_update"] else None,
                })

            return result

        except Exception as e:
            agents_ns.abort(500, f"Erreur serveur: {str(e)}")
        finally:
            conn.close()

    @agents_ns.doc(security="BearerAuth")
    @agents_ns.expect(agent_model)
    @jwt_required()
    def post(self):
        """Créer un nouvel agent"""
        data = request.get_json()

        # Validation des données requises (aligné sur /auth/create-agent)
        required_fields = ['nom', 'email', 'telephone', 'password']
        for field in required_fields:
            if field not in data or not data[field]:
                agents_ns.abort(400, f"Le champ '{field}' est requis")

        conn = get_connection()
        cur = conn.cursor()

        try:
            # Vérifier doublon email
            cur.execute("SELECT id FROM users WHERE email = %s", (data['email'],))
            if cur.fetchone():
                agents_ns.abort(409, "Email déjà utilisé")

            # Créer l'utilisateur agent using pgcrypto crypt() for consistency
            try:
                cur.execute(
                    """
                    INSERT INTO users (nom, email, password_hash, role)
                    VALUES (%s, %s, crypt(%s, gen_salt('bf')), 'agent')
                    RETURNING id
                    """,
                    (data['nom'], data['email'], data['password'])
                )
            except psycopg2.IntegrityError as e:
                conn.rollback()
                msg = str(e)
                if 'email' in msg.lower():
                    agents_ns.abort(409, "Email déjà utilisé")
                else:
                    agents_ns.abort(400, f"Erreur création user: {msg}")

            user_id = cur.fetchone()["id"]

            # Créer l'agent
            try:
                cur.execute(
                    """
                    INSERT INTO agents (
                        nom, telephone, email, tricycle, actif, latitude, longitude, user_id
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id
                    """,
                    (
                        data.get('nom'),
                        data['telephone'],
                        data.get('email'),
                        data.get('tricycle'),
                        data.get('actif', True),
                        data.get('latitude'),
                        data.get('longitude'),
                        user_id
                    )
                )
            except psycopg2.IntegrityError as e:
                conn.rollback()
                msg = str(e)
                if 'telephone' in msg.lower():
                    agents_ns.abort(409, "Téléphone déjà utilisé")
                elif 'email' in msg.lower():
                    agents_ns.abort(409, "Email déjà utilisé pour un agent")
                else:
                    agents_ns.abort(400, f"Erreur création agent: {msg}")

            agent_id = cur.fetchone()["id"]
            conn.commit()

            return {
                "id": agent_id,
                "message": "Agent créé avec succès",
                "user_id": user_id
            }, 201

        except Exception as e:
            if isinstance(e, HTTPException):
                raise
            conn.rollback()
            agents_ns.abort(500, f"Erreur lors de la création de l'agent: {str(e)}")
        finally:
            conn.close()

@agents_ns.route("/<int:agent_id>")
class AgentDetail(Resource):
    @agents_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, agent_id):
        """Récupérer les détails d'un agent spécifique"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            cur.execute(
                """
                SELECT
                    a.id as agent_id,
                    u.nom,
                    u.email,
                    u.created_at,
                    a.telephone,
                    a.tricycle,
                    a.actif,
                    a.latitude,
                    a.longitude,
                    a.last_location_update
                FROM users u
                JOIN agents a ON u.id = a.user_id
                WHERE a.id = %s
                """,
                (agent_id,)
            )

            agent = cur.fetchone()

            if not agent:
                agents_ns.abort(404, "Agent non trouvé")

            # Compter les livraisons
            cur.execute(
                "SELECT COUNT(*) as delivery_count FROM livraisons WHERE agent_id = %s",
                (agent_id,)
            )
            delivery_count = cur.fetchone()["delivery_count"]

            return {
                "id": agent['agent_id'],
                "matricule": f"AG-{agent['agent_id']:03d}",
                "name": agent["nom"],
                "firstName": agent["nom"].split()[0] if agent["nom"] else "",
                "lastName": " ".join(agent["nom"].split()[1:]) if len(agent["nom"].split()) > 1 else "",
                "initials": "".join([n[0] for n in agent["nom"].split()[:2]]).upper() if agent["nom"] else "AG",
                "phone": agent["telephone"] or "",
                "email": agent["email"],
                "tricycle": agent["tricycle"] or "",
                "status": "active" if agent["actif"] else "inactive",
                "deliveries": delivery_count,
                "hireDate": agent["created_at"].strftime("%d/%m/%Y") if agent["created_at"] else "",
                "latitude": float(agent["latitude"]) if agent["latitude"] else None,
                "longitude": float(agent["longitude"]) if agent["longitude"] else None,
                "lastLocationUpdate": agent["last_location_update"].strftime("%d/%m/%Y %H:%M") if agent["last_location_update"] else None,
            }

        except Exception as e:
            agents_ns.abort(500, f"Erreur serveur: {str(e)}")
        finally:
            conn.close()

    @agents_ns.doc(security="BearerAuth")
    @agents_ns.expect(agent_update_model)
    @jwt_required()
    def put(self, agent_id):
        """Mettre à jour un agent"""
        data = request.get_json()

        conn = get_connection()
        cur = conn.cursor()

        try:
            # Vérifier que l'agent existe
            cur.execute(
                "SELECT user_id FROM agents WHERE id = %s",
                (agent_id,)
            )

            agent = cur.fetchone()
            if not agent:
                agents_ns.abort(404, "Agent non trouvé")

            user_id = agent["user_id"]

            # Mettre à jour l'utilisateur si nécessaire
            if 'nom' in data or 'email' in data:
                update_fields = []
                update_values = []

                if 'nom' in data:
                    update_fields.append("nom = %s")
                    update_values.append(data['nom'])

                if 'email' in data:
                    update_fields.append("email = %s")
                    update_values.append(data['email'])

                if update_fields:
                    update_values.append(user_id)
                    cur.execute(
                        f"UPDATE users SET {', '.join(update_fields)} WHERE id = %s",
                        update_values
                    )

            # Mettre à jour l'agent
            update_fields = []
            update_values = []

            if 'telephone' in data:
                update_fields.append("telephone = %s")
                update_values.append(data['telephone'])

            if 'tricycle' in data:
                update_fields.append("tricycle = %s")
                update_values.append(data['tricycle'])

            if 'actif' in data:
                update_fields.append("actif = %s")
                update_values.append(data['actif'])

            if 'latitude' in data:
                update_fields.append("latitude = %s")
                update_values.append(data['latitude'])

            if 'longitude' in data:
                update_fields.append("longitude = %s")
                update_values.append(data['longitude'])

            if update_fields:
                update_values.append(agent_id)
                cur.execute(
                    f"UPDATE agents SET {', '.join(update_fields)} WHERE id = %s",
                    update_values
                )

            conn.commit()
            return {"message": "Agent mis à jour avec succès"}

        except Exception as e:
            conn.rollback()
            agents_ns.abort(500, f"Erreur lors de la mise à jour de l'agent: {str(e)}")
        finally:
            conn.close()

    @agents_ns.doc(security="BearerAuth")
    @jwt_required()
    def delete(self, agent_id):
        """Supprimer un agent"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            # Vérifier que l'agent existe et récupérer l'user_id
            cur.execute(
                "SELECT user_id FROM agents WHERE id = %s",
                (agent_id,)
            )

            agent = cur.fetchone()
            if not agent:
                agents_ns.abort(404, "Agent non trouvé")

            user_id = agent["user_id"]

            # Supprimer l'agent d'abord
            cur.execute("DELETE FROM agents WHERE id = %s", (agent_id,))

            # Supprimer l'utilisateur associé
            cur.execute("DELETE FROM users WHERE id = %s", (user_id,))

            conn.commit()
            return {"message": "Agent supprimé avec succès"}

        except Exception as e:
            conn.rollback()
            agents_ns.abort(500, f"Erreur lors de la suppression de l'agent: {str(e)}")
        finally:
            conn.close()

@agents_ns.route("/<int:agent_id>/location")
class AgentLocation(Resource):
    @agents_ns.doc(security="BearerAuth")
    @jwt_required()
    def put(self, agent_id):
        """Mettre à jour la position GPS d'un agent"""
        data = request.get_json()

        if not data or 'latitude' not in data or 'longitude' not in data:
            agents_ns.abort(400, "latitude et longitude sont requis")

        latitude = data.get("latitude")
        longitude = data.get("longitude")

        # Validation des coordonnées
        if not (-90 <= latitude <= 90) or not (-180 <= longitude <= 180):
            agents_ns.abort(400, "Coordonnées GPS invalides")

        conn = get_connection()
        cur = conn.cursor()

        try:
            # Vérifier que l'agent existe et appartient à l'utilisateur connecté
            claims = get_jwt()
            user_id = claims['sub']

            cur.execute(
                "SELECT id FROM agents WHERE id = %s AND user_id = %s",
                (agent_id, user_id)
            )

            if not cur.fetchone():
                agents_ns.abort(404, "Agent non trouvé ou accès non autorisé")

            # Mettre à jour la position
            cur.execute(
                """
                UPDATE agents
                SET latitude = %s, longitude = %s, last_location_update = CURRENT_TIMESTAMP
                WHERE id = %s
                """,
                (latitude, longitude, agent_id)
            )

            conn.commit()
            return {"message": "Position mise à jour avec succès"}

        except Exception as e:
            conn.rollback()
            agents_ns.abort(500, f"Erreur serveur: {str(e)}")
        finally:
            conn.close()

@agents_ns.route("/active-locations")
class ActiveAgentsLocations(Resource):
    @agents_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer les positions des agents actifs (mis à jour récemment)"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            # Récupérer les agents actifs avec position récente (dernières 24h)
            cur.execute(
                """
                SELECT
                    a.id,
                    u.nom as name,
                    a.telephone as phone,
                    a.tricycle,
                    a.latitude,
                    a.longitude,
                    a.last_location_update,
                    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - a.last_location_update))/60 as minutes_since_update
                FROM agents a
                JOIN users u ON a.user_id = u.id
                WHERE a.actif = TRUE
                AND a.latitude IS NOT NULL
                AND a.longitude IS NOT NULL
                AND a.last_location_update > CURRENT_TIMESTAMP - INTERVAL '24 hours'
                ORDER BY a.last_location_update DESC
                """
            )

            agents = cur.fetchall()
            result = []

            for agent in agents:
                result.append({
                    "id": agent['id'],
                    "matricule": f"AG-{agent['id']:03d}",
                    "name": agent["name"],
                    "phone": agent["phone"],
                    "tricycle": agent["tricycle"],
                    "latitude": float(agent["latitude"]),
                    "longitude": float(agent["longitude"]),
                    "lastLocationUpdate": agent["last_location_update"].strftime("%d/%m/%Y %H:%M:%S") if agent["last_location_update"] else None,
                    "minutesSinceUpdate": round(float(agent["minutes_since_update"]), 1),
                    "isOnline": float(agent["minutes_since_update"]) < 30,  # En ligne si MAJ < 30 min
                })

            return result

        except Exception as e:
            agents_ns.abort(500, f"Erreur serveur: {str(e)}")
        finally:
            conn.close()


@agents_ns.route("/<int:agent_id>/monthly-stats")
class AgentMonthlyStats(Resource):
    def options(self, agent_id):
        """Handle CORS preflight requests"""
        from flask import make_response
        response = make_response()
        response.status_code = 200
        return response
    
    @agents_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, agent_id):
        """Récupérer les statistiques mensuelles d'un agent"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            # Vérifier que l'agent existe
            cur.execute("SELECT id FROM agents WHERE id = %s", (agent_id,))
            if not cur.fetchone():
                agents_ns.abort(404, "Agent non trouvé")

            # Statistiques des 6 derniers mois
            cur.execute("""
                SELECT
                    TO_CHAR(DATE_TRUNC('month', l.created_at), 'Mon') as month,
                    TO_CHAR(DATE_TRUNC('month', l.created_at), 'YYYY') as year,
                    COUNT(*) as deliveries,
                    COALESCE(SUM(l.montant_percu), 0) as revenue
                FROM livraisons l
                WHERE l.agent_id = %s
                AND l.created_at > CURRENT_DATE - INTERVAL '6 months'
                GROUP BY DATE_TRUNC('month', l.created_at), TO_CHAR(DATE_TRUNC('month', l.created_at), 'Mon'), TO_CHAR(DATE_TRUNC('month', l.created_at), 'YYYY')
                ORDER BY DATE_TRUNC('month', l.created_at) DESC
            """, (agent_id,))

            monthly_data = cur.fetchall()

            # Statistiques du mois en cours
            cur.execute("""
                SELECT
                    COUNT(*) as this_month_deliveries,
                    COALESCE(SUM(montant_percu), 0) as this_month_revenue
                FROM livraisons
                WHERE agent_id = %s
                AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
            """, (agent_id,))

            current_month = cur.fetchone()

            # Statistiques globales pour calculer les taux
            cur.execute("""
                SELECT
                    COUNT(*) as total_deliveries,
                    SUM(CASE WHEN statut = 'livree' THEN 1 ELSE 0 END) as completed_deliveries,
                    COALESCE(SUM(montant_percu), 0) as total_revenue
                FROM livraisons
                WHERE agent_id = %s
            """, (agent_id,))

            global_stats = cur.fetchone()

            # Calculer les taux
            total_deliveries = global_stats['total_deliveries'] or 0
            completed_deliveries = global_stats['completed_deliveries'] or 0
            completion_rate = (completed_deliveries / total_deliveries * 100) if total_deliveries > 0 else 0

            # Calculer taux à l'heure (livraisons terminées / total * 100, approximatif)
            on_time_rate = completion_rate * 0.9  # Approximation

            return {
                "monthly_stats": [
                    {
                        "month": f"{row['month']} {row['year']}",
                        "deliveries": row['deliveries'] or 0,
                        "revenue": float(row['revenue'] or 0)
                    }
                    for row in monthly_data
                ],
                "current_month": {
                    "deliveries": current_month['this_month_deliveries'] or 0,
                    "revenue": float(current_month['this_month_revenue'] or 0)
                },
                "global_stats": {
                    "total_deliveries": total_deliveries,
                    "completion_rate": round(completion_rate, 1),
                    "on_time_rate": round(on_time_rate, 1),
                    "total_revenue": float(global_stats['total_revenue'] or 0)
                }
            }

        except Exception as e:
            agents_ns.abort(500, f"Erreur: {str(e)}")
        finally:
            conn.close()


@agents_ns.route("/stats")
class AgentStats(Resource):
    @agents_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer les statistiques de l'agent connecté"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            from flask import request
            period = request.args.get('period', 'month')

            # Récupérer l'agent_id depuis le token JWT
            user_id = get_jwt_identity()
            claims = get_jwt()
            user_role = claims.get("role")

            if user_role != "agent":
                agents_ns.abort(403, "Accès réservé aux agents")

            # Récupérer l'agent_id depuis la table agents
            cur.execute("SELECT id FROM agents WHERE user_id = %s", (user_id,))
            agent = cur.fetchone()

            if not agent:
                agents_ns.abort(404, "Agent non trouvé")

            agent_id = agent['id']

            # Statistiques du jour
            cur.execute("""
                SELECT
                    COUNT(*) as total,
                    SUM(CASE WHEN statut = 'livree' THEN 1 ELSE 0 END) as completed,
                    COALESCE(SUM(quantite), 0) as total_quantity,
                    COALESCE(SUM(montant_percu), 0) as total_amount
                FROM livraisons
                WHERE agent_id = %s
                AND DATE(date_livraison) = CURRENT_DATE
            """, (agent_id,))

            stats_day = cur.fetchone()

            # Gérer le cas où il n'y a pas de livraisons (stats_day peut être None)
            if stats_day:
                total = stats_day['total'] or 0
                completed = stats_day['completed'] or 0
                total_amount = float(stats_day['total_amount'] or 0)
                total_quantity = int(stats_day['total_quantity'] or 0)
            else:
                total = 0
                completed = 0
                total_amount = 0.0
                total_quantity = 0

            # Calculer le taux de complétion
            completion_rate = (completed / total * 100) if total > 0 else 0

            return {
                "total_deliveries": total,
                "completed_deliveries": completed,
                "total_amount": total_amount,
                "total_quantity": total_quantity,
                "average_distance": 15.5,  # Valeur par défaut, peut être calculée plus tard
                "completion_rate": round(completion_rate, 2)
            }

        except Exception as e:
            agents_ns.abort(500, f"Erreur: {str(e)}")
        finally:
            conn.close()
