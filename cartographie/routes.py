from flask_restx import Namespace, Resource, fields
from flask import request
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from db import get_connection
import traceback
from datetime import datetime
from decimal import Decimal


def convert_decimal(obj):
    """Convert Decimal, datetime, date, and time objects to JSON-serializable types"""
    import datetime as dt
    if isinstance(obj, Decimal):
        return float(obj)
    if isinstance(obj, (dt.datetime, dt.date, dt.time)):
        return obj.isoformat()
    if isinstance(obj, dict):
        return {k: convert_decimal(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [convert_decimal(item) for item in obj]
    return obj

carto_ns = Namespace(
    "cartographie",
    path="/cartographie",
    description="Cartography and localization endpoints"
)

# ===== Swagger Models =====
localisation_model = carto_ns.model("Localisation", {
    "latitude": fields.Float(required=True),
    "longitude": fields.Float(required=True),
})


@carto_ns.route("/agents/temps-reel")
class AgentsTempsReel(Resource):
    @carto_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer les positions en temps réel de tous les agents en tournée"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            cur.execute("""
                SELECT
                    a.id,
                    a.nom,
                    a.telephone,
                    a.tricycle,
                    a.latitude,
                    a.longitude,
                    a.last_location_update,
                    COUNT(l.id) as livraisons_jour,
                    SUM(l.montant_percu) as montant_jour
                FROM agents a
                LEFT JOIN livraisons l ON a.id = l.agent_id 
                    AND DATE(l.date_livraison) = CURRENT_DATE
                WHERE a.actif = TRUE AND a.latitude IS NOT NULL AND a.longitude IS NOT NULL
                GROUP BY a.id, a.nom, a.telephone, a.tricycle, a.latitude, a.longitude, a.last_location_update
                ORDER BY a.last_location_update DESC
            """)
            
            agents = cur.fetchall()
            
            return {
                "agents": agents,
                "timestamp": datetime.now().isoformat()
            }, 200
            
        except Exception as e:
            # Log full stack trace to server logs for debugging
            print("[cartographie/ClientsGeo] Exception:")
            print(traceback.format_exc())
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@carto_ns.route("/agents/<int:agent_id>/localiser")
class LocaliserAgent(Resource):
    @carto_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, agent_id):
        """Récupérer la position actuelle d'un agent"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            cur.execute("""
                SELECT
                    id,
                    nom,
                    telephone,
                    tricycle,
                    latitude,
                    longitude,
                    last_location_update
                FROM agents
                WHERE id = %s
            """, (agent_id,))
            
            agent = cur.fetchone()
            
            if not agent:
                return {"error": "Agent non trouvé"}, 404
            
            return agent, 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()
    
    @carto_ns.doc(security="BearerAuth")
    @carto_ns.expect(localisation_model)
    @jwt_required()
    def put(self, agent_id):
        """Mettre à jour la position GPS d'un agent"""
        user_id = get_jwt_identity()
        claims = get_jwt()
        user_role = claims.get("role")
        
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            data = request.get_json()
            
            # Vérifier que l'agent modifie sa propre position ou qu'il est admin
            if user_role == "agent":
                cur.execute("SELECT id FROM agents WHERE user_id = %s", (user_id,))
                agent = cur.fetchone()
                if not agent or agent["id"] != agent_id:
                    return {"error": "Accès non autorisé"}, 403
            
            cur.execute("""
                UPDATE agents
                SET latitude = %s, longitude = %s, last_location_update = CURRENT_TIMESTAMP
                WHERE id = %s
                RETURNING id, latitude, longitude, last_location_update
            """, (
                data.get("latitude"),
                data.get("longitude"),
                agent_id
            ))
            
            result = cur.fetchone()
            
            if not result:
                return {"error": "Agent non trouvé"}, 404
            
            conn.commit()
            
            return {
                "message": "Position mise à jour",
                "agent_id": result["id"],
                "latitude": result["latitude"],
                "longitude": result["longitude"],
                "updated_at": result["last_location_update"].isoformat()
            }, 200
            
        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@carto_ns.route("/clients/geo")
class ClientsGeo(Resource):
    @carto_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer toutes les positions des clients"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            zone = request.args.get("zone")  # Filtrer par zone si fourni
            
            query = """
                SELECT
                    id,
                    nom_point_vente,
                    responsable,
                    telephone,
                    adresse,
                    latitude,
                    longitude
                FROM clients
                WHERE latitude IS NOT NULL AND longitude IS NOT NULL
            """
            
            params = []
            
            if zone:
                query += " AND adresse ILIKE %s"
                params.append(f"%{zone}%")
            
            query += " ORDER BY nom_point_vente"
            
            cur.execute(query, params)
            clients = cur.fetchall()
            
            # Convert results to ensure decimals are converted to float
            clients_data = []
            if clients:
                for client in clients:
                    client_dict = dict(client) if hasattr(client, 'keys') else client
                    clients_data.append(convert_decimal(client_dict))
            
            return {"data": clients_data}, 200
            
        except Exception as e:
            # Log full stack trace to server logs for debugging
            print("[cartographie/ClientsGeo] Exception:")
            print(traceback.format_exc())
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@carto_ns.route("/livraisons/trajet/<int:livraison_id>")
class TrajetsLivraison(Resource):
    @carto_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, livraison_id):
        """Récupérer le trajet d'une livraison"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            # Récupérer les points de la livraison
            cur.execute("""
                SELECT
                    l.id,
                    l.latitude_gps as latitude,
                    l.longitude_gps as longitude,
                    l.date_livraison,
                    l.heure_livraison,
                    l.adresse_livraison,
                    c.nom_point_vente,
                    a.latitude as agent_lat_start,
                    a.longitude as agent_lon_start
                FROM livraisons l
                LEFT JOIN clients c ON l.client_id = c.id
                LEFT JOIN agents a ON l.agent_id = a.id
                WHERE l.id = %s
            """, (livraison_id,))
            
            livraison = cur.fetchone()
            
            if not livraison:
                return {"error": "Livraison non trouvée"}, 404
            
            return {
                "livraison_id": livraison_id,
                "point_depart": {
                    "latitude": livraison["agent_lat_start"],
                    "longitude": livraison["agent_lon_start"]
                },
                "point_arrivee": {
                    "latitude": livraison["latitude"],
                    "longitude": livraison["longitude"],
                    "adresse": livraison["adresse_livraison"],
                    "client": livraison["nom_point_vente"]
                },
                "date": livraison["date_livraison"].isoformat() if livraison["date_livraison"] else None
            }, 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@carto_ns.route("/zones/couverture")
class CouvertureZones(Resource):
    @carto_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer les zones couvertes par les agents"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            cur.execute("""
                SELECT
                    a.id as agent_id,
                    a.nom,
                    COUNT(DISTINCT l.client_id) as clients_desservis,
                    MIN(l.latitude_gps) as lat_min,
                    MAX(l.latitude_gps) as lat_max,
                    MIN(l.longitude_gps) as lon_min,
                    MAX(l.longitude_gps) as lon_max
                FROM agents a
                LEFT JOIN livraisons l ON a.id = l.agent_id
                    AND DATE(l.date_livraison) >= CURRENT_DATE - INTERVAL '30 days'
                WHERE a.actif = TRUE
                GROUP BY a.id, a.nom
                ORDER BY clients_desservis DESC
            """)
            
            zones = cur.fetchall()
            
            return {"zones": zones}, 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@carto_ns.route("/clients/<int:client_id>/localiser")
class LocaliserClient(Resource):
    @carto_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, client_id):
        """Récupérer la position actuelle d'un client"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            cur.execute("""
                SELECT
                    id,
                    nom_point_vente,
                    responsable,
                    telephone,
                    latitude,
                    longitude
                FROM clients
                WHERE id = %s
            """, (client_id,))
            
            client = cur.fetchone()
            
            if not client:
                return {"error": "Client non trouvé"}, 404
            
            return convert_decimal(client), 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()
    
    @carto_ns.doc(security="BearerAuth")
    @carto_ns.expect(localisation_model)
    @jwt_required()
    def put(self, client_id):
        """Mettre à jour la position GPS d'un client"""
        user_id = get_jwt_identity()
        claims = get_jwt()
        user_role = claims.get("role")
        
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            data = request.get_json()
            
            # Vérifier que le client modifie sa propre position ou qu'il est admin
            if user_role == "client":
                cur.execute("SELECT id FROM clients WHERE user_id = %s", (user_id,))
                client = cur.fetchone()
                if not client or client["id"] != client_id:
                    return {"error": "Accès non autorisé"}, 403
            
            cur.execute("""
                UPDATE clients
                SET latitude = %s, longitude = %s
                WHERE id = %s
                RETURNING id, latitude, longitude
            """, (
                data.get("latitude"),
                data.get("longitude"),
                client_id
            ))
            
            result = cur.fetchone()
            
            if not result:
                return {"error": "Client non trouvé"}, 404
            
            conn.commit()
            
            return {
                "message": "Position mise à jour",
                "client_id": result["id"],
                "latitude": result["latitude"],
                "longitude": result["longitude"],
                "updated_at": datetime.now().isoformat()
            }, 200
            
        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()

    def options(self, client_id):
        """Gérer les requêtes OPTIONS pour CORS"""
        return {}, 200


@carto_ns.route("/proximite")
class ProximiteAgentClient(Resource):
    @carto_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Calculer la proximité agent-client (pour validation de livraison)"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            agent_id = request.args.get("agent_id", type=int, required=True)
            client_id = request.args.get("client_id", type=int, required=True)
            
            # Récupérer les coordonnées
            cur.execute("""
                SELECT latitude, longitude FROM agents WHERE id = %s
            """, (agent_id,))
            agent = cur.fetchone()
            
            cur.execute("""
                SELECT latitude, longitude FROM clients WHERE id = %s
            """, (client_id,))
            client = cur.fetchone()
            
            if not agent or not client:
                return {"error": "Agent ou client non trouvé"}, 404
            
            # Calcul simplifié de distance (en km)
            # Formule approximée: sqrt((lat2-lat1)² + (lon2-lon1)²) * 111
            lat1, lon1 = agent["latitude"], agent["longitude"]
            lat2, lon2 = client["latitude"], client["longitude"]
            
            distance = ((lat2 - lat1)**2 + (lon2 - lon1)**2)**0.5 * 111
            
            # 2 km selon cahier des charges
            can_deliver = distance <= 2.0
            
            return {
                "distance_km": round(distance, 3),
                "peut_livrer": can_deliver,
                "seuil_km": 2.0
            }, 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()
