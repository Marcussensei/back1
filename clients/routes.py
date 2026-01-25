from flask_restx import Namespace, Resource, fields
from flask import request
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from werkzeug.security import generate_password_hash
from werkzeug.exceptions import HTTPException
from db import get_connection
import psycopg2

clients_ns = Namespace(
    "clients",
    path="/clients",
    description="Client management endpoints"
)

# Modèles pour la validation des données
client_model = clients_ns.model('Client', {
    'nom': fields.String(required=True, description='Nom du client'),
    'password': fields.String(required=True, description='Mot de passe du client'),
    'email': fields.String(required=True, description='Email du client'),
    'telephone': fields.String(required=True, description='Téléphone du client'),
    'nom_point_vente': fields.String(description='Nom du point de vente'),
    'responsable': fields.String(description='Nom du responsable'),
    'adresse': fields.String(description='Adresse du client'),
    'latitude': fields.Float(description='Latitude GPS'),
    'longitude': fields.Float(description='Longitude GPS'),
    'type_client': fields.String(description='Type de client (particulier/entreprise)')
})

client_update_model = clients_ns.model('ClientUpdate', {
    'nom': fields.String(description='Nom du client'),
    'email': fields.String(description='Email du client'),
    'telephone': fields.String(description='Téléphone du client'),
    'nom_point_vente': fields.String(description='Nom du point de vente'),
    'responsable': fields.String(description='Nom du responsable'),
    'adresse': fields.String(description='Adresse du client'),
    'latitude': fields.Float(description='Latitude GPS'),
    'longitude': fields.Float(description='Longitude GPS'),
    'type_client': fields.String(description='Type de client (particulier/entreprise)')
})

@clients_ns.route("/")
class ClientsList(Resource):
    @clients_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer la liste de tous les clients"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            cur.execute(
                """
                SELECT
                    c.id,
                    u.nom,
                    u.email,
                    u.created_at,
                    c.nom_point_vente,
                    c.responsable,
                    c.telephone,
                    c.adresse,
                    c.latitude,
                    c.longitude
                FROM users u
                JOIN clients c ON u.id = c.user_id
                ORDER BY u.created_at DESC
                """
            )

            clients = cur.fetchall()

            result = []
            for client in clients:
                # Compter les commandes (simplifié pour l'exemple)
                cur.execute(
                    "SELECT COUNT(*) as order_count FROM commandes WHERE client_id = %s",
                    (client["id"],)
                )
                order_count = cur.fetchone()["order_count"]

                result.append({
                    "id": client["id"],
                    "nom": client["nom"],
                    "email": client["email"],
                    "telephone": client["telephone"],
                    "nom_point_vente": client["nom_point_vente"],
                    "responsable": client["responsable"],
                    "adresse": client["adresse"],
                    "latitude": float(client["latitude"]) if client["latitude"] else None,
                    "longitude": float(client["longitude"]) if client["longitude"] else None,
                    "type_client": "particulier",  # Type par défaut
                    "totalOrders": order_count,
                    "totalAmount": 0,  # À calculer plus tard
                    "created_at": client["created_at"].isoformat() if client["created_at"] else None,
                })

            return result

        except Exception as e:
            clients_ns.abort(500, f"Erreur serveur: {str(e)}")
        finally:
            conn.close()

    @clients_ns.doc(security="BearerAuth")
    @clients_ns.expect(client_model)
    @jwt_required()
    def post(self):
        """Créer un nouveau client"""
        data = request.get_json()

        # Validation des données requises (aligné sur /auth/create-client)
        required_fields = ['nom', 'email', 'telephone', 'nom_point_vente', 'password']
        for field in required_fields:
            if field not in data or not data[field]:
                clients_ns.abort(400, f"Le champ '{field}' est requis")

        # Admin must provide a password for the created client
        password = data.get('password')

        conn = get_connection()
        cur = conn.cursor()

        try:
            # Vérifier doublon email
            cur.execute("SELECT id FROM users WHERE email = %s", (data['email'],))
            if cur.fetchone():
                clients_ns.abort(409, "Email déjà utilisé")

            # Créer l'utilisateur client using pgcrypto crypt() for consistency
            try:
                cur.execute(
                    """
                    INSERT INTO users (nom, email, password_hash, role)
                    VALUES (%s, %s, crypt(%s, gen_salt('bf')), 'client')
                    RETURNING id
                    """,
                    (data['nom'], data['email'], password)
                )
            except psycopg2.IntegrityError as e:
                conn.rollback()
                msg = str(e)
                if 'email' in msg.lower():
                    clients_ns.abort(409, "Email déjà utilisé")
                else:
                    clients_ns.abort(400, f"Erreur création user: {msg}")

            user_id = cur.fetchone()["id"]

            # Créer le client
            try:
                cur.execute(
                    """
                    INSERT INTO clients (
                        nom_point_vente, responsable, telephone, adresse,
                        latitude, longitude, user_id
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    RETURNING id
                    """,
                    (
                        data.get('nom_point_vente'),
                        data.get('responsable'),
                        data['telephone'],
                        data.get('adresse'),
                        data.get('latitude'),
                        data.get('longitude'),
                        user_id
                    )
                )
            except psycopg2.IntegrityError as e:
                conn.rollback()
                msg = str(e)
                if 'telephone' in msg.lower():
                    clients_ns.abort(409, "Téléphone déjà utilisé")
                else:
                    clients_ns.abort(400, f"Erreur création client: {msg}")

            client_id = cur.fetchone()["id"]
            conn.commit()

            return {
                "id": client_id,
                "message": "Client créé avec succès",
                "user_id": user_id
            }, 201

        except Exception as e:
            if isinstance(e, HTTPException):
                raise
            conn.rollback()
            clients_ns.abort(500, f"Erreur lors de la création du client: {str(e)}")
        finally:
            conn.close()

