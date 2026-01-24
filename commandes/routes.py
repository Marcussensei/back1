from flask_restx import Namespace, Resource, fields
from flask import request
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from db import get_connection
from datetime import datetime
from decimal import Decimal
import math
from notifications import get_notification_service
from notifications_admin import add_admin_notification


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


def haversine_distance(lat1, lon1, lat2, lon2):
    """
    Calculate the great circle distance between two points
    on the earth (specified in decimal degrees)
    Returns distance in meters
    """
    # Convert decimal degrees to radians
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])

    # Haversine formula
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))

    # Radius of earth in meters
    r = 6371000
    return c * r

commandes_ns = Namespace(
    "commandes",
    path="/commandes",
    description="Commandes management endpoints"
)

# ===== Swagger Models =====
commande_model = commandes_ns.model("Commande", {
    "id": fields.Integer(readonly=True),
    "client_id": fields.Integer(required=True),
    "agent_id": fields.Integer(),
    "date_commande": fields.String(readonly=True),
    "date_livraison_prevue": fields.String(),
    "date_livraison_effective": fields.String(),
    "statut": fields.String(),
    "montant_total": fields.Float(readonly=True),
    "notes": fields.String(),
})

create_commande_model = commandes_ns.model("CreateCommande", {
    "client_id": fields.Integer(required=True),
    "date_livraison_prevue": fields.String(),
    "notes": fields.String(),
    "latitude": fields.Float(),  # Position du client lors de la commande
    "longitude": fields.Float(),  # Position du client lors de la commande
    "delivery_address": fields.String(),
    "items": fields.List(fields.Raw(required=True))  # List of {produit_id, quantite, prix_unitaire}
})

update_statut_model = commandes_ns.model("UpdateStatut", {
    "statut": fields.String(required=True, enum=["en_attente", "confirmee", "en_cours", "livree", "annulee"]),
    "agent_id": fields.Integer(),
})


