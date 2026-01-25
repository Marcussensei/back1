from flask_restx import Namespace, Resource, fields
from flask import request
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from db import get_connection
from datetime import datetime
from decimal import Decimal
from notifications import get_notification_service
import traceback
from threading import Thread


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


def send_notifications_async(client_info, agent_info, livraison_info):
    """Send notifications in a background thread to avoid blocking the response"""
    try:
        print("[send_notifications_async] Starting notification thread")
        notification_service = get_notification_service()
        
        # Ensure data is properly converted
        if client_info:
            client_info = dict(client_info) if hasattr(client_info, 'keys') else client_info
            print(f"[send_notifications_async] Client info: {client_info}")
        
        if agent_info:
            agent_info = dict(agent_info) if hasattr(agent_info, 'keys') else agent_info
            print(f"[send_notifications_async] Agent info: {agent_info}")
        
        if livraison_info:
            livraison_info = dict(livraison_info) if hasattr(livraison_info, 'keys') else livraison_info
            print(f"[send_notifications_async] Livraison info: {livraison_info}")
        
        # Notify client about agent assignment
        if client_info and client_info.get("email"):
            print(f"[send_notifications_async] Sending client notification to {client_info.get('email')}")
            notification_service.notify_agent_assignment(
                client_email=client_info.get("email"),
                client_name=client_info.get("client_name"),
                agent_name=agent_info.get("nom"),
                agent_phone=agent_info.get("telephone", "N/A"),
                delivery_address=livraison_info.get("adresse_livraison", "Adresse non spécifiée"),
                delivery_id=livraison_info.get("id")
            )
            print("[send_notifications_async] Client notification sent successfully")
        else:
            print(f"[send_notifications_async] No client email: client_info={client_info}")
        
        # Notify agent about delivery assignment
        if agent_info and agent_info.get("user_id"):
            print(f"[send_notifications_async] Sending agent notification to user {agent_info.get('user_id')}")
            notification_service.notify_agent_delivery_assignment(
                agent_user_id=agent_info.get("user_id"),
                agent_name=agent_info.get("agent_name"),
                delivery_id=livraison_info.get("id"),
                client_name=client_info.get("client_name", "Client") if client_info else "Client",
                delivery_address=livraison_info.get("adresse_livraison", "Adresse non spécifiée")
            )
            print("[send_notifications_async] Agent notification sent successfully")
        else:
            print(f"[send_notifications_async] No agent user_id: agent_info={agent_info}")
            
    except Exception as e:
        print(f"[send_notifications_async] Error: {str(e)}")
        print(traceback.format_exc())

livraisons_ns = Namespace(
    "livraisons",
    path="/livraisons",
    description="Livraisons management endpoints"
)

# ===== Swagger Models =====
livraison_model = livraisons_ns.model("Livraison", {
    "id": fields.Integer(readonly=True),
    "commande_id": fields.Integer(required=True),
    "agent_id": fields.Integer(required=True),
    "client_id": fields.Integer(required=True),
    "quantite": fields.Integer(required=True),
    "montant_percu": fields.Float(required=True),
    "latitude_gps": fields.Float(required=True),
    "longitude_gps": fields.Float(required=True),
    "adresse_livraison": fields.String(required=True),
    "photo_lieu": fields.String(),
    "signature_client": fields.String(),
    "date_livraison": fields.String(readonly=True),
    "heure_livraison": fields.String(readonly=True),
    "statut": fields.String(readonly=True),
})

create_livraison_model = livraisons_ns.model("CreateLivraison", {
    "commande_id": fields.Integer(required=True),
    "client_id": fields.Integer(required=True),
    "quantite": fields.Integer(required=True),
    "montant_percu": fields.Float(required=True),
    "latitude_gps": fields.Float(required=True),
    "longitude_gps": fields.Float(required=True),
    "adresse_livraison": fields.String(required=True),
    "photo_lieu": fields.String(),
    "signature_client": fields.String(),
    "statut": fields.String(),
})