@clients_ns.route("/<int:client_id>")
class ClientDetail(Resource):
    @clients_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, client_id):
        """Récupérer les détails d'un client spécifique"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            cur.execute(
                """
                SELECT
                    c.id,
                    u.nom,
                    u.email,
                    u.created_at,
                    c.nom_point_vente,
                    c.responsable,
                    c.telephone,
                    c.adresse,
                    c.latitude,
                    c.longitude
                FROM users u
                JOIN clients c ON u.id = c.user_id
                WHERE c.id = %s
                """,
                (client_id,)
            )

            client = cur.fetchone()
            if not client:
                clients_ns.abort(404, "Client non trouvé")

            # Compter les commandes
            cur.execute(
                "SELECT COUNT(*) as order_count FROM commandes WHERE client_id = %s",
                (client_id,)
            )
            order_count = cur.fetchone()["order_count"]

            # Calculer le montant total des commandes
            cur.execute(
                "SELECT COALESCE(SUM(montant_total), 0) as total_amount FROM commandes WHERE client_id = %s AND statut = 'livree'",
                (client_id,)
            )
            total_amount = cur.fetchone()["total_amount"]

            # Dernière commande
            cur.execute(
                "SELECT date_commande FROM commandes WHERE client_id = %s ORDER BY date_commande DESC LIMIT 1",
                (client_id,)
            )
            last_order = cur.fetchone()

            return {
                "id": client["id"],
                "nom": client["nom"],
                "email": client["email"],
                "telephone": client["telephone"],
                "nom_point_vente": client["nom_point_vente"],
                "responsable": client["responsable"],
                "adresse": client["adresse"],
                "latitude": float(client["latitude"]) if client["latitude"] else None,
                "longitude": float(client["longitude"]) if client["longitude"] else None,
                "type_client": "particulier",
                "totalOrders": order_count,
                "totalAmount": float(total_amount),
                "avgOrderValue": float(total_amount / order_count) if order_count > 0 else 0,
                "lastOrderDate": last_order["date_commande"].strftime("%d/%m/%Y") if last_order and last_order["date_commande"] else None,
                "created_at": client["created_at"].isoformat() if client["created_at"] else None,
            }

        except Exception as e:
            clients_ns.abort(500, f"Erreur serveur: {str(e)}")
        finally:
            conn.close()

    @clients_ns.doc(security="BearerAuth")
    @clients_ns.expect(client_update_model)
    @jwt_required()
    def put(self, client_id):
        """Mettre à jour un client"""
        data = request.get_json()

        conn = get_connection()
        cur = conn.cursor()

        try:
            # Vérifier que le client existe
            cur.execute("SELECT user_id FROM clients WHERE id = %s", (client_id,))
            client_record = cur.fetchone()
            if not client_record:
                clients_ns.abort(404, "Client non trouvé")

            user_id = client_record["user_id"]

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

            # Mettre à jour le client
            update_fields = []
            update_values = []

            client_fields = ['nom_point_vente', 'responsable', 'telephone', 'adresse', 'latitude', 'longitude']
            for field in client_fields:
                if field in data:
                    update_fields.append(f"{field} = %s")
                    update_values.append(data[field])

            if update_fields:
                update_values.append(client_id)
                cur.execute(
                    f"UPDATE clients SET {', '.join(update_fields)} WHERE id = %s",
                    update_values
                )

            conn.commit()

            return {"message": "Client mis à jour avec succès"}

        except Exception as e:
            conn.rollback()
            clients_ns.abort(500, f"Erreur lors de la mise à jour du client: {str(e)}")
        finally:
            conn.close()

    @clients_ns.doc(security="BearerAuth")
    @jwt_required()
    def delete(self, client_id):
        """Supprimer un client"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            # Vérifier que le client existe
            cur.execute("SELECT user_id FROM clients WHERE id = %s", (client_id,))
            client_record = cur.fetchone()
            if not client_record:
                clients_ns.abort(404, "Client non trouvé")

            user_id = client_record["user_id"]

            # Supprimer le client d'abord
            cur.execute("DELETE FROM clients WHERE id = %s", (client_id,))

            # Supprimer l'utilisateur associé
            cur.execute("DELETE FROM users WHERE id = %s", (user_id,))

            conn.commit()

            return {"message": "Client supprimé avec succès"}

        except Exception as e:
            conn.rollback()
            clients_ns.abort(500, f"Erreur lors de la suppression du client: {str(e)}")
        finally:
            conn.close()