@commandes_ns.route("/")
class CommandesList(Resource):
    @commandes_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer la liste de toutes les commandes avec filtres"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            user_id = get_jwt_identity()
            claims = get_jwt()
            user_role = claims.get("role")
            
            client_id = request.args.get("client_id", type=int)
            agent_id = request.args.get("agent_id", type=int)
            statut = request.args.get("statut")
            date_debut = request.args.get("date_debut")
            date_fin = request.args.get("date_fin")
            page = request.args.get("page", default=1, type=int)
            per_page = request.args.get("per_page", default=20, type=int)

            base_query = """
                SELECT
                    c.id,
                    c.client_id,
                    c.agent_id,
                    c.date_commande,
                    c.date_livraison_prevue,
                    c.date_livraison_effective,
                    c.statut,
                    c.montant_total,
                    c.notes,
                    c.adresse_livraison,
                    cl.nom_point_vente,
                    cl.responsable,
                    cl.telephone as client_telephone,
                    a.nom as agent_nom,
                    a.telephone as agent_telephone
                FROM commandes c
                LEFT JOIN clients cl ON c.client_id = cl.id
                LEFT JOIN agents a ON c.agent_id = a.id
                WHERE 1=1
            """

            params = []
            
            # Filtrage automatique selon le rôle
            if user_role == "client":
                # Les clients ne voient que leurs propres commandes
                cur.execute("SELECT id FROM clients WHERE user_id = %s", (user_id,))
                client = cur.fetchone()
                if client:
                    base_query += " AND c.client_id = %s"
                    params.append(client["id"])
                else:
                    # Utilisateur client sans client associé
                    base_query += " AND c.client_id = 0"  # Aucune commande
            elif user_role == "agent":
                # Les agents voient les commandes qui leur sont assignées
                base_query += " AND c.agent_id = %s"
                params.append(user_id)
            # Les admins voient toutes les commandes (pas de filtrage automatique)

            # Filtres additionnels
            if client_id:
                base_query += " AND c.client_id = %s"
                params.append(client_id)
            if agent_id:
                base_query += " AND c.agent_id = %s"
                params.append(agent_id)
            if statut:
                base_query += " AND c.statut = %s"
                params.append(statut)
            if date_debut:
                base_query += " AND DATE(c.date_commande) >= %s"
                params.append(date_debut)
            if date_fin:
                base_query += " AND DATE(c.date_commande) <= %s"
                params.append(date_fin)

            # Compter le total
            count_query = "SELECT COUNT(*) as total FROM commandes c WHERE 1=1"
            count_params = []
            
            # Ajouter les mêmes filtres au count_query
            if user_role == "client":
                cur.execute("SELECT id FROM clients WHERE user_id = %s", (user_id,))
                client = cur.fetchone()
                if client:
                    count_query += " AND c.client_id = %s"
                    count_params.append(client["id"])
                else:
                    count_query += " AND c.client_id = 0"
            elif user_role == "agent":
                count_query += " AND c.agent_id = %s"
                count_params.append(user_id)
                
            if client_id:
                count_query += " AND c.client_id = %s"
                count_params.append(client_id)
            if agent_id:
                count_query += " AND c.agent_id = %s"
                count_params.append(agent_id)
            if statut:
                count_query += " AND c.statut = %s"
                count_params.append(statut)
            if date_debut:
                count_query += " AND DATE(c.date_commande) >= %s"
                count_params.append(date_debut)
            if date_fin:
                count_query += " AND DATE(c.date_commande) <= %s"
                count_params.append(date_fin)

            cur.execute(count_query, count_params)
            total = cur.fetchone()["total"]

            query = base_query

            # Ajouter pagination
            query += " ORDER BY c.date_commande DESC LIMIT %s OFFSET %s"
            params.append(per_page)
            params.append((page - 1) * per_page)

            cur.execute(query, params)
            commandes = cur.fetchall()

            return {
                "commandes": convert_decimal(commandes),
                "total": total,
                "page": page,
                "per_page": per_page,
                "total_pages": (total + per_page - 1) // per_page
            }, 200

        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()

    @commandes_ns.doc(security="BearerAuth")
    @commandes_ns.expect(create_commande_model)
    @jwt_required()
    def post(self):
        """Créer une nouvelle commande"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            data = request.get_json()
            
            # Récupérer le user_id du JWT
            user_id = get_jwt_identity()

            # Récupérer le client associé à cet utilisateur
            cur.execute(
                "SELECT id, adresse FROM clients WHERE user_id = %s",
                (user_id,)
            )
            client = cur.fetchone()
            
            if not client:
                return {"error": "Client non trouvé pour cet utilisateur"}, 404
            
            client_id = client["id"]
            
            # Utiliser l'adresse fournie dans la requête, sinon celle du client
            delivery_address = data.get("delivery_address") or client["adresse"]
            latitude = data.get("latitude")
            longitude = data.get("longitude")

            # Créer la commande avec l'adresse de livraison et les coordonnées GPS
            cur.execute("""
                INSERT INTO commandes (
                    client_id, date_livraison_prevue, statut, montant_total, notes, adresse_livraison, latitude, longitude, created_at
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id, created_at
            """, (
                client_id,
                data.get("date_livraison_prevue"),
                "en_attente",
                0,
                data.get("notes"),
                delivery_address,
                latitude,
                longitude,
                datetime.now()
            ))

            commande = cur.fetchone()
            commande_id = commande["id"]

            # Ajouter les articles de la commande
            montant_total = 0
            items = data.get("items", [])

            for item in items:
                montant_ligne = item.get("quantite") * item.get("prix_unitaire")
                montant_total += montant_ligne

                cur.execute("""
                    INSERT INTO commande_details (
                        commande_id, produit_id, quantite, prix_unitaire, montant_ligne, created_at
                    )
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (
                    commande_id,
                    item.get("produit_id"),
                    item.get("quantite"),
                    item.get("prix_unitaire"),
                    montant_ligne,
                    datetime.now()
                ))

            # Mettre à jour le montant total de la commande
            cur.execute(
                "UPDATE commandes SET montant_total = %s WHERE id = %s",
                (montant_total, commande_id)
            )

            # Créer automatiquement une livraison pour cette commande
            total_quantite = sum(item.get("quantite", 0) for item in items)
            
            # Récupérer la position du client (latitude et longitude)
            latitude = data.get("latitude", 0.0)
            longitude = data.get("longitude", 0.0)
            
            cur.execute("""
                INSERT INTO livraisons (
                    commande_id, client_id, quantite, montant_percu,
                    adresse_livraison, latitude_gps, longitude_gps,
                    date_livraison, heure_livraison, statut, created_at
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (
                commande_id,
                client_id,
                total_quantite,
                montant_total,
                delivery_address,
                latitude,  # Latitude fournie lors de la commande
                longitude,  # Longitude fournie lors de la commande
                datetime.now().date(),
                datetime.now().time(),
                "en_cours",  # Statut par défaut: en_cours (valid values: en_cours, terminee, probleme)
                datetime.now()
            ))
            
            livraison = cur.fetchone()
            livraison_id = livraison["id"]

            conn.commit()

            # Envoyer notification à l'admin (nouvelle commande)
            try:
                add_admin_notification(
                    notification_type="new_order",
                    title="Nouvelle commande",
                    message=f"Nouvelle commande #{commande_id} du client (Montant: {montant_total}€)",
                    data={
                        "commande_id": commande_id,
                        "client_id": client_id,
                        "montant_total": montant_total,
                        "livraison_id": livraison_id
                    },
                    sound=True
                )
            except Exception as e:
                print(f"Erreur lors de la notification admin: {str(e)}")

            return {
                "message": "Commande créée avec succès",
                "commande_id": commande_id,
                "livraison_id": livraison_id,
                "montant_total": montant_total,
                "adresse_livraison": delivery_address,
                "created_at": commande["created_at"].isoformat()
            }, 201

        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@commandes_ns.route("/<int:commande_id>/agent-location")
class CommandeAgentLocation(Resource):
    @commandes_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, commande_id):
        """Récupérer la position de l'agent assigné à une commande (pour les clients)"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            # Récupérer les informations de l'utilisateur connecté
            user_id = get_jwt_identity()
            claims = get_jwt()
            user_role = claims.get("role")

            # Vérifier que c'est un client
            if user_role != "client":
                return {"error": "Seuls les clients peuvent accéder à cette ressource"}, 403

            # Récupérer la commande et vérifier qu'elle appartient au client
            cur.execute("""
                SELECT c.id, c.agent_id, c.statut, c.client_id, cl.user_id as client_user_id
                FROM commandes c
                JOIN clients cl ON c.client_id = cl.id
                WHERE c.id = %s
            """, (commande_id,))

            commande = cur.fetchone()
            if not commande:
                return {"error": "Commande non trouvée"}, 404

            # Vérifier que la commande appartient au client connecté
            if commande["client_user_id"] != int(user_id):
                return {"error": "Vous ne pouvez accéder qu'aux informations de vos propres commandes"}, 403

            # Vérifier qu'un agent est assigné
            if not commande["agent_id"]:
                return {"error": "Aucun agent assigné à cette commande"}, 404

            # Récupérer les informations de l'agent
            cur.execute("""
                SELECT
                    a.id,
                    a.nom as name,
                    a.telephone as phone,
                    a.latitude,
                    a.longitude,
                    a.last_location_update
                FROM agents a
                WHERE a.id = %s
            """, (commande["agent_id"],))

            agent = cur.fetchone()
            if not agent:
                return {"error": "Agent non trouvé"}, 404

            # Vérifier que l'agent a une position valide
            if agent["latitude"] is None or agent["longitude"] is None:
                return {"error": "Position de l'agent non disponible"}, 404

            return {
                "id": agent["id"],
                "name": agent["name"],
                "phone": agent["phone"],
                "latitude": float(agent["latitude"]),
                "longitude": float(agent["longitude"]),
                "lastLocationUpdate": agent["last_location_update"].isoformat() if agent["last_location_update"] else None,
            }, 200

        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@commandes_ns.route("/<int:commande_id>/cancel")
class AnnulerCommande(Resource):
    @commandes_ns.doc(security="BearerAuth")
    @jwt_required()
    def post(self, commande_id):
        """Annuler une commande (réservé aux clients propriétaires de la commande)"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            # Récupérer les informations de l'utilisateur connecté
            user_id = get_jwt_identity()
            claims = get_jwt()
            user_role = claims.get("role")

            # Vérifier que c'est un client
            if user_role != "client":
                return {"error": "Seuls les clients peuvent annuler leurs commandes"}, 403

            # Récupérer la commande et vérifier qu'elle appartient au client
            cur.execute("""
                SELECT c.id, c.statut, c.client_id, cl.user_id as client_user_id
                FROM commandes c
                JOIN clients cl ON c.client_id = cl.id
                WHERE c.id = %s
            """, (commande_id,))

            commande = cur.fetchone()
            if not commande:
                return {"error": "Commande non trouvée"}, 404

            # Vérifier que la commande appartient au client connecté
            if commande["client_user_id"] != int(user_id):
                return {"error": "Vous ne pouvez annuler que vos propres commandes"}, 403

            # Vérifier que la commande peut être annulée
            if commande["statut"] not in ["en_attente", "confirmee"]:
                return {"error": f"Impossible d'annuler une commande avec le statut '{commande['statut']}'"}, 400

            # Annuler la commande
            cur.execute("""
                UPDATE commandes
                SET statut = 'annulee', updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
                RETURNING id, updated_at
            """, (commande_id,))

            result = cur.fetchone()
            conn.commit()

            return {
                "message": "Commande annulée avec succès",
                "commande_id": result["id"],
                "updated_at": result["updated_at"].isoformat()
            }, 200

        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@commandes_ns.route("/<int:commande_id>/validate")
class ValiderCommande(Resource):
    @commandes_ns.doc(security="BearerAuth")
    @jwt_required()
    def post(self, commande_id):
        """Valider une commande (réservé aux agents, vérification de distance < 2m)"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            # Récupérer les informations de l'utilisateur connecté
            user_id = get_jwt_identity()
            claims = get_jwt()
            user_role = claims.get("role")

            # Vérifier que c'est un agent
            if user_role != "agent":
                return {"error": "Seuls les agents peuvent valider les commandes"}, 403

            # Récupérer la commande et les coordonnées
            cur.execute("""
                SELECT
                    c.id, c.statut, c.client_id, c.agent_id,
                    cl.latitude as client_lat, cl.longitude as client_lon,
                    a.latitude as agent_lat, a.longitude as agent_lon
                FROM commandes c
                JOIN clients cl ON c.client_id = cl.id
                LEFT JOIN agents a ON a.user_id = %s
                WHERE c.id = %s
            """, (user_id, commande_id))

            commande = cur.fetchone()
            if not commande:
                return {"error": "Commande non trouvée"}, 404

            # Vérifier que la commande est en cours
            if commande["statut"] != "en_cours":
                return {"error": f"Impossible de valider une commande avec le statut '{commande['statut']}'"}, 400

            # Récupérer l'agent_id de l'utilisateur connecté
            cur.execute("SELECT id FROM agents WHERE user_id = %s", (user_id,))
            agent_record = cur.fetchone()
            if not agent_record:
                return {"error": "Agent non trouvé"}, 404

            agent_id = agent_record["id"]

            # Vérifier que l'agent est assigné à cette commande
            if commande["agent_id"] != agent_id:
                return {"error": "Vous n'êtes pas assigné à cette commande"}, 403

            # Vérifier les coordonnées GPS
            if not commande["client_lat"] or not commande["client_lon"] or not commande["agent_lat"] or not commande["agent_lon"]:
                return {"error": "Coordonnées GPS manquantes pour la validation"}, 400

            # Calculer la distance
            distance = haversine_distance(
                commande["agent_lat"], commande["agent_lon"],
                commande["client_lat"], commande["client_lon"]
            )

            # Vérifier que la distance est inférieure à 2 mètres
            if distance > 2:
                return {
                    "error": f"Distance trop importante: {distance:.2f}m (maximum 2m requis)",
                    "distance": distance
                }, 400

            # Valider la commande (marquer comme livrée)
            cur.execute("""
                UPDATE commandes
                SET statut = 'livree', date_livraison_effective = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
                RETURNING id, date_livraison_effective, updated_at
            """, (commande_id,))

            result = cur.fetchone()
            conn.commit()

            return {
                "message": "Commande validée et marquée comme livrée",
                "commande_id": result["id"],
                "distance": distance,
                "date_livraison_effective": result["date_livraison_effective"].isoformat(),
                "updated_at": result["updated_at"].isoformat()
            }, 200

        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@commandes_ns.route("/<int:commande_id>", methods=['DELETE'])
class SupprimerCommande(Resource):
    @commandes_ns.doc(security="BearerAuth")
    @jwt_required()
    def delete(self, commande_id):
        """Supprimer une commande (réservé aux administrateurs)"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            # Récupérer les informations de l'utilisateur connecté
            claims = get_jwt()
            user_role = claims.get("role")

            # Vérifier que c'est un admin
            if user_role != "admin":
                return {"error": "Seuls les administrateurs peuvent supprimer des commandes"}, 403

            # Vérifier que la commande existe
            cur.execute("SELECT id, statut FROM commandes WHERE id = %s", (commande_id,))
            commande = cur.fetchone()
            if not commande:
                return {"error": "Commande non trouvée"}, 404

            # Supprimer les détails de commande d'abord (clé étrangère)
            cur.execute("DELETE FROM commande_details WHERE commande_id = %s", (commande_id,))

            # Supprimer les livraisons associées
            cur.execute("DELETE FROM livraisons WHERE commande_id = %s", (commande_id,))

            # Supprimer les paiements associés
            cur.execute("DELETE FROM paiements WHERE commande_id = %s", (commande_id,))

            # Supprimer la commande
            cur.execute("DELETE FROM commandes WHERE id = %s", (commande_id,))

            conn.commit()

            return {
                "message": "Commande supprimée avec succès",
                "commande_id": commande_id
            }, 200

        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@commandes_ns.route("/<int:commande_id>")
class CommandeDetail(Resource):
    @commandes_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, commande_id):
        """Récupérer les détails d'une commande avec ses articles"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            # Récupérer la commande
            cur.execute("""
                SELECT
                    c.id,
                    c.client_id,
                    c.agent_id,
                    c.date_commande,
                    c.date_livraison_prevue,
                    c.date_livraison_effective,
                    c.statut,
                    c.montant_total,
                    c.notes,
                    c.adresse_livraison,
                    cl.nom_point_vente,
                    cl.responsable,
                    cl.telephone as client_telephone,
                    cl.adresse,
                    a.nom as agent_nom,
                    a.telephone as agent_telephone
                FROM commandes c
                LEFT JOIN clients cl ON c.client_id = cl.id
                LEFT JOIN agents a ON c.agent_id = a.id
                WHERE c.id = %s
            """, (commande_id,))

            commande = cur.fetchone()

            if not commande:
                return {"error": "Commande non trouvée"}, 404

            # Récupérer les articles
            cur.execute("""
                SELECT
                    cd.id,
                    cd.produit_id,
                    cd.quantite,
                    cd.prix_unitaire,
                    cd.montant_ligne,
                    p.nom as produit_nom,
                    p.description,
                    p.unite
                FROM commande_details cd
                LEFT JOIN produits p ON cd.produit_id = p.id
                WHERE cd.commande_id = %s
            """, (commande_id,))

            articles = cur.fetchall()

            return {
                "id": commande["id"],
                "client_id": commande["client_id"],
                "agent_id": commande["agent_id"],
                "date_commande": commande["date_commande"].isoformat() if commande["date_commande"] else None,
                "date_livraison_prevue": commande["date_livraison_prevue"].isoformat() if commande["date_livraison_prevue"] else None,
                "date_livraison_effective": commande["date_livraison_effective"].isoformat() if commande["date_livraison_effective"] else None,
                "statut": commande["statut"],
                "montant_total": float(commande["montant_total"]),
                "notes": commande["notes"],
                "adresse_livraison": commande["adresse_livraison"],
                "client_nom": commande.get("nom_point_vente"),
                "client_telephone": commande.get("client_telephone"),
                "agent_nom": commande.get("agent_nom"),
                "agent_telephone": commande.get("agent_telephone"),
                "items": [convert_decimal(article) for article in articles],
            }, 200

        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()

    @commandes_ns.doc(security="BearerAuth")
    @commandes_ns.expect(update_statut_model)
    @jwt_required()
    def put(self, commande_id):
        """Modifier le statut d'une commande"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            data = request.get_json()
            new_statut = data.get("statut")
            agent_id = data.get("agent_id")

            # Validation du statut
            statuts_valides = ["en_attente", "confirmee", "en_cours", "livree", "annulee"]
            if new_statut not in statuts_valides:
                return {"error": f"Statut invalide. Doit être parmi: {statuts_valides}"}, 400

            # Get current status before update
            cur.execute("SELECT statut, client_id, adresse_livraison FROM commandes WHERE id = %s", (commande_id,))
            commande = cur.fetchone()
            
            if not commande:
                return {"error": "Commande non trouvée"}, 404
            
            old_statut = commande["statut"]
            client_id = commande["client_id"]
            adresse_livraison = commande["adresse_livraison"]

            # Préparer la mise à jour
            if new_statut == "en_cours":
                cur.execute("""
                    UPDATE commandes
                    SET statut = %s, agent_id = %s, updated_at = CURRENT_TIMESTAMP
                    WHERE id = %s
                    RETURNING id, updated_at
                """, (new_statut, agent_id, commande_id))
            elif new_statut == "livree":
                cur.execute("""
                    UPDATE commandes
                    SET statut = %s, date_livraison_effective = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
                    WHERE id = %s
                    RETURNING id, updated_at
                """, (new_statut, commande_id))
            else:
                cur.execute("""
                    UPDATE commandes
                    SET statut = %s, updated_at = CURRENT_TIMESTAMP
                    WHERE id = %s
                    RETURNING id, updated_at
                """, (new_statut, commande_id))

            result = cur.fetchone()

            if not result:
                return {"error": "Commande non trouvée"}, 404

            conn.commit()

            # Récupérer les informations du client
            cur.execute("""
                SELECT c.id, u.email, u.nom as client_name, c.nom_point_vente, c.responsable
                FROM clients c
                JOIN users u ON c.user_id = u.id
                WHERE c.id = %s
            """, (client_id,))
            client = cur.fetchone()
            
            notification_service = get_notification_service()
            
            # Notify about agent assignment if status is "en_cours" and agent_id is provided
            if new_statut == "en_cours" and agent_id and client and client["email"]:
                cur.execute("""
                    SELECT id, nom, telephone
                    FROM agents
                    WHERE id = %s
                """, (agent_id,))
                agent = cur.fetchone()
                
                if agent:
                    notification_service.notify_agent_assignment(
                        client_email=client["email"],
                        client_name=client.get("responsable") or client.get("nom_point_vente", client["client_name"]),
                        agent_name=agent["nom"],
                        agent_phone=agent["telephone"],
                        delivery_address=adresse_livraison or "",
                        delivery_id=commande_id
                    )
            
            # Notify about status change
            if client and client["email"] and new_statut != old_statut:
                notification_service.notify_order_status_change(
                    client_email=client["email"],
                    client_name=client.get("responsable") or client.get("nom_point_vente", client["client_name"]),
                    order_id=commande_id,
                    old_status=old_statut,
                    new_status=new_statut
                )

            return {
                "message": f"Statut changé à {new_statut}",
                "commande_id": result["id"],
                "updated_at": result["updated_at"].isoformat()
            }, 200

        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@commandes_ns.route("/statistiques/resume")
class CommandesStatistiques(Resource):
    @commandes_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer les statistiques des commandes"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            cur.execute("""
                SELECT
                    COUNT(*) as total_commandes,
                    SUM(CASE WHEN statut = 'livree' THEN 1 ELSE 0 END) as livrees,
                    SUM(CASE WHEN statut = 'en_attente' THEN 1 ELSE 0 END) as en_attente,
                    SUM(CASE WHEN statut = 'en_cours' THEN 1 ELSE 0 END) as en_cours,
                    SUM(CASE WHEN statut = 'annulee' THEN 1 ELSE 0 END) as annulees,
                    SUM(montant_total) as montant_total,
                    AVG(montant_total) as montant_moyen
                FROM commandes
            """)

            stats = cur.fetchone()

            return {
                "total_commandes": stats["total_commandes"] or 0,
                "livrees": stats["livrees"] or 0,
                "en_attente": stats["en_attente"] or 0,
                "en_cours": stats["en_cours"] or 0,
                "annulees": stats["annulees"] or 0,
                "montant_total": float(stats["montant_total"] or 0),
                "montant_moyen": float(stats["montant_moyen"] or 0)
            }, 200

        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()

# ===== Model for updating client position =====
update_client_position_model = commandes_ns.model("UpdateClientPosition", {
    "commande_id": fields.Integer(required=True),
    "latitude": fields.Float(required=True),
    "longitude": fields.Float(required=True),
})


@commandes_ns.route("/update-client-position")
class UpdateClientPosition(Resource):
    @commandes_ns.doc(security="BearerAuth")
    @commandes_ns.expect(update_client_position_model)
    @jwt_required()
    def post(self):
        """Mettre à jour la position du client pour une commande"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            data = request.get_json()
            commande_id = data.get("commande_id")
            latitude = data.get("latitude")
            longitude = data.get("longitude")

            if not commande_id:
                return {"error": "commande_id est requis"}, 400
            
            if latitude is None or longitude is None:
                return {"error": "latitude et longitude sont requis"}, 400

            # Vérifier que la commande existe
            cur.execute("SELECT id FROM commandes WHERE id = %s", (commande_id,))
            if not cur.fetchone():
                return {"error": "Commande non trouvée"}, 404

            # Mettre à jour la position dans la livraison associée
            cur.execute("""
                UPDATE livraisons 
                SET latitude_gps = %s, longitude_gps = %s, updated_at = %s
                WHERE commande_id = %s
                RETURNING id, latitude_gps, longitude_gps
            """, (latitude, longitude, datetime.now(), commande_id))

            livraison = cur.fetchone()
            
            if not livraison:
                return {"error": "Aucune livraison trouvée pour cette commande"}, 404

            conn.commit()

            return {
                "message": "Position du client mise à jour avec succès",
                "livraison_id": livraison["id"],
                "latitude": float(livraison["latitude_gps"]),
                "longitude": float(livraison["longitude_gps"])
            }, 200

        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()