@livraisons_ns.route("/")
class LivraisonsList(Resource):
    @livraisons_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer la liste de toutes les livraisons avec filtres"""
        conn = None
        try:
            conn = get_connection()
            cur = conn.cursor()
            
            print("[LivraisonsList GET] Starting request")
            
            # Récupérer les paramètres de filtrage
            agent_id = request.args.get("agent_id", type=int)
            client_id = request.args.get("client_id", type=int)
            statut = request.args.get("statut")
            date_debut = request.args.get("date_debut")
            date_fin = request.args.get("date_fin")
            montant_min = request.args.get("montant_min", type=float)
            montant_max = request.args.get("montant_max", type=float)
            page = request.args.get("page", default=1, type=int)
            per_page = request.args.get("per_page", default=100, type=int)
            
            print(f"[LivraisonsList GET] Params: agent_id={agent_id}, client_id={client_id}, statut={statut}, page={page}, per_page={per_page}")
            
            # Construire la requête dynamiquement
            query = """
                SELECT
                    l.id,
                    l.commande_id,
                    l.agent_id,
                    l.client_id,
                    l.quantite,
                    l.montant_percu,
                    l.latitude_gps,
                    l.longitude_gps,
                    l.adresse_livraison,
                    l.photo_lieu,
                    l.signature_client,
                    l.date_livraison,
                    l.heure_livraison,
                    l.statut,
                    l.created_at,
                    a.nom as agent_nom,
                    a.telephone as agent_telephone,
                    a.tricycle,
                    c.nom_point_vente,
                    c.responsable,
                    c.telephone as client_telephone,
                    cmd.latitude as order_latitude,
                    cmd.longitude as order_longitude,
                    cmd.montant_total
                FROM livraisons l
                LEFT JOIN agents a ON l.agent_id = a.id
                LEFT JOIN clients c ON l.client_id = c.id
                LEFT JOIN commandes cmd ON l.commande_id = cmd.id
                WHERE 1=1
            """
            
            params = []
            
            if agent_id:
                query += " AND l.agent_id = %s"
                params.append(agent_id)
            if client_id:
                query += " AND l.client_id = %s"
                params.append(client_id)
            if statut:
                query += " AND l.statut = %s"
                params.append(statut)
            if date_debut:
                query += " AND DATE(l.date_livraison) >= %s"
                params.append(date_debut)
            if date_fin:
                query += " AND DATE(l.date_livraison) <= %s"
                params.append(date_fin)
            if montant_min is not None:
                query += " AND l.montant_percu >= %s"
                params.append(montant_min)
            if montant_max is not None:
                query += " AND l.montant_percu <= %s"
                params.append(montant_max)
            
            # Compter le total
            count_query = "SELECT COUNT(*) as total FROM livraisons l WHERE 1=1"
            count_params = []
            
            if agent_id:
                count_query += " AND l.agent_id = %s"
                count_params.append(agent_id)
            if client_id:
                count_query += " AND l.client_id = %s"
                count_params.append(client_id)
            if statut:
                count_query += " AND l.statut = %s"
                count_params.append(statut)
            if date_debut:
                count_query += " AND DATE(l.date_livraison) >= %s"
                count_params.append(date_debut)
            if date_fin:
                count_query += " AND DATE(l.date_livraison) <= %s"
                count_params.append(date_fin)
            if montant_min is not None:
                count_query += " AND l.montant_percu >= %s"
                count_params.append(montant_min)
            if montant_max is not None:
                count_query += " AND l.montant_percu <= %s"
                count_params.append(montant_max)
            
            print(f"[LivraisonsList GET] Executing count query: {count_query}")
            cur.execute(count_query, count_params)
            count_result = cur.fetchone()
            print(f"[LivraisonsList GET] Count result: {count_result}")
            
            # Safe extraction of total count
            total = 0
            if count_result:
                if isinstance(count_result, dict):
                    total = count_result.get("total", 0) or 0
                else:
                    total = count_result[0] or 0
            
            print(f"[LivraisonsList GET] Total count: {total}")
            
            # Ajouter pagination et tri
            query += " ORDER BY l.created_at DESC LIMIT %s OFFSET %s"
            params.append(per_page)
            params.append((page - 1) * per_page)
            
            print(f"[LivraisonsList GET] Executing data query with params count: {len(params)}")
            cur.execute(query, params)
            livraisons = cur.fetchall()
            
            print(f"[LivraisonsList GET] Found {len(livraisons)} livraisons")
            
            # Convert and return
            converted_livraisons = convert_decimal(livraisons) if livraisons else []
            
            return {
                "livraisons": converted_livraisons,
                "total": total,
                "page": page,
                "per_page": per_page,
                "total_pages": (total + per_page - 1) // per_page if total > 0 else 0
            }, 200
            
        except Exception as e:
            print("[LivraisonsList GET] Exception occurred:")
            print(traceback.format_exc())
            return {"error": f"Erreur serveur: {str(e)}", "type": type(e).__name__}, 500
        finally:
            if conn:
                conn.close()
    
    @livraisons_ns.doc(security="BearerAuth")
    @livraisons_ns.expect(create_livraison_model)
    @jwt_required()
    def post(self):
        """Créer une nouvelle livraison"""
        user_id = get_jwt_identity()
        claims = get_jwt()
        user_role = claims.get("role")
        
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            data = request.get_json()
            
            # Récupérer l'ID de l'agent depuis le user_id
            cur.execute("SELECT id FROM agents WHERE user_id = %s", (user_id,))
            agent = cur.fetchone()
            
            if not agent and user_role != "admin":
                return {"error": "Vous n'êtes pas un agent"}, 403
            
            agent_id = agent["id"] if agent else data.get("agent_id")
            
            cur.execute("""
                INSERT INTO livraisons (
                    commande_id, agent_id, client_id, quantite, montant_percu,
                    latitude_gps, longitude_gps, adresse_livraison,
                    photo_lieu, signature_client, date_livraison, heure_livraison,
                    statut, created_at
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id, created_at
            """, (
                data.get("commande_id"),
                agent_id,
                data.get("client_id"),
                data.get("quantite"),
                data.get("montant_percu"),
                data.get("latitude_gps"),
                data.get("longitude_gps"),
                data.get("adresse_livraison"),
                data.get("photo_lieu"),
                data.get("signature_client"),
                datetime.now().date(),
                datetime.now().time(),
                "en_cours",
                datetime.now()
            ))
            
            result = cur.fetchone()
            conn.commit()
            
            return {
                "message": "Livraison créée avec succès",
                "livraison_id": result["id"],
                "created_at": result["created_at"].isoformat()
            }, 201
            
        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@livraisons_ns.route("/<int:livraison_id>")
class LivraisonDetail(Resource):

    @livraisons_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, livraison_id):
        """Récupérer les détails d'une livraison"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            cur.execute("""
                SELECT
                    l.id,
                    l.commande_id,
                    l.agent_id,
                    l.client_id,
                    l.quantite,
                    l.montant_percu,
                    l.latitude_gps,
                    l.longitude_gps,
                    l.adresse_livraison,
                    l.photo_lieu,
                    l.signature_client,
                    l.date_livraison,
                    l.heure_livraison,
                    l.statut,
                    l.created_at,
                    a.nom as agent_nom,
                    a.telephone as agent_telephone,
                    a.tricycle,
                    c.nom_point_vente,
                    c.responsable,
                    c.telephone as client_telephone,
                    c.adresse
                FROM livraisons l
                LEFT JOIN agents a ON l.agent_id = a.id
                LEFT JOIN clients c ON l.client_id = c.id
                WHERE l.id = %s
            """, (livraison_id,))

            livraison = cur.fetchone()

            if not livraison:
                return {"error": "Livraison non trouvée"}, 404

            return convert_decimal(livraison), 200

        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()
    
    @livraisons_ns.doc(security="BearerAuth")
    @livraisons_ns.expect(create_livraison_model)
    @jwt_required()
    def put(self, livraison_id):
        """Modifier une livraison"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            data = request.get_json()

            # Récupérer le statut actuel avant la mise à jour
            cur.execute("SELECT commande_id, statut FROM livraisons WHERE id = %s", (livraison_id,))
            livraison_actuelle = cur.fetchone()

            if not livraison_actuelle:
                return {"error": "Livraison non trouvée"}, 404

            cur.execute("""
                UPDATE livraisons
                SET
                    quantite = COALESCE(%s, quantite),
                    montant_percu = COALESCE(%s, montant_percu),
                    latitude_gps = COALESCE(%s, latitude_gps),
                    longitude_gps = COALESCE(%s, longitude_gps),
                    adresse_livraison = COALESCE(%s, adresse_livraison),
                    photo_lieu = COALESCE(%s, photo_lieu),
                    signature_client = COALESCE(%s, signature_client),
                    statut = COALESCE(%s, statut),
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
                RETURNING id, updated_at, statut
            """, (
                data.get("quantite"),
                data.get("montant_percu"),
                data.get("latitude_gps"),
                data.get("longitude_gps"),
                data.get("adresse_livraison"),
                data.get("photo_lieu"),
                data.get("signature_client"),
                data.get("statut"),
                livraison_id
            ))

            result = cur.fetchone()

            if not result:
                return {"error": "Livraison non trouvée"}, 404

            # Si le statut de la livraison passe à "livree", mettre à jour le statut de la commande à "livree"
            if data.get("statut") == "livree" and livraison_actuelle["statut"] != "livree":
                cur.execute("""
                    UPDATE commandes
                    SET statut = 'livree', date_livraison_effective = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
                    WHERE id = %s
                """, (livraison_actuelle["commande_id"],))

            conn.commit()

            return {
                "message": "Livraison modifiée avec succès",
                "livraison_id": result["id"],
                "updated_at": result["updated_at"].isoformat()
            }, 200

        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()
    
    @livraisons_ns.doc(security="BearerAuth")
    @jwt_required()
    def delete(self, livraison_id):
        """Supprimer une livraison"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            cur.execute("DELETE FROM livraisons WHERE id = %s RETURNING id", (livraison_id,))
            
            result = cur.fetchone()
            
            if not result:
                return {"error": "Livraison non trouvée"}, 404
            
            conn.commit()
            
            return {"message": "Livraison supprimée avec succès"}, 200
            
        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


# Endpoint to assign an agent to a delivery
assign_model = livraisons_ns.model("AssignAgent", {
    "agent_id": fields.Integer(required=True),
})


@livraisons_ns.route("/<int:livraison_id>/assign")
class AssignAgent(Resource):
    @livraisons_ns.doc(security="BearerAuth")
    @livraisons_ns.expect(assign_model)
    @jwt_required()
    def put(self, livraison_id):
        """Assigner un agent à une livraison"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            data = request.get_json()
            agent_id = data.get("agent_id")
            
            if not agent_id:
                return {"error": "agent_id est requis"}, 400
            
            # Vérifier que l'agent existe
            cur.execute("SELECT id, nom, telephone FROM agents WHERE id = %s", (agent_id,))
            agent = cur.fetchone()
            
            if not agent:
                return {"error": "Agent non trouvé"}, 404
            
            # Vérifier que la livraison existe
            cur.execute("""
                SELECT l.id, l.client_id, l.adresse_livraison 
                FROM livraisons l
                WHERE l.id = %s
            """, (livraison_id,))
            livraison = cur.fetchone()
            
            if not livraison:
                return {"error": "Livraison non trouvée"}, 404
            
            # Assigner l'agent et mettre à jour le statut
            cur.execute("""
                UPDATE livraisons
                SET
                    agent_id = %s,
                    statut = 'en_cours',
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
                RETURNING id, agent_id, statut, updated_at, commande_id
            """, (agent_id, livraison_id))

            result = cur.fetchone()

            # Mettre à jour le statut et l'agent de la commande associée à "en_cours"
            cur.execute("""
                UPDATE commandes
                SET statut = 'en_cours', agent_id = %s, updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
            """, (agent_id, result["commande_id"]))

            conn.commit()
            
            # Prepare notification data for async sending
            client_info = None
            agent_user_info = None
            
            try:
                print(f"[AssignAgent] Fetching notification data for livraison_id={livraison_id}, client_id={livraison.get('client_id')}")
                
                # Fetch client info for notification
                cur.execute("""
                    SELECT c.id, u.email, u.nom as client_name
                    FROM clients c
                    JOIN users u ON c.user_id = u.id
                    WHERE c.id = %s
                """, (livraison["client_id"],))
                client_result = cur.fetchone()
                if client_result:
                    client_info = {
                        "id": client_result["id"],
                        "email": client_result["email"],
                        "client_name": client_result["client_name"]
                    }
                    print(f"[AssignAgent] Client info fetched: {client_info}")
                else:
                    print(f"[AssignAgent] No client found for client_id={livraison.get('client_id')}")
                
                # Fetch agent user info for notification
                cur.execute("""
                    SELECT u.id as user_id, u.nom as agent_name
                    FROM agents a
                    JOIN users u ON a.user_id = u.id
                    WHERE a.id = %s
                """, (agent_id,))
                agent_result = cur.fetchone()
                if agent_result:
                    agent_user_info = {
                        "user_id": agent_result["user_id"],
                        "agent_name": agent_result["agent_name"],
                        "nom": agent.get("nom"),
                        "telephone": agent.get("telephone")
                    }
                    print(f"[AssignAgent] Agent user info fetched: {agent_user_info}")
                else:
                    print(f"[AssignAgent] No agent user found for agent_id={agent_id}")
                    
            except Exception as e:
                print(f"[AssignAgent] Error fetching notification data: {str(e)}")
                print(traceback.format_exc())
            
            # Send notifications in background thread (non-blocking)
            if client_info or agent_user_info:
                livraison_data = {
                    "id": livraison_id,
                    "adresse_livraison": livraison.get("adresse_livraison")
                }
                print(f"[AssignAgent] Starting notification thread with client_info={bool(client_info)}, agent_info={bool(agent_user_info)}")
                notification_thread = Thread(
                    target=send_notifications_async,
                    args=(client_info, agent_user_info or {"nom": agent.get("nom"), "telephone": agent.get("telephone")}, livraison_data),
                    daemon=True
                )
                notification_thread.start()
                print("[AssignAgent] Notification thread started")
            else:
                print("[AssignAgent] No notification data to send")
            
            return {
                "message": "Agent assigné avec succès",
                "livraison_id": result["id"],
                "agent_id": result["agent_id"],
                "statut": result["statut"],
                "agent_nom": agent["nom"],
                "updated_at": result["updated_at"].isoformat()
            }, 200
            
        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@livraisons_ns.route("/statistiques/jour")
class LivraisonsStatistiquesJour(Resource):
    @livraisons_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer les statistiques du jour"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            cur.execute("""
                SELECT
                    COUNT(*) as nombre_livraisons,
                    SUM(quantite) as quantite_totale,
                    SUM(montant_percu) as montant_total,
                    AVG(montant_percu) as montant_moyen
                FROM livraisons
                WHERE DATE(date_livraison) = CURRENT_DATE
            """)
            
            stats = cur.fetchone()
            
            return {
                "nombre_livraisons": stats["nombre_livraisons"] or 0,
                "quantite_totale": stats["quantite_totale"] or 0,
                "montant_total": float(stats["montant_total"] or 0),
                "montant_moyen": float(stats["montant_moyen"] or 0)
            }, 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@livraisons_ns.route("/tours")
class ToursAPI(Resource):
    @livraisons_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer la liste des tournées (déprécié: utiliser /tours)"""
        # Cet endpoint est déprécié, utiliser GET /tours à la place
        return {"message": "Endpoint déprécié. Utiliser GET /tours à la place"}, 410


@livraisons_ns.route("/<int:livraison_id>/notifications-history")
class NotificationsHistory(Resource):
    @livraisons_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, livraison_id):
        """Récupérer l'historique des notifications d'une livraison"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            # Vérifier que la livraison existe
            cur.execute("SELECT id FROM livraisons WHERE id = %s", (livraison_id,))
            if not cur.fetchone():
                return {"error": "Livraison non trouvée"}, 404
            
            # Récupérer les notifications associées à cette livraison
            cur.execute("""
                SELECT
                    n.id,
                    n.utilisateur_id,
                    n.contenu as message,
                    n.type,
                    n.date_creation as sentAt,
                    n.est_lue as status
                FROM notifications n
                WHERE n.contenu LIKE CONCAT('%', %s, '%')
                ORDER BY n.date_creation DESC
                LIMIT 50
            """, (f"livraison {livraison_id}",))
            
            notifications = cur.fetchall()
            
            # Mapper les notifications au format frontend
            mapped_notifications = []
            for notif in notifications:
                mapped_notifications.append({
                    "id": str(notif["id"]),
                    "type": notif["type"] or "sms",
                    "message": notif["message"],
                    "sentAt": notif["sentAt"].isoformat() if notif["sentAt"] else None,
                    "status": "delivered" if notif["status"] else "pending"
                })
            
            return convert_decimal({
                "notifications": mapped_notifications,
                "total": len(mapped_notifications)
            }), 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()

    def options(self, livraison_id):
        """Gérer les requêtes OPTIONS pour CORS"""
        return {}, 200


@livraisons_ns.route("/<int:livraison_id>/tracking-history")
class TrackingHistory(Resource):
    @livraisons_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, livraison_id):
        """Récupérer l'historique de suivi d'une livraison"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            # Récupérer la livraison et ses informations d'état
            cur.execute("""
                SELECT
                    l.id,
                    l.statut,
                    l.date_livraison,
                    l.heure_livraison,
                    l.created_at,
                    l.updated_at,
                    a.nom as agent_nom,
                    c.nom_point_vente as client_name
                FROM livraisons l
                LEFT JOIN agents a ON l.agent_id = a.id
                LEFT JOIN clients c ON l.client_id = c.id
                WHERE l.id = %s
            """, (livraison_id,))
            
            livraison = cur.fetchone()
            
            if not livraison:
                return {"error": "Livraison non trouvée"}, 404
            
            # Construire l'historique de suivi basé sur l'état actuel
            tracking_steps = []
            
            # Étape 1: Commande reçue
            tracking_steps.append({
                "id": "1",
                "title": "Commande reçue",
                "description": "La commande a été enregistrée dans le système",
                "time": livraison["created_at"].strftime("%H:%M") if livraison["created_at"] else None,
                "completed": True,
                "current": False
            })
            
            # Étape 2: Agent assigné
            is_pending = livraison["statut"] in ["en_attente", "pending"]
            is_in_progress = livraison["statut"] in ["en_cours", "assigned"]
            is_completed = livraison["statut"] in ["livree", "completed"]
            
            tracking_steps.append({
                "id": "2",
                "title": "Agent assigné",
                "description": "En attente d'assignation" if is_pending else "Un livreur a été assigné à la commande",
                "time": None if is_pending else (livraison["updated_at"].strftime("%H:%M") if livraison["updated_at"] else None),
                "completed": not is_pending,
                "current": is_pending
            })
            
            # Étape 3: En route
            tracking_steps.append({
                "id": "3",
                "title": "En route",
                "description": "Le livreur est en route vers la destination" if is_in_progress or is_completed else "Le livreur partira bientôt",
                "time": None if not (is_in_progress or is_completed) else (livraison["heure_livraison"].strftime("%H:%M") if livraison["heure_livraison"] else None),
                "completed": is_in_progress or is_completed,
                "current": is_in_progress and not is_completed
            })
            
            # Étape 4: Arrivée sur place
            tracking_steps.append({
                "id": "4",
                "title": "Arrivée sur place",
                "description": "Le livreur est arrivé chez le client" if is_completed else "Le livreur arrivera bientôt",
                "time": None if not is_completed else (livraison["updated_at"].strftime("%H:%M") if livraison["updated_at"] else None),
                "completed": is_completed,
                "current": False
            })
            
            # Étape 5: Livraison effectuée
            tracking_steps.append({
                "id": "5",
                "title": "Livraison effectuée",
                "description": "La livraison a été confirmée par le client" if is_completed else "En attente de confirmation",
                "time": None if not is_completed else (livraison["updated_at"].strftime("%H:%M") if livraison["updated_at"] else None),
                "completed": is_completed,
                "current": False
            })
            
            return convert_decimal({
                "tracking_steps": tracking_steps,
                "current_status": livraison["statut"],
                "agent_name": livraison["agent_nom"],
                "client_name": livraison["client_name"]
            }), 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()

    def options(self, livraison_id):
        """Gérer les requêtes OPTIONS pour CORS"""
        return {}, 200