@clients_ns.route("/my-orders")
class ClientOrders(Resource):
    @clients_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer les commandes du client connecté (empêche l'accès aux commandes des autres clients)"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            # Récupérer les informations de l'utilisateur connecté
            user_id = get_jwt_identity()
            claims = get_jwt()
            user_role = claims.get("role")

            # Vérifier que c'est un client
            if user_role != "client":
                clients_ns.abort(403, "Seuls les clients peuvent accéder à leurs commandes")

            # Récupérer le client_id de l'utilisateur
            cur.execute("SELECT id FROM clients WHERE user_id = %s", (user_id,))
            client_record = cur.fetchone()
            if not client_record:
                clients_ns.abort(404, "Client non trouvé")

            client_id = client_record["id"]

            # Récupérer les paramètres de requête
            statut = request.args.get("statut")
            date_debut = request.args.get("date_debut")
            date_fin = request.args.get("date_fin")
            page = request.args.get("page", default=1, type=int)
            per_page = request.args.get("per_page", default=20, type=int)

            # Construire la requête
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
                    a.nom as agent_nom,
                    a.telephone as agent_telephone
                FROM commandes c
                LEFT JOIN agents a ON c.agent_id = a.id
                WHERE c.client_id = %s
            """

            params = [client_id]

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
            count_query = "SELECT COUNT(*) as total FROM commandes WHERE client_id = %s"
            count_params = [client_id]
            if statut:
                count_query += " AND statut = %s"
                count_params.append(statut)
            if date_debut:
                count_query += " AND DATE(date_commande) >= %s"
                count_params.append(date_debut)
            if date_fin:
                count_query += " AND DATE(date_commande) <= %s"
                count_params.append(date_fin)

            cur.execute(count_query, count_params)
            total = cur.fetchone()["total"]

            # Ajouter pagination et tri
            query = base_query + " ORDER BY c.date_commande DESC LIMIT %s OFFSET %s"
            params.extend([per_page, (page - 1) * per_page])

            cur.execute(query, params)
            commandes = cur.fetchall()

            # Convertir les valeurs Decimal et datetime
            result_commandes = []
            for cmd in commandes:
                result_commandes.append({
                    "id": cmd["id"],
                    "client_id": cmd["client_id"],
                    "agent_id": cmd["agent_id"],
                    "date_commande": cmd["date_commande"].isoformat() if cmd["date_commande"] else None,
                    "date_livraison_prevue": cmd["date_livraison_prevue"].isoformat() if cmd["date_livraison_prevue"] else None,
                    "date_livraison_effective": cmd["date_livraison_effective"].isoformat() if cmd["date_livraison_effective"] else None,
                    "statut": cmd["statut"],
                    "montant_total": float(cmd["montant_total"]) if cmd["montant_total"] else 0,
                    "notes": cmd["notes"],
                    "agent_nom": cmd["agent_nom"],
                    "agent_telephone": cmd["agent_telephone"]
                })

            return {
                "commandes": result_commandes,
                "total": total,
                "page": page,
                "per_page": per_page,
                "total_pages": (total + per_page - 1) // per_page
            }, 200

        except Exception as e:
            clients_ns.abort(500, f"Erreur serveur: {str(e)}")
        finally:
            conn.close()

@clients_ns.route("/<int:client_id>/monthly-stats")
class ClientMonthlyStats(Resource):
    def options(self, client_id):
        """Handle CORS preflight requests"""
        from flask import make_response
        response = make_response()
        response.status_code = 200
        return response
    
    @clients_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, client_id):
        """Récupérer les statistiques mensuelles d'un client"""
        conn = get_connection()
        cur = conn.cursor()

        try:
            # Vérifier que le client existe
            cur.execute("SELECT id FROM clients WHERE id = %s", (client_id,))
            if not cur.fetchone():
                clients_ns.abort(404, "Client non trouvé")

            # Statistiques des 6 derniers mois
            cur.execute("""
                SELECT
                    TO_CHAR(DATE_TRUNC('month', c.date_commande), 'Mon') as month,
                    TO_CHAR(DATE_TRUNC('month', c.date_commande), 'YYYY') as year,
                    COUNT(*) as orders,
                    COALESCE(SUM(c.montant_total), 0) as amount
                FROM commandes c
                WHERE c.client_id = %s
                AND c.date_commande > CURRENT_DATE - INTERVAL '6 months'
                GROUP BY DATE_TRUNC('month', c.date_commande), TO_CHAR(DATE_TRUNC('month', c.date_commande), 'Mon'), TO_CHAR(DATE_TRUNC('month', c.date_commande), 'YYYY')
                ORDER BY DATE_TRUNC('month', c.date_commande) DESC
            """, (client_id,))

            monthly_data = cur.fetchall()

            # Statistiques du mois en cours
            cur.execute("""
                SELECT
                    COUNT(*) as this_month_orders,
                    COALESCE(SUM(montant_total), 0) as this_month_amount
                FROM commandes
                WHERE client_id = %s
                AND DATE_TRUNC('month', date_commande) = DATE_TRUNC('month', CURRENT_DATE)
            """, (client_id,))

            current_month = cur.fetchone()

            # Statistiques globales
            cur.execute("""
                SELECT
                    COUNT(*) as total_orders,
                    COALESCE(SUM(montant_total), 0) as total_amount,
                    COALESCE(AVG(montant_total), 0) as avg_order_value
                FROM commandes
                WHERE client_id = %s
            """, (client_id,))

            global_stats = cur.fetchone()

            return {
                "monthly_stats": [
                    {
                        "month": f"{row['month']} {row['year']}",
                        "orders": row['orders'] or 0,
                        "amount": float(row['amount'] or 0)
                    }
                    for row in monthly_data
                ],
                "current_month": {
                    "orders": current_month['this_month_orders'] or 0,
                    "amount": float(current_month['this_month_amount'] or 0)
                },
                "global_stats": {
                    "total_orders": global_stats['total_orders'] or 0,
                    "total_amount": float(global_stats['total_amount'] or 0),
                    "avg_order_value": float(global_stats['avg_order_value'] or 0)
                }
            }

        except Exception as e:
            clients_ns.abort(500, f"Erreur: {str(e)}")
        finally:
            conn.close()