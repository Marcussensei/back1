from flask_restx import Namespace, Resource, fields
from flask import request
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import get_connection
from datetime import datetime

user_notifications_ns = Namespace(
    "user-notifications",
    path="/user-notifications",
    description="User notification endpoints"
)

notification_model = user_notifications_ns.model("UserNotification", {
    "id": fields.Integer(readonly=True),
    "utilisateur_id": fields.Integer(readonly=True),
    "titre": fields.String(required=True),
    "message": fields.String(required=True),
    "type_notification": fields.String(required=True),
    "lue": fields.Boolean(required=True),
    "created_at": fields.DateTime(readonly=True),
})


@user_notifications_ns.route("/")
class UserNotificationsList(Resource):
    @user_notifications_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer les notifications de l'utilisateur connecté"""
        user_id = get_jwt_identity()

        conn = get_connection()
        cur = conn.cursor()

        try:
            # Récupérer les paramètres de filtrage
            unread_only = request.args.get("unread_only", "false").lower() == "true"
            limit = request.args.get("limit", 50, type=int)

            # Construire la requête
            query = """
                SELECT id, utilisateur_id, titre, message, type_notification, lue, created_at
                FROM notifications
                WHERE utilisateur_id = %s
            """

            params = [user_id]

            if unread_only:
                query += " AND lue = FALSE"

            query += " ORDER BY created_at DESC LIMIT %s"
            params.append(limit)

            cur.execute(query, params)
            notifications = cur.fetchall()

            # Compter le total et les non lues
            cur.execute("""
                SELECT
                    COUNT(*) as total,
                    COUNT(CASE WHEN lue = FALSE THEN 1 END) as unread_count
                FROM notifications
                WHERE utilisateur_id = %s
            """, (user_id,))

            counts = cur.fetchone()

            return {
                "notifications": [{
                    "id": n["id"],
                    "utilisateur_id": n["utilisateur_id"],
                    "titre": n["titre"],
                    "message": n["message"],
                    "type_notification": n["type_notification"],
                    "lue": n["lue"],
                    "created_at": n["created_at"].isoformat() if n["created_at"] else None
                } for n in notifications],
                "total": counts["total"],
                "unread_count": counts["unread_count"]
            }, 200

        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@user_notifications_ns.route("/<int:notification_id>")
class UserNotificationDetail(Resource):
    @user_notifications_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, notification_id):
        """Récupérer une notification spécifique et la marquer comme lue"""
        user_id = get_jwt_identity()

        conn = get_connection()
        cur = conn.cursor()

        try:
            # Récupérer la notification
            cur.execute("""
                SELECT id, utilisateur_id, titre, message, type_notification, lue, created_at
                FROM notifications
                WHERE id = %s AND utilisateur_id = %s
            """, (notification_id, user_id))

            notification = cur.fetchone()

            if not notification:
                return {"error": "Notification non trouvée"}, 404

            # Marquer comme lue si elle ne l'est pas déjà
            if not notification["lue"]:
                cur.execute("""
                    UPDATE notifications
                    SET lue = TRUE
                    WHERE id = %s
                """, (notification_id,))
                conn.commit()

            return {
                "id": notification["id"],
                "utilisateur_id": notification["utilisateur_id"],
                "titre": notification["titre"],
                "message": notification["message"],
                "type_notification": notification["type_notification"],
                "lue": True,  # Marquée comme lue
                "created_at": notification["created_at"].isoformat() if notification["created_at"] else None
            }, 200

        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()

    @user_notifications_ns.doc(security="BearerAuth")
    @jwt_required()
    def put(self, notification_id):
        """Marquer une notification comme lue/non lue"""
        user_id = get_jwt_identity()

        conn = get_connection()
        cur = conn.cursor()

        try:
            data = request.get_json()
            lue = data.get("lue", True)

            # Vérifier que la notification appartient à l'utilisateur
            cur.execute("""
                UPDATE notifications
                SET lue = %s
                WHERE id = %s AND utilisateur_id = %s
                RETURNING id
            """, (lue, notification_id, user_id))

            result = cur.fetchone()

            if not result:
                return {"error": "Notification non trouvée"}, 404

            conn.commit()

            return {"message": "Notification mise à jour"}, 200

        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()

    @user_notifications_ns.doc(security="BearerAuth")
    @jwt_required()
    def delete(self, notification_id):
        """Supprimer une notification"""
        user_id = get_jwt_identity()

        conn = get_connection()
        cur = conn.cursor()

        try:
            cur.execute("""
                DELETE FROM notifications
                WHERE id = %s AND utilisateur_id = %s
                RETURNING id
            """, (notification_id, user_id))

            result = cur.fetchone()

            if not result:
                return {"error": "Notification non trouvée"}, 404

            conn.commit()

            return {"message": "Notification supprimée"}, 200

        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@user_notifications_ns.route("/mark-all-read")
class MarkAllRead(Resource):
    @user_notifications_ns.doc(security="BearerAuth")
    @jwt_required()
    def post(self):
        """Marquer toutes les notifications de l'utilisateur comme lues"""
        user_id = get_jwt_identity()

        conn = get_connection()
        cur = conn.cursor()

        try:
            cur.execute("""
                UPDATE notifications
                SET lue = TRUE
                WHERE utilisateur_id = %s AND lue = FALSE
            """, (user_id,))

            conn.commit()

            return {"message": "Toutes les notifications ont été marquées comme lues"}, 200

        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()