notify_model = livraisons_ns.model("NotifyClient", {
    "type": fields.String(required=True, enum=["sms", "whatsapp", "email"]),
    "message": fields.String(required=True),
})


@livraisons_ns.route("/<int:livraison_id>/notify")
class NotifyClient(Resource):
    @livraisons_ns.doc(security="BearerAuth")
    @livraisons_ns.expect(notify_model)
    @jwt_required()
    def post(self, livraison_id):
        """Envoyer une notification au client pour une livraison"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            data = request.get_json()
            notification_type = data.get("type", "sms")
            message = data.get("message")
            
            if not message:
                return {"error": "Message est requis"}, 400
            
            # Récupérer les détails de la livraison et du client
            cur.execute("""
                SELECT
                    l.id,
                    l.client_id,
                    c.telephone as client_phone,
                    u.email as client_email,
                    u.nom as client_name,
                    a.nom as agent_name,
                    l.adresse_livraison
                FROM livraisons l
                LEFT JOIN clients c ON l.client_id = c.id
                LEFT JOIN users u ON c.user_id = u.id
                LEFT JOIN agents a ON l.agent_id = a.id
                WHERE l.id = %s
            """, (livraison_id,))
            
            livraison = cur.fetchone()
            
            if not livraison:
                return {"error": "Livraison non trouvée"}, 404
            
            # Créer la notification dans la base de données
            cur.execute("""
                INSERT INTO notifications (
                    utilisateur_id, contenu, type, date_creation, est_lue
                )
                VALUES (
                    %s, %s, %s, %s, %s
                )
                RETURNING id, date_creation
            """, (
                livraison["client_id"],
                f"Livraison {livraison_id}: {message}",
                notification_type,
                datetime.now(),
                False
            ))
            
            result = cur.fetchone()
            conn.commit()
            
            # Envoyer la notification via le service de notifications (futur)
            # Pour l'instant, on enregistre juste la notification
            
            return {
                "message": "Notification envoyée avec succès",
                "notification_id": result["id"],
                "sent_at": result["date_creation"].isoformat(),
                "type": notification_type,
                "recipient": livraison["client_name"]
            }, 201
            
        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()

    def options(self, livraison_id):
        """Gérer les requêtes OPTIONS pour CORS"""
        return {}, 200
